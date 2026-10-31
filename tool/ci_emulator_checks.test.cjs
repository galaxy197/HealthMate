'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const path=require('node:path');
const {main}=require('./ci_emulator_checks.cjs');
const local={FIRESTORE_EMULATOR_HOST:'127.0.0.1:8080',FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:9099'};

test('CI refuses missing or remote endpoints before a command or reset',async()=>{
  for(const env of [{},{...local,FIRESTORE_EMULATOR_HOST:'example.com:8080'},
    {...local,FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:9098'}]) {
    let calls=0;
    await assert.rejects(main({env,execute:()=>calls++,fetcher:()=>calls++}),/local/);
    assert.equal(calls,0);
  }
});

test('CI finishes clearing Rules before fixed demo reset, seed and SDK checks',async()=>{
  const calls=[];
  await main({env:local,execute:(...args)=>calls.push({type:'run',args}),
    fetcher:async(url,options)=>{calls.push({type:'reset',url,options});return {ok:true};}});
  assert.equal(calls[0].args[3],path.resolve(__dirname,'../rules-tests'));
  assert.ok(calls[0].args[1].slice(1).every(file=>!file.includes('/')));
  assert.equal(calls[1].type,'reset');
  assert.equal(calls[1].url,'http://127.0.0.1:8080/emulator/v1/projects/demo-healthmate-rules/databases/(default)/documents');
  assert.equal(calls[1].options.method,'DELETE');
  assert.deepEqual(calls[2].args[1],['tool/test_h1_catalog_import.cjs']);
  const sdk=calls.filter(call=>call.type==='run'&&call.args[1][0]==='test');
  assert.equal(sdk.length,5);
  assert.ok(sdk.every(call=>call.args[1].filter(arg=>arg.endsWith('.dart')).length===1));
  assert.ok(sdk[4].args[1].includes('test/support_repository_integration.dart'));
  assert.equal(calls.filter(call=>call.type==='reset').length,5);
  for(let i=1;i<16;i+=3) {
    assert.equal(calls[i].type,'reset');
    assert.deepEqual(calls[i+1].args[1],['tool/test_h1_catalog_import.cjs']);
    assert.equal(calls[i+2].args[1][0],'test');
  }
  assert.equal(calls.at(-1).args[2].HEALTHMATE_GATEWAY_EMULATOR_TESTS,'true');
});

test('CI stops after Rules or reset failure, never starts SDK on invalid fixtures',async()=>{
  let resets=0;
  await assert.rejects(main({env:local,execute:()=>{throw Error('Rules failed');},
    fetcher:()=>resets++}),/Rules failed/);
  assert.equal(resets,0);
  const calls=[];
  await assert.rejects(main({env:local,execute:(...args)=>calls.push(args),
    fetcher:async()=>({ok:false})}),/reset/);
  assert.equal(calls.length,1);
});
