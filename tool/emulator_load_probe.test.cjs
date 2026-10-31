'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {validateEnvironment,percentile,probe}=require('./emulator_load_probe.cjs');
const env={FIRESTORE_EMULATOR_HOST:'127.0.0.1:8080',HEALTHMATE_LOCAL_LOAD_PROBE:'true'};
test('input guard refuses absent opt-in, alternate host, port and production target before network',async()=>{
  for(const invalid of [{},{...env,HEALTHMATE_LOCAL_LOAD_PROBE:'false'},
    {...env,FIRESTORE_EMULATOR_HOST:'localhost:8080'}, {...env,FIRESTORE_EMULATOR_HOST:'127.0.0.1:8081'},
    {...env,FIRESTORE_EMULATOR_HOST:'firestore.googleapis.com'}]) {
    let called=false;await assert.rejects(probe({env:invalid,fetcher:async()=>{called=true;}}));assert.equal(called,false);
  }
  assert.doesNotThrow(()=>validateEnvironment(env));
});
test('nearest-rank percentiles handle unordered, empty and singleton measurements',()=>{
  assert.equal(percentile([],0.95),null);assert.equal(percentile([9],0.95),9);
  assert.equal(percentile([4,1,5,2,3],0.5),3);assert.equal(percentile([4,1,5,2,3],0.95),5);
});
test('bounded probe validates cursor pages and only deletes its own fixed local fixture paths',async()=>{
  let setup,queries=0,cleanup=0,active=0,maxActive=0;
  const fetcher=async(url,options)=>{
    assert.ok(url.startsWith('http://127.0.0.1:8080/v1/projects/demo-healthmate-rules/'));
    assert.equal(options.method,'POST');assert.equal(options.redirect,'error');
    const body=JSON.parse(options.body);
    if(body.writes?.[0].update){setup=body.writes;assert.equal(setup.length,100);return {ok:true,json:async()=>({})};}
    if(body.writes?.[0].delete){cleanup++;assert.deepEqual(body.writes.map(x=>x.delete),setup.map(x=>x.update.name));return {ok:true,json:async()=>({})};}
    queries++;active++;maxActive=Math.max(maxActive,active);await new Promise(resolve=>setImmediate(resolve));active--;
    assert.equal(body.structuredQuery.limit,10);assert.equal(body.structuredQuery.startAt.before,true);
    const first=Number(body.structuredQuery.startAt.values[0].integerValue);
    return {ok:true,json:async()=>setup.slice(first,first+10).map(x=>({document:x.update}))};
  };
  const report=await probe({env,fetcher});assert.equal(queries,100);assert.equal(maxActive,10);assert.equal(cleanup,1);
  assert.equal(report.successfulQueries,100);assert.equal(report.returnedDocuments,1000);assert.equal(report.billingReads,null);
});
test('setup and query failures remain failures and still attempt scoped cleanup',async()=>{
  for(const failSetup of [true,false]) {
    let calls=0,cleanup=0;
    const report=await probe({env,fetcher:async(_url,options)=>{
      const body=JSON.parse(options.body);calls++;
      if(body.writes?.[0].delete){cleanup++;return {ok:true,json:async()=>({})};}
      if(failSetup||body.structuredQuery)return {ok:false,status:503};
      return {ok:true,json:async()=>({})};
    }});
    assert.equal(cleanup,1);
    if(failSetup){assert.equal(report.setupError,'fixture-setup-failed');assert.equal(calls,2);}
    else {assert.equal(report.errorCount,100);assert.equal(report.errors['http-503'],100);}
  }
});
