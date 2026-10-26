import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {registerHooks} from 'node:module';
import {parseHTML} from 'linkedom';

const hooks=registerHooks({resolve(specifier,context,next){
  if(specifier==='./firebase.mjs'&&context.parentURL?.includes('/dist/app.mjs'))return{url:new URL('./support/connect-fixture.mjs',import.meta.url).href,shortCircuit:true};
  return next(specifier,context);
}});
let serial=0;
async function setup({member=false,pendingList=false}={}) {
  const {window,document}=parseHTML(await readFile(new URL('../dist/index.html',import.meta.url),'utf8'));
  globalThis.window=window;globalThis.document=document;
  const dialog=document.querySelector('#editor');dialog.showModal=()=>dialog.setAttribute('open','');dialog.close=()=>dialog.removeAttribute('open');
  Object.defineProperty(document.querySelector('#editor-form'),'elements',{configurable:true,get(){return this.querySelectorAll('input,select,textarea,button');}});
  Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.querySelector('option[selected]')?.value??this.querySelector('option')?.value??'';},set(value){for(const option of this.querySelectorAll('option'))option.toggleAttribute('selected',option.value===String(value));}});
  globalThis.FormData=class {constructor(form){this.values=[...form.querySelectorAll('input,textarea,select')].filter(el=>el.name&&!el.disabled&&(!(el.type==='checkbox')||el.checked)).map(el=>[el.name,el.value]);}*[Symbol.iterator](){yield* this.values;}};
  const stamp={seconds:1,nanoseconds:0,toDate:()=>new Date('2026-10-27T00:00:00Z')};
  const rows=Array.from({length:67},(_,i)=>({id:`qa-${i}`,name:i===56?'Cơm tấm sườn':'QA Món '+String(i).padStart(3,'0'),alternateNames:[],category:i%2?'Món chính':'Trái cây',isActive:true,kcalPer100g:130,proteinGPer100g:2,carbsGPer100g:28,fatGPer100g:.3,fiberGPer100g:null,sourceLabel:'Nguồn QA',sourceUrl:'https://example.com',isEstimated:true,updatedAt:stamp}));
  let release;const held=new Promise(resolve=>release=resolve);
  const api={emulator:true,projectId:'demo-healthmate-admin',rows,saves:[],listCalls:0,failSave:false,
    authChanges(callback){this.auth=callback;callback({uid:'admin',email:'admin@healthmate.local',emailVerified:true});},
    role(uid,data){this.roleData=data;data(!member);return()=>{};},
    async logout(){this.auth(null);},async counts(){return[67,3,0,0];},async config(){return{chatbotEnabled:true,foodScannerEnabled:true,maintenanceMode:false};},
    async list(kind){this.listCalls++;if(pendingList)await held;return kind==='food_catalog'?this.rows:[{id:'member',email:'member@example.com',displayName:'Member',adminRole:null,control:null},{id:'admin',email:'admin@example.com',adminRole:{enabled:true}}];},
    async save(kind,id,payload,reason,version){this.saves.push({kind,id,payload,reason,version});if(this.failSave)throw Error('Lỗi nguồn QA');const row=this.rows.find(r=>r.id===id);if(row)Object.assign(row,payload);else this.rows.push({...payload,id});},
    release,
  };
  globalThis.adminDomFixture=api;
  await import(`../dist/app.mjs?dom-test=${serial++}`);
  const flush=async()=>{for(let i=0;i<8;i++)await new Promise(resolve=>setImmediate(resolve));};
  const click=async el=>{assert.ok(el,'Expected control');el.dispatchEvent(new window.Event('click',{bubbles:true}));await flush();};
  const button=label=>[...document.querySelectorAll('button')].find(el=>el.textContent===label);
  const submit=async()=>{document.querySelector('#editor-form').dispatchEvent(new window.Event('submit',{cancelable:true}));await flush();};
  await flush();
  return{window,document,api,click,button,submit,flush};
}
test('four admin dashboard counters, full search across pages, STT and filter pagination',async()=>{
  const t=await setup();
  assert.equal(t.document.querySelectorAll('.stat-number').length,4);
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  assert.equal(t.document.querySelectorAll('tbody tr').length,25);
  await t.click(t.button('Sau'));
  assert.equal(t.document.querySelector('tbody td').textContent,'26');
  const search=t.document.querySelector('#list-search');search.value='com tam';search.dispatchEvent(new t.window.Event('input'));await t.flush();
  assert.equal(t.document.querySelectorAll('tbody tr').length,1);
  assert.match(t.document.querySelector('tbody').textContent,/Cơm tấm/);
  assert.equal(t.document.querySelector('tbody td').textContent,'1');
  assert.equal(t.api.listCalls,1,'filtering must not refetch per keystroke');
});
test('archive requires review and reason, failure keeps draft, restore preserves row and source',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  await t.click(t.button('Xóa khỏi danh mục'));
  assert.equal(t.api.saves.length,0);
  assert.match(t.document.querySelector('#editor-title').textContent,/Xóa/);
  t.document.querySelector('[name="reason"]').value='QA kiểm tra';
  t.api.failSave=true;await t.submit();
  assert.match(t.document.querySelector('#editor-error').textContent,/Lỗi nguồn/);
  assert.ok(t.document.querySelector('#editor[open]'));
  t.api.failSave=false;await t.submit();
  assert.equal(t.api.rows[0].isActive,false);assert.equal(t.api.rows[0].sourceLabel,'Nguồn QA');
  await t.click(t.button('Khôi phục'));t.document.querySelector('[name="reason"]').value='QA khôi phục';await t.submit();
  assert.equal(t.api.rows[0].isActive,true);
});
test('ordinary account never renders private admin lists; revoked role clears visible data',async()=>{
  const denied=await setup({member:true});assert.equal(denied.document.querySelector('tbody'),null);assert.match(denied.document.body.textContent,/chưa được cấp quyền/);
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  t.api.roleData(false);await t.flush();assert.equal(t.document.querySelector('tbody'),null);assert.equal(t.document.querySelector('#editor[open]'),null);
});
test('account self/admin is protected; late data after logout cannot reappear',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="user_directory"]'));
  assert.equal([...t.document.querySelectorAll('tbody button')].filter(b=>b.textContent==='Khóa truy cập').length,1);
  const delayed=await setup({pendingList:true});
  delayed.document.querySelector('[data-page="food_catalog"]').dispatchEvent(new delayed.window.Event('click'));
  await delayed.flush();await delayed.api.logout();delayed.api.release();await delayed.flush();
  assert.equal(delayed.document.querySelector('tbody'),null);assert.match(delayed.document.body.textContent,/Đăng nhập quản trị/);
});
test('catalog create validates nutrition before writing and detail safely shows user text',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  await t.click(t.button('+ Thêm món ăn'));
  const fields={id:'qa-created',name:'<script>do not run</script>',category:'Món chính',kcalPer100g:'150',proteinGPer100g:'5',carbsGPer100g:'25',fatGPer100g:'3',fiberGPer100g:'',sourceLabel:'QA',sourceUrl:'https://example.com',reason:'QA tạo'};
  for(const [key,value]of Object.entries(fields))t.document.querySelector(`[name="${key}"]`).value=value;
  t.document.querySelector('[name="isActive"]').checked=true;t.document.querySelector('[name="isEstimated"]').checked=true;
  t.document.querySelector('[name="kcalPer100g"]').value='-1';await t.submit();assert.equal(t.api.saves.length,0);assert.match(t.document.querySelector('#editor-error').textContent,/kcal/);
  t.document.querySelector('[name="kcalPer100g"]').value='150';await t.submit();assert.equal(t.api.saves.length,1);
  assert.equal(t.api.rows.at(-1).fiberGPer100g,null);assert.equal(t.document.querySelectorAll('#app script').length,0);
});
test('Google sign-in opens from login and handles popup rejection without a stuck button',async()=>{
  const t=await setup();await t.api.logout();await t.flush();
  let calls=0;
  t.api.loginGoogle=async()=>{calls++;throw{code:'auth/popup-blocked'};};
  await t.click(t.document.querySelector('#google-login'));
  assert.equal(calls,1);assert.match(t.document.querySelector('.error').textContent,/cửa sổ đăng nhập/);
  assert.equal(t.document.querySelector('#google-login').disabled,false);
  t.api.loginGoogle=async()=>{calls++;throw{code:'auth/popup-closed-by-user'};};
  await t.click(t.document.querySelector('#google-login'));
  assert.equal(calls,2);assert.match(t.document.querySelector('.error').textContent,/hủy đăng nhập/);
});

test.after(()=>hooks.deregister());
