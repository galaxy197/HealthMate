import test from 'node:test';
import assert from 'node:assert/strict';
import {demoRevenue,dateBoundary,revenueExport,vietnamDateKey} from '../dist/revenue-model.mjs';
const stamp = s => ({toMillis:()=>Date.parse(s)});
const order = (id,at,uid='alice') => ({id,uid,mode:'demo',planId:'premium_demo_30d',amountVnd:20000,currency:'VND',status:'simulated_paid',source:'demo_checkout',occurredAt:stamp(at)});
test('Vietnam period boundaries include midnight and exclude the next day',()=>{
  const rows=[order('a','2026-10-29T17:00:00Z'),order('b','2026-10-30T16:59:59Z','bob'),order('c','2026-10-30T17:00:00Z')];
  const result=demoRevenue(rows,[],{start:'2026-10-30',end:'2026-10-30'});
  assert.equal(result.amountVnd,40000);assert.equal(result.count,2);assert.equal(result.buyers,2);
  assert.deepEqual(result.days,[{day:'2026-10-30',amountVnd:40000,transactions:2}]);
  assert.equal(vietnamDateKey(new Date('2026-10-29T17:00:00Z')),'2026-10-30');
});
test('empty period is zero; active accounts do not manufacture revenue',()=>{
  const accounts=[{id:'gift',mode:'demo',planId:'premium_demo_30d',startedAt:stamp('2026-10-01'),expiresAt:stamp('2026-11-01')},
    {id:'expired',mode:'demo',planId:'premium_demo_30d',startedAt:stamp('2026-09-01'),expiresAt:stamp('2026-10-01')}];
  const r=demoRevenue([],accounts,{start:'2026-10-29',end:'2026-10-30',now:new Date('2026-10-30')});
  assert.equal(r.amountVnd,0);assert.equal(r.activeAccounts,1);assert.equal(r.days.length,2);
});
test('reject mixed environments, duplicate IDs, price/currency tampering and missing timestamps',()=>{
  const a=order('a','2026-10-30T00:00:00Z'),range={start:'2026-10-30',end:'2026-10-30'};
  for(const change of [{mode:'live'},{status:'paid'},{amountVnd:NaN},{amountVnd:1},{currency:'USD'},{occurredAt:null},{source:'gift'}]) {
    assert.throws(()=>demoRevenue([{...a,...change}],[],range));
  }
  assert.throws(()=>demoRevenue([a,a],[],range));
  for(const start of ['2026-02-30','not a date']) assert.throws(()=>dateBoundary(start));
  assert.throws(()=>demoRevenue([],[],{start:'2026-11-01',end:'2026-10-01'}));
});
test('export keeps demo label, complete filtered transactions and numeric VND',()=>{
  const r=demoRevenue([order('a','2026-10-30T00:00:00Z')],[],{start:'2026-10-30',end:'2026-10-30'});
  const data=revenueExport(r);assert.match(data.name,/mô phỏng/);
  assert.equal(data.rows[0][5],20000);assert.equal(data.rows[0][7],'DEMO - KHÔNG THU TIỀN');
});
