// Executes the production admin client against local emulators. The loader maps
// official CDN imports to the SAME Firebase 13.0.0 installed for Rules tests.
import {registerHooks,createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';
import {entityVersion,foodPayload} from '../dist/validation.mjs';
const require=createRequire(new URL('../../rules-tests/package.json',import.meta.url));
const hooks=registerHooks({resolve(specifier,context,next){
  const match=/^https:\/\/www\.gstatic\.com\/firebasejs\/13\.0\.0\/firebase-(app|auth|firestore|app-check)\.js$/.exec(specifier);
  if(match)return{url:pathToFileURL(require.resolve(`firebase/${match[1]}`)).href,shortCircuit:true};
  return next(specifier,context);
}});
const sessionStore=new Map();
globalThis.window={sessionStorage:{setItem:(k,v)=>sessionStore.set(k,v),getItem:k=>sessionStore.get(k)??null,removeItem:k=>sessionStore.delete(k)}};
globalThis.location={hostname:'127.0.0.1',protocol:'http:'};
const {connect}=await import('../dist/firebase.mjs');
const api=await connect({firebase:{apiKey:'demo-key',projectId:'demo-healthmate-admin',authDomain:'demo-healthmate-admin.firebaseapp.com'},emulators:{auth:'http://127.0.0.1:9098',firestoreHost:'127.0.0.1',firestorePort:8092}});
let currentUser;
const authStop=api.authChanges(user=>currentUser=user);
const roleStop=()=>new Promise((resolve,reject)=>{
  let stop;
  const timeout=setTimeout(()=>{stop?.();reject(Error('Role confirmation timed out'));},15000);
  stop=api.role(currentUser.uid,enabled=>{if(enabled){clearTimeout(timeout);resolve(stop);}},reject);
});
let stop;
test.before(async()=>{
  await api.login('admin@healthmate.local','LocalHealthMate!2026');
  stop=await roleStop();
});
test.after(async()=>{stop?.();await api.logout();authStop();hooks.deregister();const{deleteApp,getApps}=require('firebase/app');await Promise.all(getApps().map(deleteApp));});
test('full production client lists all pages, roles and four independent counts from the server',async()=>{
  const list=await api.list('food_catalog');assert.ok(list.length>=65);
  assert.ok(list.some(row=>row.id==='qa-item-057'));
  const accounts=await api.list('user_directory');assert.ok(accounts.some(row=>row.id===currentUser.uid&&row.adminRole?.enabled));
  assert.equal((await api.counts()).length,4);
});
test('production client archive/restore is audited, confirmed and rejects stale edits',async()=>{
  const row=(await api.list('food_catalog')).find(r=>r.id==='qa-item-057');
  await api.save('food_catalog',row.id,{isActive:false},'SDK QA archive',entityVersion(row));
  const archived=(await api.list('food_catalog')).find(r=>r.id===row.id);
  assert.equal(archived.isActive,false);assert.ok(archived.lastAdminOperationId);
  await assert.rejects(api.save('food_catalog',row.id,{name:'Stale must not replace'},'SDK QA stale',entityVersion(row)),/thay đổi/);
  const audits=await api.list('admin_audit');assert.ok(audits.some(a=>a.id===archived.lastAdminOperationId&&a.reason==='SDK QA archive'));
  await api.save('food_catalog',row.id,{isActive:true},'SDK QA restore',entityVersion(archived));
});
test('new catalog food is created, edited and archived with independent audit records',async()=>{
  const id=`qa-sdk-new-${Date.now()}`;
  const payload=foodPayload({name:'SDK món mới',category:'Món chính',kcalPer100g:150,proteinGPer100g:5,carbsGPer100g:25,fatGPer100g:3,fiberGPer100g:'',sourceLabel:'Nguồn QA',sourceUrl:'https://example.com/qa',isActive:true,isEstimated:true});
  await api.save('food_catalog',id,payload,'SDK QA create',null);
  const row=(await api.list('food_catalog')).find(r=>r.id===id);assert.equal(row.fiberGPer100g,null);
  await api.save('food_catalog',id,{name:'SDK món đã sửa'},'SDK QA edit',entityVersion(row));
  const changed=(await api.list('food_catalog')).find(r=>r.id===id);assert.equal(changed.name,'SDK món đã sửa');
  await api.save('food_catalog',id,{isActive:false},'SDK QA archive created',entityVersion(changed));
  const logs=(await api.list('admin_audit')).filter(a=>a.entityId===id);assert.equal(logs.length,3);
});
test('server-backed account suspension and config changes keep audit and restore original values',async()=>{
  const member=(await api.list('user_directory')).find(r=>r.email==='member@healthmate.local');
  await api.save('account_controls',member.id,{status:'suspended',reason:'SDK QA suspend'},'SDK QA suspend',entityVersion(member.control));
  const locked=(await api.list('user_directory')).find(r=>r.id===member.id);assert.equal(locked.control.status,'suspended');
  await api.save('account_controls',member.id,{status:'active',reason:'SDK QA reopen'},'SDK QA reopen',entityVersion(locked.control));
  const config=await api.config();
  const payload={chatbotEnabled:config.chatbotEnabled,foodScannerEnabled:config.foodScannerEnabled,maintenanceMode:true,maintenanceMessage:'SDK QA maintenance'};
  await api.save('app_config','runtime',payload,'SDK QA config',entityVersion(config));
  const changed=await api.config();assert.equal(changed.maintenanceMode,true);
  await api.save('app_config','runtime',{...payload,maintenanceMode:false,maintenanceMessage:''},'SDK QA config restore',entityVersion(changed));
});

test('support SDK sends a single idempotent admin reply, changes status and reads customer follow-up',async()=>{
  const {getFirestore,collection,doc,setDoc,serverTimestamp,runTransaction,updateDoc,deleteDoc}=require('firebase/firestore');
  const {getApp}=require('firebase/app');const db=getFirestore(getApp());
  const ref=doc(collection(db,'support_tickets')),uid=currentUser.uid;
  await setDoc(ref,{uid,type:'bug',title:'SDK lỗi lưu bữa',description:'Nội dung QA trên emulator.',status:'open',
    messageCount:0,lastMessageId:'',updatedBy:uid,deleting:false,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
  try {
    const initial=await api.supportThread(ref.id);assert.equal(initial.messages.length,0);
    const messageId=api.newSupportMessageId();
    await assert.rejects(api.supportReply(ref.id,messageId,'   '),/Nội dung/);
    await api.supportReply(ref.id,messageId,'Bạn vui lòng thử lại.');
    await api.supportReply(ref.id,messageId,'Bạn vui lòng thử lại.');
    const replied=await api.supportThread(ref.id);assert.equal(replied.messages.length,1);assert.equal(replied.messages[0].role,'admin');
    await assert.rejects(api.supportStatus(ref.id,'resolved',entityVersion(initial.ticket)),/vừa thay đổi/);
    await api.supportStatus(ref.id,'resolved',entityVersion(replied.ticket));
    const followup=doc(collection(ref,'messages'));
    await runTransaction(db,async t=>{
      const parent=await t.get(ref),count=parent.data().messageCount+1;
      t.set(followup,{authorUid:uid,role:'customer',text:'Mình đã thử, cảm ơn.',sequence:count,createdAt:serverTimestamp()});
      t.update(ref,{status:'open',messageCount:count,lastMessageId:followup.id,updatedBy:uid,updatedAt:serverTimestamp()});
    });
    const result=await api.supportThread(ref.id);assert.equal(result.ticket.status,'open');assert.equal(result.messages.length,2);
    assert.equal(result.messages[1].role,'customer');
  } finally {
    const thread=await api.supportThread(ref.id);
    await updateDoc(ref,{deleting:true,updatedBy:uid,updatedAt:serverTimestamp()});
    for(const message of thread.messages)await deleteDoc(doc(ref,'messages',message.id));
    await deleteDoc(ref);
  }
});
