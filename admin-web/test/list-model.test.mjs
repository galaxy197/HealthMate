import test from 'node:test';
import assert from 'node:assert/strict';
import {filterRows,paginateRows,normalizeSearch,collectAdminRows,canControlAccount,exportRows} from '../dist/list-model.mjs';

const foods=Array.from({length:67},(_,i)=>({id:`food-${i}`,name:i===56?'Cơm tấm sườn':'Món '+i,alternateNames:i===56?['Broken rice']:[],category:i%2?'Món chính':'Trái cây',isActive:i%3!==0,kcalPer100g:i}));
test('searches all pages with Vietnamese accents, aliases, IDs and combined filters',()=>{
  assert.equal(normalizeSearch(' ĐẬU   ĐỎ '),'dau do');
  assert.equal(filterRows(foods,'food_catalog',{search:'com tam'})[0].id,'food-56');
  assert.equal(filterRows(foods,'food_catalog',{search:'broken rice'})[0].id,'food-56');
  assert.equal(filterRows(foods,'food_catalog',{search:'food-56',category:'Trái cây',status:'active'}).length,1);
  assert.equal(filterRows(foods,'food_catalog',{search:'food-56',category:'Món chính'}).length,0);
  assert.equal(filterRows(foods,'food_catalog',{status:'archived'}).length,23);
});
test('pagination preserves STT, all navigation boundaries, empty and changed results',()=>{
  const second=paginateRows(foods,2);assert.equal(second.rows.length,25);assert.equal(second.offset,25);
  assert.equal(paginateRows(foods,100).page,3);assert.equal(paginateRows(foods,3).rows.length,17);
  assert.equal(paginateRows([],3).page,1);assert.equal(paginateRows(foods,-1).offset,0);
  assert.throws(()=>paginateRows(foods,1,0));
});
test('account roles and status filters never offer suspension for current/protected admin IDs',()=>{
  const rows=[{id:'a',email:'a@example.com',adminRole:{enabled:true}}, {id:'b',adminRole:{enabled:false}}, {id:'c',control:{status:'suspended',reason:'Kiểm thử'}}];
  assert.equal(filterRows(rows,'user_directory',{role:'admin'}).length,1);
  assert.equal(filterRows(rows,'user_directory',{status:'suspended'})[0].id,'c');
  assert.equal(canControlAccount(rows[0],'a'),false);assert.equal(canControlAccount(rows[1],'a'),false);assert.equal(canControlAccount(rows[2],'a'),true);
});
test('full loader follows cursors and rejects overflow, failure or repeated cursors without a partial result',async()=>{
  let calls=0;
  const result=await collectAdminRows(async c=>{calls++;return c?{rows:foods.slice(25),hasMore:false}:{rows:foods.slice(0,25),cursor:{id:'cursor'},hasMore:true};});
  assert.equal(result.length,67);assert.equal(calls,2);
  await assert.rejects(collectAdminRows(async()=>({rows:foods,hasMore:false}),{maxRows:20}),/vượt/);
  await assert.rejects(collectAdminRows(async c=>{if(c)throw Error('offline');return{rows:foods.slice(0,25),cursor:{id:'cursor'},hasMore:true};}),/offline/);
  await assert.rejects(collectAdminRows(async()=>({rows:foods.slice(0,25),cursor:{id:'same'},hasMore:true})),/Con trỏ/);
});
test('changed account or page aborts the next request and discards delayed rows',async()=>{
  let current=true,calls=0;
  await assert.rejects(collectAdminRows(async()=>{calls++;current=false;return{rows:foods,hasMore:false};},{isCurrent:()=>current}),/kết thúc/);
  assert.equal(calls,1);
});
test('Excel export includes every filtered row and preserves unknown and real zero',()=>{
  const sheet=exportRows('food_catalog',foods);
  assert.equal(sheet.rows.length,67);assert.equal(sheet.rows[66][0],67);
  const single=exportRows('food_catalog',[{...foods[0],fiberGPer100g:null},{...foods[1],fiberGPer100g:0}]);
  assert.equal(single.rows[0][10],null);assert.equal(single.rows[1][10],0);
  assert.throws(()=>exportRows('users',[]));assert.throws(()=>filterRows([],'users'));
});
