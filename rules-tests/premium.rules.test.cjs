const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {before,beforeEach,after,test} = require('node:test');
const {initializeTestEnvironment,assertFails,assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc,collection,getDoc,getDocs,setDoc,deleteDoc,writeBatch,runTransaction,serverTimestamp,Timestamp} = require('firebase/firestore');
let env;
before(async()=>{
  const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8092').split(':');
  env=await initializeTestEnvironment({projectId:'demo-healthmate-premium-rules',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')}});
});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:true}));
});
after(async()=>env?.cleanup());
const db=uid=>env.authenticatedContext(uid,{email_verified:true,email:`${uid}@example.com`}).firestore();
const id='AbCdEfGhIjKlMnOpQrSt';
function period(now=Date.now()) {return{mode:'demo',planId:'premium_demo_30d',startedAt:Timestamp.fromMillis(now),expiresAt:Timestamp.fromMillis(now+30*86400000)};}
function purchase(database,uid='alice',transactionId=id,patch={}) {
  const batch=writeBatch(database),shared=period();
  batch.set(doc(database,'demo_premium_accounts',uid),{...shared,transactionId,updatedAt:serverTimestamp()});
  batch.set(doc(database,'demo_premium_transactions',transactionId),{...shared,uid,amountVnd:20000,currency:'VND',status:'simulated_paid',source:'demo_checkout',occurredAt:serverTimestamp(),...patch});
  return batch.commit();
}
function usageData(scans,chats,dayStart) {
  const vn=new Date(Date.now()+7*3600000);
  const start=dayStart ?? Date.UTC(vn.getUTCFullYear(),vn.getUTCMonth(),vn.getUTCDate())-7*3600000;
  return{mode:'demo',dayStart:Timestamp.fromMillis(start),scans,chats,updatedAt:serverTimestamp()};
}
function usageRef(database,uid,data,suffix='') {return doc(database,'demo_ai_usage',uid,'days',String(data.dayStart.toMillis())+suffix);}
test('demo purchase is atomic, exact price/period and immutable, active package cannot be repurchased',async()=>{
  const a=db('alice');
  await assertSucceeds(getDoc(doc(a,'demo_premium_transactions',id)));
  await assertFails(setDoc(doc(a,'demo_premium_accounts/alice'),{...period(),transactionId:id,updatedAt:serverTimestamp()}));
  await assertSucceeds(purchase(a));
  await assertFails(purchase(a,'alice','ZbCdEfGhIjKlMnOpQrSt'));
  await assertFails(setDoc(doc(a,'demo_premium_transactions',id),{status:'paid'}));
  await assertFails(deleteDoc(doc(a,'demo_premium_transactions',id)));
  await assertFails(deleteDoc(doc(a,'demo_premium_accounts/alice')));
});
test('cannot forge price, currency, real money status, expiration, owner or standalone order',async()=>{
  const a=db('alice');
  for(const patch of [{amountVnd:1},{amountVnd:200000},{currency:'USD'},{mode:'live'},{status:'paid'},
    {source:'google_play'},{expiresAt:Timestamp.fromMillis(Date.now()+90*86400000)},{uid:'bob'},{extra:'x'}]) {
    await assertFails(purchase(a,'alice',id,patch));
  }
  await assertFails(purchase(a,'bob'));
  await assertFails(setDoc(doc(a,'demo_premium_transactions',id),{...period(),uid:'alice',amountVnd:20000,currency:'VND',status:'simulated_paid',source:'demo_checkout',occurredAt:serverTimestamp()}));
});
test('transactions/accounts private to owner and admin, no health access for admin',async()=>{
  await purchase(db('alice'));
  await assertSucceeds(getDoc(doc(db('alice'),'demo_premium_accounts/alice')));
  await assertFails(getDoc(doc(db('bob'),'demo_premium_accounts/alice')));
  await assertFails(getDoc(doc(db('bob'),'demo_premium_transactions',id)));
  await assertFails(getDocs(collection(db('alice'),'demo_premium_transactions')));
  await assertSucceeds(getDocs(collection(db('admin'),'demo_premium_transactions')));
  await assertSucceeds(getDocs(collection(db('admin'),'demo_premium_accounts')));
  await assertFails(getDoc(doc(db('admin'),'users/alice')));
  const guest=env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(guest,'demo_premium_accounts/alice')));
  const unverified=env.authenticatedContext('alice',{email_verified:false}).firestore();
  await assertFails(purchase(unverified));
});
test('free quota stops at scan 3/chat 5, no resets, arbitrary day IDs or cross-user writes',async()=>{
  const a=db('alice');let data=usageData(1,0);const ref=usageRef(a,'alice',data);
  await assertSucceeds(setDoc(ref,data));
  await assertSucceeds(setDoc(ref,usageData(2,0)));
  await assertSucceeds(setDoc(ref,usageData(3,0)));
  await assertFails(setDoc(ref,usageData(4,0)));
  await assertFails(setDoc(ref,usageData(0,0)));
  await assertFails(setDoc(usageRef(a,'alice',data,'other'),data));
  await assertFails(setDoc(usageRef(a,'alice',usageData(1,0,data.dayStart.toMillis()-86400000)),usageData(1,0,data.dayStart.toMillis()-86400000)));
  await assertFails(setDoc(usageRef(a,'bob',data),data));
  await assertFails(deleteDoc(ref));
  for(let chats=1;chats<=5;chats++)await assertSucceeds(setDoc(ref,usageData(3,chats)));
  await assertFails(setDoc(ref,usageData(3,6)));
  await assertFails(getDoc(usageRef(db('bob'),'alice',data)));
});
test('premium quota 20/50 and expiration returns to free limits without resetting counts',async()=>{
  const a=db('alice');await purchase(a);
  const data=usageData(19,49),ref=usageRef(a,'alice',data);
  await env.withSecurityRulesDisabled(c=>setDoc(usageRef(c.firestore(),'alice',data),data));
  await assertSucceeds(setDoc(ref,usageData(20,49)));
  await assertSucceeds(setDoc(ref,usageData(20,50)));
  await assertFails(setDoc(ref,usageData(21,50)));
  await assertFails(setDoc(ref,usageData(20,51)));
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'demo_premium_accounts/alice'),{...period(Date.now()-31*86400000),transactionId:id,updatedAt:Timestamp.now()}));
  await assertFails(setDoc(ref,usageData(21,50)));
  await assertFails(setDoc(ref,usageData(20,51)));
  // Expired user can purchase a new demo period, not overwrite an old receipt.
  await assertSucceeds(purchase(a,'alice','XbCdEfGhIjKlMnOpQrSt'));
});
test('concurrent devices cannot exceed daily quota',async()=>{
  const first=db('alice'),second=db('alice'),data=usageData(2,0);
  await env.withSecurityRulesDisabled(c=>setDoc(usageRef(c.firestore(),'alice',data),data));
  const increment=database=>runTransaction(database,async t=>{
    const ref=usageRef(database,'alice',data),snap=await t.get(ref);
    t.set(ref,usageData(snap.data().scans+1,0));
  });
  const results=await Promise.allSettled([increment(first),increment(second)]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal((await getDoc(usageRef(first,'alice',data))).data().scans,3);
});
