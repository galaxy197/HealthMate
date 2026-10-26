import test from 'node:test';
import assert from 'node:assert/strict';
import { foodPayload,configPayload,validFoodId,number,changedFields,entityVersion } from '../dist/validation.mjs';
const fields={name:'Cơm tấm',category:'Món chính',kcalPer100g:'200',proteinGPer100g:'12',carbsGPer100g:'23',fatGPer100g:'7',fiberGPer100g:'',sourceLabel:'Nguồn tham khảo',sourceUrl:'https://example.com/food',isEstimated:true,isActive:true};
test('conflict detection preserves timestamp nanoseconds and separates missing from legacy documents',()=>{
  assert.notEqual(entityVersion({updatedAt:{seconds:1,nanoseconds:1}}),entityVersion({updatedAt:{seconds:1,nanoseconds:2}}));
  assert.equal(entityVersion(null),null);assert.equal(entityVersion({}),'legacy');
});
test('nutrition distinguishes missing from zero and accepts Vietnamese decimal input',()=>{
  assert.equal(foodPayload(fields).fiberGPer100g,null);
  assert.equal(foodPayload({...fields,fiberGPer100g:'0'}).fiberGPer100g,0);
  assert.equal(foodPayload({...fields,proteinGPer100g:'12,5'}).proteinGPer100g,12.5);
  for(const value of ['',NaN,Infinity,-1,1001])assert.throws(()=>number(value,'kcal',1000));
});
test('catalog rejects impossible mass, unsafe URLs and incomplete portions',()=>{
  for(const patch of [{fatGPer100g:100,proteinGPer100g:100},{sourceUrl:'javascript:alert(1)'},{sourceUrl:'https://user:password@example.com'},{servingLabel:'tô'},{servingGrams:'0'},{alternateNames:Array(9).fill('tên').join('\n')}])assert.throws(()=>foodPayload({...fields,...patch}));
  const payload=foodPayload({...fields,servingLabel:'phần',servingGrams:'450'});
  assert.equal(payload.servingGrams,450);assert.equal(payload.kcalPer100g,200);
});
test('maintenance requires a message; config contains only permitted switches',()=>{
  assert.throws(()=>configPayload({maintenanceMode:true,maintenanceMessage:' '}));
  assert.deepEqual(Object.keys(configPayload({chatbotEnabled:true,maintenanceMessage:'',apiKey:'secret'})).sort(),['chatbotEnabled','foodScannerEnabled','maintenanceMode','maintenanceMessage'].sort());
});
test('IDs are bounded and audit retains only fields changed in catalog',()=>{
  for(const id of ['../x','A','a/b','', 'a'.repeat(101)])assert.throws(()=>validFoodId(id));
  assert.equal(validFoodId('vn-com-tam-1'),'vn-com-tam-1');
  assert.deepEqual(changedFields({name:'A',updatedBy:'admin'},{name:'B',updatedBy:'admin'},'food_catalog'),['name']);
});
