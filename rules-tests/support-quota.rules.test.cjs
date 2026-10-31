const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {before,beforeEach,after,test}=require('node:test');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,deleteDoc,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
let env;
const id='AbCdEfGhIjKlMnOpQrSt',otherId='BbCdEfGhIjKlMnOpQrSt';
const client=uid=>env.authenticatedContext(uid,{email_verified:true,auth_time:Math.floor(Date.now()/1000)}).firestore();
const day=()=>{const local=new Date(Date.now()+7*3600000);return Timestamp.fromMillis(Date.UTC(local.getUTCFullYear(),local.getUTCMonth(),local.getUTCDate())-7*3600000);};
const ticket=(uid='alice')=>({uid,type:'bug',title:'Synthetic report',description:'Synthetic fixture only',status:'open',
 createdAt:serverTimestamp(),updatedAt:serverTimestamp(),messageCount:0,lastMessageId:'',updatedBy:uid,deleting:false});
const usage=(ticketId=id,count=1)=>({schemaVersion:1,dayStart:day(),count,lastTicketId:ticketId,lastCreatedAt:serverTimestamp(),updatedAt:serverTimestamp()});
function create(db,{ticketId=id,count=1,patch={}}={}){
 const batch=writeBatch(db);batch.set(doc(db,'support_tickets',ticketId),ticket());
 batch.set(doc(db,'support_usage/alice'),{...usage(ticketId,count),...patch});return batch.commit();
}
async function seedUsage(patch={}){
 await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'support_usage/alice'),{
  ...usage(),lastCreatedAt:Timestamp.fromMillis(Date.now()-120000),updatedAt:Timestamp.fromMillis(Date.now()-120000),...patch}));
}
before(async()=>{const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8080').split(':');
 env=await initializeTestEnvironment({projectId:'demo-healthmate-support-quota',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')}});});
beforeEach(()=>env.clearFirestore());after(()=>env?.cleanup());

test('both directions require one newly created owned ticket and exact quota reservation',async()=>{
 const a=client('alice');
 await assertFails(setDoc(doc(a,'support_tickets',id),ticket()));
 await assertFails(setDoc(doc(a,'support_usage/alice'),usage()));
 await assertFails(create(a,{patch:{lastTicketId:otherId}}));
 await assertSucceeds(create(a));
 await assertFails(updateDoc(doc(a,'support_usage/alice'),usage(otherId,2)));
 await assertFails(deleteDoc(doc(a,'support_usage/alice')));
 assert.equal((await getDoc(doc(a,'support_usage/alice'))).data().count,1);
});
test('direct writes cannot reset same-day allowance or exceed three new tickets',async()=>{
 const a=client('alice');await seedUsage({count:3});
 await assertFails(create(a,{count:4}));await assertFails(create(a,{count:1}));
 await assertFails(create(a,{count:3}));await assertFails(create(a,{count:2}));
});
test('server cooldown denies immediate creation, permits one after sixty seconds',async()=>{
 const a=client('alice');await seedUsage({lastCreatedAt:Timestamp.now()});
 await assertFails(create(a,{count:2}));
 await seedUsage({lastCreatedAt:Timestamp.fromMillis(Date.now()-61000)});
 await assertSucceeds(create(a,{count:2}));
});
test('quota resets only at the trusted Vietnam day boundary; future/backdated windows fail',async()=>{
 const a=client('alice');await seedUsage({count:3,dayStart:Timestamp.fromMillis(day().toMillis()-86400000)});
 await assertSucceeds(create(a,{count:1}));
 await env.clearFirestore();await seedUsage({count:3});
 await assertFails(create(a,{count:1,patch:{dayStart:Timestamp.fromMillis(day().toMillis()+86400000)}}));
 await assertFails(create(a,{count:1,patch:{dayStart:Timestamp.fromMillis(day().toMillis()-86400000)}}));
});
test('counter cannot authorize multiple creations in one batch or reuse an existing ticket',async()=>{
 const a=client('alice'),batch=writeBatch(a);
 batch.set(doc(a,'support_tickets',id),ticket());batch.set(doc(a,'support_tickets',otherId),ticket());
 batch.set(doc(a,'support_usage/alice'),usage());await assertFails(batch.commit());
 await assertSucceeds(create(a));
 await seedUsage({count:1});
 await assertFails(setDoc(doc(a,'support_usage/alice'),usage(id,2)));
});
test('two independent contexts contesting the final daily slot cannot exceed it',async()=>{
 await seedUsage({count:2});
 const send=(db,ticketId)=>runTransaction(db,async t=>{
  const ref=doc(db,'support_usage/alice'),before=await t.get(ref);
  t.set(doc(db,'support_tickets',ticketId),ticket());t.set(ref,usage(ticketId,before.data().count+1));
 });
 const results=await Promise.allSettled([send(client('alice'),id),send(client('alice'),otherId)]);
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
 assert.equal((await getDoc(doc(client('alice'),'support_usage/alice'))).data().count,3);
});
test('foreign UID, guest and unverified owner cannot reserve or inspect allowance',async()=>{
 await assertSucceeds(create(client('alice')));
 for(const db of [client('bob'),env.unauthenticatedContext().firestore(),env.authenticatedContext('alice',{email_verified:false}).firestore()]){
  await assertFails(getDoc(doc(db,'support_usage/alice')));await assertFails(create(db,{ticketId:otherId,count:2}));
 }
});
test('deletion tombstone blocks reservations and permits only owner quota cleanup',async()=>{
 const a=client('alice');await assertSucceeds(create(a));
 await setDoc(doc(a,'account_deletions/alice'),{uid:'alice',schemaVersion:1,executor:'client',state:'requested',checkpoint:0,requestedAt:serverTimestamp(),updatedAt:serverTimestamp()});
 await assertFails(create(a,{ticketId:otherId,count:2}));
 await assertFails(deleteDoc(doc(client('bob'),'support_usage/alice')));
 await assertSucceeds(deleteDoc(doc(a,'support_usage/alice')));
 await assertFails(create(a,{ticketId:otherId,count:1}));
});
