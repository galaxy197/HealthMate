'use strict';
// Opt-in only. No production endpoint, auth identity or credential can be set.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {applyEmulator} = require('./meal_query_migration.cjs');
if(process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw Error('Explicit local emulator required');
const root='http://127.0.0.1:8080/v1/projects/demo-healthmate-rules/databases/(default)/documents';
async function call(path,method='GET',body) {
  const response=await fetch(`${root}/${path}`,{method,headers:{Authorization:'Bearer owner','Content-Type':'application/json'},
    ...(body?{body:JSON.stringify(body)}:{})});
  assert.equal(response.status,200,`${method} fixture failed: ${response.status}`);
  return response.json();
}
test('actual local migration applies205 records, resumes checkpoints, preserves snapshots and is idempotent',async()=>{
  const uid=`migration-qa-${Date.now()}`,prefix=`users/${uid}`;
  const before=[];
  try {
    for(let i=0;i<205;i++) {
      const fields={consumedAt:{timestampValue:'2026-10-30T18:00:00Z'},
        totalKcal:{integerValue:String(i+100)},createdAt:{timestampValue:'2026-10-30T18:00:00Z'},
        updatedAt:{timestampValue:'2026-10-30T18:00:00Z'},items:{arrayValue:{values:[{stringValue:'unchanged synthetic snapshot'}]}}};
      if(i%2===0){ fields.dateKey={stringValue:'2026-10-31'};fields.timezoneOffsetMinutes={integerValue:'420'}; }
      const id=`m-${String(i).padStart(3,'0')}`;before.push({id,fields});
      await call(`${prefix}/meal_logs/${id}`,'PATCH',{fields});
    }
    // A prior crash left a misleading high checkpoint; resume must scan all.
    await call(`${prefix}/data_migrations/meal_date_key_v1`,'PATCH',{fields:{schemaVersion:{integerValue:'1'},
      state:{stringValue:'migrating'},checkpoint:{stringValue:'m-999'}}});
    const options={targetState:'partitioned',legacyTimezoneOffsetMinutes:420};
    const partitioned=await applyEmulator(uid,options);
    assert.equal(partitioned.written,205);assert.equal(partitioned.verifiedDocuments,205);
    assert.equal((await applyEmulator(uid,options)).written,0);
    const complete=await applyEmulator(uid,{...options,targetState:'complete'});
    assert.equal(complete.written,102);
    assert.equal((await applyEmulator(uid,{...options,targetState:'complete'})).written,0);
    await assert.rejects(applyEmulator(uid,options),/downgraded/);
    for(const {id,fields} of before) {
      const saved=await call(`${prefix}/meal_logs/${id}`);
      for(const field of ['totalKcal','createdAt','updatedAt','items']) assert.deepEqual(saved.fields[field],fields[field],field);
      assert.equal(saved.fields.dateKey.stringValue,'2026-10-31');
      assert.equal(saved.fields.queryPartition.stringValue,'current');
    }
    const marker=await call(`${prefix}/data_migrations/meal_date_key_v1`);
    assert.equal(marker.fields.state.stringValue,'complete');assert.ok(marker.fields.verifiedAt.timestampValue);
  } finally {
    for(const {id} of before) await fetch(`${root}/${prefix}/meal_logs/${id}`,{method:'DELETE',headers:{Authorization:'Bearer owner'}});
    await fetch(`${root}/${prefix}/data_migrations/meal_date_key_v1`,{method:'DELETE',headers:{Authorization:'Bearer owner'}});
  }
});
