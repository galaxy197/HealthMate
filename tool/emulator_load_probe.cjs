'use strict';
// Bounded synthetic benchmark. Never starts/resets emulators or calls a provider.
const {randomUUID}=require('node:crypto');
const {performance}=require('node:perf_hooks');
const origin='http://127.0.0.1:8080';
const database='projects/demo-healthmate-rules/databases/(default)';
const base=`${origin}/v1/${database}/documents`;
function validateEnvironment(env) {
  if(env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080' || env.HEALTHMATE_LOCAL_LOAD_PROBE!=='true') {
    throw Error('Requires explicit fixed loopback emulator and HEALTHMATE_LOCAL_LOAD_PROBE=true');
  }
}
function percentile(values,p) {
  if(!values.length)return null;
  const sorted=[...values].sort((a,b)=>a-b);
  return Number(sorted[Math.max(0,Math.ceil(sorted.length*p)-1)].toFixed(3));
}
async function probe({env=process.env,fetcher=fetch}={}) {
  validateEnvironment(env);
  const collection=`load_probe_catalog_${randomUUID().replaceAll('-','')}`;
  const names=Array.from({length:100},(_,i)=>`${database}/documents/${collection}/item-${String(i).padStart(3,'0')}`);
  async function call(url,body) {
    const response=await fetcher(url,{method:'POST',redirect:'error',signal:AbortSignal.timeout(10000),
      headers:{Authorization:'Bearer owner','Content-Type':'application/json'},body:JSON.stringify(body)});
    if(!response.ok)throw Error(`http-${response.status}`);
    return response.json();
  }
  const latencies=[],errors={};let returned=0,successes=0,completed=0,cleanup='not-attempted';
  let setupError=null;
  const started=performance.now();
  try {
    await call(`${base}:commit`,{writes:names.map((name,i)=>({update:{name,fields:{
      ordinal:{integerValue:String(i)},name:{stringValue:`Synthetic catalog ${i}`},isEstimated:{booleanValue:true},
      sourceLabel:{stringValue:'LOCAL LOAD FIXTURE ONLY'},kcalPer100g:{doubleValue:100+i}}}}))});
    await Promise.all(Array.from({length:10},async(_,worker)=>{
      for(let iteration=0;iteration<10;iteration++) {
        const first=((worker+iteration)%10)*10;
        const start=performance.now();
        try {
          const rows=await call(`${base}:runQuery`,{structuredQuery:{from:[{collectionId:collection}],
            orderBy:[{field:{fieldPath:'ordinal'},direction:'ASCENDING'}],
            startAt:{values:[{integerValue:String(first)}],before:true},limit:10}});
          const documents=rows.filter(row=>row.document).map(row=>row.document);
          returned+=documents.length;
          if(documents.length!==10 || documents.some((doc,i)=>doc.name!==names[first+i] ||
            Number(doc.fields.ordinal.integerValue)!==first+i))throw Error('unexpected-page');
          successes++;
        } catch(error) {
          const code=/^http-\d+$/.test(error.message)?error.message:
            error.message==='unexpected-page'?'unexpected-page':'transport-or-invalid-response';
          errors[code]=(errors[code]||0)+1;
        } finally {completed++;latencies.push(performance.now()-start);}
      }
    }));
  } catch {setupError='fixture-setup-failed';}
  finally {
    try {await call(`${base}:commit`,{writes:names.map(name=>({delete:name}))});cleanup='deleted-own-100-fixture-paths';}
    catch {cleanup='failed-own-fixture-cleanup';}
  }
  return {scope:'synthetic-local-firestore-admin-rest',project:'demo-healthmate-rules',
    concurrency:10,requestedQueryCount:100,completedQueryCount:completed,successfulQueries:successes,
    returnedDocuments:returned,errorCount:completed-successes,errors,setupError,cleanup,
    fixtureDocumentCount:100,setupCommitRequests:1,cleanupCommitRequests:1,
    queryLatencyMs:{p50:percentile(latencies,0.5),p95:percentile(latencies,0.95),max:latencies.length?Number(Math.max(...latencies).toFixed(3)):null},
    totalElapsedMs:Number((performance.now()-started).toFixed(3)),
    latencyIncludes:'HTTP request, JSON parsing and page validation; excludes setup/cleanup',
    billingReads:null,productionQuotaMeasured:false,
    limitations:'Admin bypass; no Auth/Rules/App Check/native/AI/quota/billing/user-capacity acceptance'};
}
if(require.main===module) {
  if(process.argv.length!==2){console.error('No endpoint/project/size overrides accepted');process.exitCode=1;}
  else probe().then(report=>{console.log(JSON.stringify(report,null,2));
    if(report.setupError||report.errorCount||report.cleanup!=='deleted-own-100-fixture-paths')process.exitCode=1;
  }).catch(()=>{console.error('Local load probe blocked: explicit emulator opt-in required');process.exitCode=1;});
}
module.exports={validateEnvironment,percentile,probe};
