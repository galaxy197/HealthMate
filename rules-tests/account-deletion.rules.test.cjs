const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {test, before, beforeEach, after} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, collection, query, where, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  writeBatch, serverTimestamp, Timestamp} = require('firebase/firestore');

let env;
const ticketId = 'AbCdEfGhIjKlMnOpQrSt';
const messageId = 'ZbCdEfGhIjKlMnOpQrSt';
const transactionId = 'XbCdEfGhIjKlMnOpQrSt';
const jobPath = 'account_deletions/alice';
const uidData = uid => ({email_verified:true, email:`${uid}@example.com`, auth_time:Math.floor(Date.now()/1000)});
const client = (uid = 'alice', claims = {}) => env.authenticatedContext(uid, {...uidData(uid), ...claims}).firestore();
const marker = (patch = {}) => ({uid:'alice',schemaVersion:1,executor:'client',state:'requested',
  checkpoint:0,requestedAt:serverTimestamp(),updatedAt:serverTimestamp(),...patch});
const profile = () => ({displayName:'Alice',email:'alice@example.com',heightCm:null,birthDate:null,
  healthGoal:null,targetWeightKg:null,onboardingCompletedAt:null,createdAt:serverTimestamp(),
  updatedAt:serverTimestamp(),schemaVersion:2});
const water = () => ({amountMl:250,consumedAt:Timestamp.now(),dateKey:new Date().toISOString().slice(0,10),
  timezoneOffsetMinutes:0,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
const ticket = () => ({uid:'alice',type:'bug',title:'Fixture report',description:'Synthetic support data',status:'open',
  createdAt:serverTimestamp(),updatedAt:serverTimestamp(),messageCount:0,lastMessageId:'',updatedBy:'alice',deleting:false});
const period = () => ({mode:'demo',planId:'premium_demo_30d',startedAt:Timestamp.now(),
  expiresAt:Timestamp.fromMillis(Date.now()+30*86400000)});
function purchase(db) {
  const p=period(), batch=writeBatch(db);
  batch.set(doc(db,'demo_premium_accounts/alice'),{...p,transactionId,updatedAt:serverTimestamp()});
  batch.set(doc(db,'demo_premium_transactions',transactionId),{...p,uid:'alice',amountVnd:20000,currency:'VND',
    status:'simulated_paid',source:'demo_checkout',occurredAt:serverTimestamp()});
  return batch.commit();
}
function usage() {
  const local = new Date(Date.now()+7*3600000);
  const start=Date.UTC(local.getUTCFullYear(),local.getUTCMonth(),local.getUTCDate())-7*3600000;
  return {mode:'demo',dayStart:Timestamp.fromMillis(start),scans:1,chats:0,updatedAt:serverTimestamp()};
}
function reply(db, role='admin') {
  const authorUid=role==='admin'?'admin':'alice',batch=writeBatch(db);
  batch.set(doc(db,'support_tickets',ticketId,'messages',messageId),{authorUid,role,text:'Fixture reply',sequence:1,createdAt:serverTimestamp()});
  batch.update(doc(db,'support_tickets',ticketId),{messageCount:1,lastMessageId:messageId,updatedBy:authorUid,updatedAt:serverTimestamp()});
  return batch.commit();
}
before(async()=>{
  const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env=await initializeTestEnvironment({projectId:'demo-healthmate-deletion-rules',
    firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')}});
});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await setDoc(doc(db,'admin_roles/admin'),{enabled:true});
  });
});
after(()=>env?.cleanup());

test('verified recent identity requests deletion; no guest, foreign UID, unverified or stale token',async()=>{
  for(const db of [env.unauthenticatedContext().firestore(),client('bob'),
    client('alice',{email_verified:false}),client('alice',{auth_time:Math.floor(Date.now()/1000)-601}),
    client('alice',{auth_time:Math.floor(Date.now()/1000)+120}),client('alice',{auth_time:'recent'})]) {
    await assertFails(setDoc(doc(db,jobPath),marker()));
  }
  for(const patch of [{uid:'bob'},{state:'auth_pending'},{checkpoint:1},{executor:'server'},
    {schemaVersion:2},{serverVerified:true},{requestedAt:Timestamp.fromMillis(1)}]) {
    await assertFails(setDoc(doc(client(),jobPath),marker(patch)));
  }
  await assertSucceeds(setDoc(doc(client(),jobPath),marker()));
  await assertSucceeds(getDoc(doc(client(),jobPath)));
  for(const db of [client('bob'),client('admin'),env.unauthenticatedContext().firestore()]) {
    await assertFails(getDoc(doc(db,jobPath)));
    await assertFails(deleteDoc(doc(db,jobPath)));
  }
  await assertFails(getDocs(collection(client(),'account_deletions')));
});

test('job state is monotonic, cannot be removed/reset and never accepts a client completed proof',async()=>{
  const db=client(),job=doc(db,jobPath);
  await setDoc(job,marker());
  await assertFails(deleteDoc(job));
  await assertFails(updateDoc(job,{checkpoint:1,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(job,{state:'cleaning',checkpoint:0,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(job,{checkpoint:3,updatedAt:serverTimestamp()}));
  for(let checkpoint=1;checkpoint<=4;checkpoint++) {
    await assertSucceeds(updateDoc(job,{checkpoint,updatedAt:serverTimestamp()}));
  }
  await assertFails(updateDoc(job,{checkpoint:3,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(job,{state:'requested',checkpoint:0,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(job,{state:'completed',checkpoint:5,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(job,{state:'auth_pending',checkpoint:5,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(job,{updatedAt:serverTimestamp()}));
  for(const patch of [{state:'cleaning'},{uid:'bob'},{executor:'server'},
    {requestedAt:Timestamp.fromMillis(1)},{schemaVersion:2}]) {
    await assertFails(updateDoc(job,{...patch,updatedAt:serverTimestamp()}));
  }
  await assertFails(deleteDoc(job));
});

test('suspended identity can request and clean up without regaining product writes',async()=>{
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await setDoc(doc(db,'account_controls/alice'),{status:'suspended',reason:'Fixture'});
    await setDoc(doc(db,'users/alice'),{displayName:'Alice'});
    await setDoc(doc(db,'users/alice/body_metrics/old'),{weightKg:60});
  });
  const db=client();
  await assertFails(getDoc(doc(db,'users/alice/body_metrics/old')));
  await assertFails(deleteDoc(doc(db,'users/alice/body_metrics/old')));
  await assertFails(setDoc(doc(db,'users/alice/water_logs/new'),water()));
  await assertSucceeds(setDoc(doc(db,jobPath),marker()));
  await assertSucceeds(getDocs(collection(db,'users/alice/body_metrics')));
  await assertSucceeds(deleteDoc(doc(db,'users/alice/body_metrics/old')));
  await assertSucceeds(deleteDoc(doc(db,'users/alice')));
  await assertSucceeds(deleteDoc(doc(db,'account_controls/alice')));
  await assertFails(setDoc(doc(db,'users/alice'),profile()));
  await assertFails(setDoc(doc(db,'users/alice/water_logs/new'),water()));
});

test('same UID second context cannot write cleaned, uncleared or recreated parent after marker',async()=>{
  const a=client(),b=client();
  await assertSucceeds(setDoc(doc(a,'users/alice'),profile()));
  await assertSucceeds(setDoc(doc(a,'users/alice/water_logs/old'),water()));
  await assertSucceeds(setDoc(doc(a,jobPath),marker()));
  await assertFails(updateDoc(doc(b,'users/alice'),{displayName:'Late',updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(b,'users/alice/water_logs/new'),water()));
  await assertSucceeds(deleteDoc(doc(a,'users/alice/water_logs/old')));
  await assertFails(setDoc(doc(b,'users/alice/water_logs/old'),water()));
  await assertSucceeds(deleteDoc(doc(a,'users/alice')));
  await assertFails(setDoc(doc(b,'users/alice'),profile()));
  assert.equal((await getDoc(doc(a,jobPath))).exists(),true);
});

test('creating marker and product document in the same batch is rejected atomically',async()=>{
  const db=client(),batch=writeBatch(db);
  batch.set(doc(db,jobPath),marker());
  batch.set(doc(db,'users/alice'),profile());
  await assertFails(batch.commit());
  assert.equal((await getDoc(doc(db,jobPath))).exists(),false);
  await assertSucceeds(setDoc(doc(db,'users/alice'),profile()));
});

test('post-marker blocks all private product create/update entry points, including chat and bootstrap',async()=>{
  const db=client();
  await setDoc(doc(db,jobPath),marker());
  const paths=['users/alice','users/alice/body_metrics/m','users/alice/meal_logs/m',
    'users/alice/water_logs/m','users/alice/activity_logs/m','users/alice/goals/m',
    'users/alice/daily_quests/m','users/alice/nutrition_targets/m','users/alice/favorite_foods/m',
    'users/alice/custom_foods/m','users/alice/recipes/m',
    'users/alice/day_reviews/m','users/alice/sleep_logs/m',
    'users/alice/wellness_state/sleep','users/alice/wellness_preferences/m',
    'users/alice/step_logs/m',
    'users/alice/chat_sessions/m','users/alice/chat_sessions/m/messages/m'];
  for(const target of paths) {
    await assertFails(setDoc(doc(db,target),{schemaVersion:1}));
    await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),target),{fixture:true}));
    await assertFails(updateDoc(doc(db,target),{fixture:false}));
  }
  // Exercise the plan guard with a structurally valid document. A missing
  // timestamp/plan ID makes the emulator's pre-existing ternary evaluator throw
  // UNKNOWN instead of resolving PERMISSION_DENIED, which is not this test.
  const day='2026-10-30',planPath=`users/alice/meal_plans/${day}-breakfast`;
  const row={foodId:'fixture',name:'Fixture',quantity:100,quantityUnit:'g',kcal:120,
    proteinG:6,carbsG:15,fatG:4,sourceLabel:'Synthetic fixture',isEstimated:true};
  const plan={dateKey:day,mealType:'breakfast',items:[row],schemaVersion:2,
    createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  await assertFails(setDoc(doc(db,planPath),plan));
  await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),planPath),plan));
  await assertFails(updateDoc(doc(db,planPath),{updatedAt:serverTimestamp()}));
  const template={name:'Fixture template',items:[{...row,grams:100}],schemaVersion:1,
    createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  delete template.items[0].quantity;
  delete template.items[0].quantityUnit;
  await assertFails(setDoc(doc(db,'users/alice/meal_templates/m'),template));
  await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),'users/alice/meal_templates/m'),template));
  await assertFails(updateDoc(doc(db,'users/alice/meal_templates/m'),{updatedAt:serverTimestamp()}));
  const energy={dateKey:day,timezoneOffsetMinutes:0,steps:6000,baselineSteps:4000,stepLengthCm:75,
    weightKg:70,weightMeasuredAt:Timestamp.fromDate(new Date(day+'T00:00:00Z')),targetFromDateKey:day,
    baseKcalTarget:1800,kcal:50,source:'walking_net_v1',schemaVersion:1,confirmedAt:serverTimestamp()};
  await assertFails(setDoc(doc(db,`users/alice/energy_adjustments/${day}`),energy));
  await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),`users/alice/energy_adjustments/${day}`),energy));
  await assertFails(updateDoc(doc(db,`users/alice/energy_adjustments/${day}`),{confirmedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'user_directory/alice'),{displayName:'Alice',email:'alice@example.com',createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
});

test('Premium demo records are removable only during own deletion; quota and new purchases stay denied',async()=>{
  const db=client(),u=usage(),usagePath=`demo_ai_usage/alice/days/${u.dayStart.toMillis()}`;
  await assertSucceeds(purchase(db));
  await assertSucceeds(setDoc(doc(db,usagePath),u));
  for(const target of ['demo_premium_accounts/alice',`demo_premium_transactions/${transactionId}`,usagePath]) {
    await assertFails(deleteDoc(doc(db,target)));
  }
  await setDoc(doc(db,jobPath),marker());
  await assertSucceeds(getDocs(query(collection(db,'demo_premium_transactions'),where('uid','==','alice'))));
  await assertSucceeds(getDocs(collection(db,'demo_ai_usage/alice/days')));
  await assertFails(purchase(db));
  await assertFails(setDoc(doc(db,usagePath),{...u,scans:2}));
  for(const target of ['demo_premium_accounts/alice',`demo_premium_transactions/${transactionId}`,usagePath]) {
    await assertFails(deleteDoc(doc(client('bob'),target)));
    await assertSucceeds(deleteDoc(doc(db,target)));
  }
  await assertSucceeds(deleteDoc(doc(db,'demo_ai_usage/alice')));
});

test('support admin/customer replies freeze immediately at marker; only owner cleanup transition remains',async()=>{
  const db=client(),admin=client('admin'),target=`support_tickets/${ticketId}`;
  const created=writeBatch(db),local=new Date(Date.now()+7*3600000);
  created.set(doc(db,target),ticket());
  created.set(doc(db,'support_usage/alice'),{schemaVersion:1,
    dayStart:Timestamp.fromMillis(Date.UTC(local.getUTCFullYear(),local.getUTCMonth(),local.getUTCDate())-7*3600000),
    count:1,lastCreatedAt:serverTimestamp(),lastTicketId:ticketId,updatedAt:serverTimestamp()});
  await created.commit();
  await setDoc(doc(db,jobPath),marker());
  await assertSucceeds(getDocs(query(collection(db,'support_tickets'),where('uid','==','alice'))));
  await assertFails(reply(admin));
  await assertFails(reply(db,'customer'));
  await assertFails(updateDoc(doc(admin,target),{status:'resolved',updatedBy:'admin',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,target),{deleting:true,status:'resolved',updatedBy:'alice',updatedAt:serverTimestamp()}));
  await assertFails(deleteDoc(doc(db,target)));
  await assertSucceeds(updateDoc(doc(db,target),{deleting:true,updatedBy:'alice',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,target),{deleting:false,updatedBy:'alice',updatedAt:serverTimestamp()}));
  await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),target,'messages',messageId),{fixture:true}));
  await assertSucceeds(deleteDoc(doc(db,target,'messages',messageId)));
  await assertSucceeds(deleteDoc(doc(db,target)));
});

test('target deletion blocks audited admin account changes, retains immutable audit and role',async()=>{
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await setDoc(doc(db,'user_directory/alice'),{displayName:'Alice',email:'alice@example.com'});
    await setDoc(doc(db,'account_controls/alice'),{status:'active'});
    await setDoc(doc(db,'admin_audit/old'),{actorUid:'admin',entityType:'account_controls',entityId:'alice'});
  });
  const db=client(),admin=client('admin');
  await setDoc(doc(db,jobPath),marker());
  const batch=writeBatch(admin),id='new-audit';
  const target={status:'suspended',reason:'Fixture',updatedBy:'admin',updatedAt:serverTimestamp(),lastAdminOperationId:id};
  batch.set(doc(admin,'account_controls/alice'),target);
  batch.set(doc(admin,'admin_audit',id),{actorUid:'admin',entityType:'account_controls',entityId:'alice',at:serverTimestamp(),changedFields:Object.keys(target),reason:'Fixture'});
  await assertFails(batch.commit());
  await assertFails(deleteDoc(doc(db,'admin_audit/old')));
  await assertFails(deleteDoc(doc(admin,'admin_audit/old')));
  await assertFails(deleteDoc(doc(admin,'admin_roles/admin')));
  await assertSucceeds(deleteDoc(doc(db,'user_directory/alice')));
  await assertSucceeds(deleteDoc(doc(db,'account_controls/alice')));
});
