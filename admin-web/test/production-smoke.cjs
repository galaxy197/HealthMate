'use strict';
// Explicit opt-in. Creates only synthetic QA identities/documents in the fixed
// HealthMate project; uses end-user ID tokens to exercise deployed Rules.
// OAuth is used only for fixture setup/cleanup, never to assert client access.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
if(process.argv[2]!=='--allow-production-qa')throw Error('Requires --allow-production-qa after authorized rollout.');
(async()=>{
 const p='healthmate-app-20261013',root=path.resolve(__dirname,'../..');
 const ready=JSON.parse(fs.readFileSync(path.join(root,'build/admin-rollout-ready-with-key.json')));
 if(ready.project!==p||!ready.appCheck?.siteKey)throw Error('Expected reviewed production config.');
 const auth=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
 const account=auth.getGlobalDefaultAccount(),oauth=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
 const run=String(Date.now()),ids=[],documents=new Set(),checks=[],audits=[];
 const base=`projects/${p}/databases/(default)/documents`,firestore=`https://firestore.googleapis.com/v1/${base}`;
 const reportFile=path.join(root,`build/admin-production-smoke-${run}.json`);
 function persist(extra={}){fs.writeFileSync(reportFile,JSON.stringify({run,project:p,checks,qaUids:ids.map(u=>u.uid),auditIds:audits,...extra},null,2));}
 async function request(url,method='GET',body,bearer){const r=await fetch(url,{method,headers:{...(bearer?{Authorization:`Bearer ${bearer}`}:{ }),...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(20000)});const text=await r.text();return{status:r.status,data:text?JSON.parse(text):{}};}
 async function owner(url,method='GET',body){const r=await request(url,method,body,oauth.access_token);if(r.status>=300)throw Error(`Fixture operation failed: ${r.status}`);return r.data;}
 const value=v=>v===null?{nullValue:null}:typeof v==='string'?{stringValue:v}:typeof v==='boolean'?{booleanValue:v}:typeof v==='number'?{doubleValue:v}:Array.isArray(v)?{arrayValue:{values:v.map(value)}}:null;
 const fields=o=>Object.fromEntries(Object.entries(o).map(([k,v])=>[k,value(v)]));
 function update(relative,data,timestamps=[],precondition){return{update:{name:`${base}/${relative}`,fields:fields(data)},...(timestamps.length?{updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))}:{}),...(precondition?{currentDocument:precondition}:{})};}
 async function client(user,relative,method='GET',body){return request(`${firestore}${relative}`,method,body,user?.token);}
 async function expect(label,promise,status){const r=await promise;assert.equal(r.status,status,`${label}: ${r.status} ${r.data.error?.status??''}`);checks.push(label);persist();return r.data;}
 async function audited(user,kind,id,data,reason){
  const old=await client(user,`/${kind}/${id}`);if(![200,404].includes(old.status))throw Error(`Cannot read QA target: ${old.status}`);
  const audit=`qa-${run}-${audits.length}`,relative=`${kind}/${id}`;
  const merged={...(old.data.fields??{}),...fields(data),updatedBy:value(user.uid),lastAdminOperationId:value(audit)};
  const changed=Object.keys(merged).filter(k=>kind!=='food_catalog'||JSON.stringify(merged[k])!==JSON.stringify(old.data.fields?.[k]));
  if(!changed.includes('updatedAt'))changed.push('updatedAt');
  // Track prior to committing so cleanup still handles an ambiguous response.
  documents.add(relative);audits.push(audit);persist();
  const target={update:{name:`${base}/${relative}`,fields:merged},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}],currentDocument:old.status===404?{exists:false}:{updateTime:old.data.updateTime}};
  return client(user,':commit','POST',{writes:[target,update(`admin_audit/${audit}`,{actorUid:user.uid,entityType:kind,entityId:id,changedFields:changed,reason},['at'],{exists:false})]});
 }
 let failure;
 try {
  for(const suffix of ['admin','member']){
   const email=`healthmate.qa.admin.${run}.${suffix}@example.com`,password=crypto.randomBytes(30).toString('base64url');
   const signup=await request(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${ready.webConfig.apiKey}`,'POST',{email,password,returnSecureToken:true});
   assert.equal(signup.status,200,`QA signup ${suffix}`);const uid=signup.data.localId;
   ids.push({uid});persist();
   await owner(`https://identitytoolkit.googleapis.com/v1/projects/${p}/accounts:update`,'POST',{localId:uid,emailVerified:true});
   const login=await request(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${ready.webConfig.apiKey}`,'POST',{email,password,returnSecureToken:true});
   assert.equal(login.status,200,'QA login');ids.at(-1).token=login.data.idToken;
  }
  const [admin,member]=ids;
  const role=`admin_roles/${admin.uid}`,directory=`user_directory/${member.uid}`,metric=`users/${member.uid}/body_metrics/qa-${run}`;
  for(const d of [role,directory,metric])documents.add(d);
  await owner(firestore+':commit','POST',{writes:[update(role,{enabled:true},[],{exists:false}),update(directory,{displayName:'QA temporary member',email:`healthmate.qa.admin.${run}.member@example.com`},['createdAt','updatedAt'],{exists:false})]});
  await expect('admin reads directory using deployed Rules',client(admin,'/user_directory?pageSize=1'),200);
  await expect('ordinary member cannot list directory',client(member,'/user_directory?pageSize=1'),403);
  await expect('anonymous cannot list directory',client(null,'/user_directory?pageSize=1'),403);
  await expect('member cannot self-grant admin',client(member,':commit','POST',{writes:[update(`admin_roles/${member.uid}`,{enabled:true})]}),403);
  const metricWrite=update(metric,{weightKg:60,note:'Synthetic QA, no health record of a real user'},['createdAt','updatedAt','measuredAt'],{exists:false});
  await expect('member writes own synthetic metric',client(member,':commit','POST',{writes:[metricWrite]}),200);
  await expect('member reads own synthetic metric',client(member,`/${metric}`),200);
  await expect('admin cannot read another user metric',client(admin,`/${metric}`),403);
  const food=`qa-admin-smoke-${run}`;
  await expect('admin creates catalog food and atomic audit',audited(admin,'food_catalog',food,{name:'QA temporary food — not nutrition data',alternateNames:[],category:'QA temporary',servingBasis:'per_100g',unit:'g',kcalPer100g:100,proteinGPer100g:5,carbsGPer100g:15,fatGPer100g:2,fiberGPer100g:null,sourceLabel:'Synthetic production QA; removed after test',sourceUrl:'https://firebase.google.com/docs/emulator-suite',isEstimated:true,isActive:false},'Production QA create; synthetic, archived'),200);
  await expect('admin edits synthetic catalog food',audited(admin,'food_catalog',food,{name:'QA edited temporary food'},'Production QA edit synthetic only'),200);
  await expect('ordinary member cannot modify catalog',client(member,':commit','POST',{writes:[update(`food_catalog/${food}`,{name:'must be denied'})]}),403);
  await expect('catalog hard delete is denied',client(admin,`/food_catalog/${food}`,'DELETE'),403);
  await expect('audit deletion is denied',client(admin,`/admin_audit/${audits[0]}`,'DELETE'),403);
  await expect('admin suspends only QA member with audit',audited(admin,'account_controls',member.uid,{status:'suspended',reason:'Production QA synthetic account'},'Production QA suspend synthetic only'),200);
  await expect('suspension blocks the same member private read',client(member,`/${metric}`),403);
  await expect('admin restores QA member with audit',audited(admin,'account_controls',member.uid,{status:'active',reason:'Production QA reopen'},'Production QA reopen synthetic only'),200);
  await expect('restored member reads own data again',client(member,`/${metric}`),200);
  await owner(firestore+':commit','POST',{writes:[update(role,{enabled:false})]});
  await expect('revoked QA admin cannot list directory',client(admin,'/user_directory?pageSize=1'),403);
 } catch(e){failure=e.message;}
 finally {
  const cleanupErrors=[];
  for(const relative of documents){try{await owner(`${firestore}/${relative}`,'DELETE');}catch{cleanupErrors.push(relative);}}
  for(const user of ids){try{await owner(`https://identitytoolkit.googleapis.com/v1/projects/${p}/accounts:delete`,'POST',{localId:user.uid});}catch{cleanupErrors.push('QA Auth identity');}}
  let retainedAuditRecords=0;
  for(const id of audits){try{const r=await request(`${firestore}/admin_audit/${id}`,'GET',undefined,oauth.access_token);if(r.status===200)retainedAuditRecords++;else if(r.status!==404)cleanupErrors.push('Could not verify QA audit');}catch{cleanupErrors.push('Could not verify QA audit');}}
  persist({passed:!failure&&!cleanupErrors.length,failure:failure??null,cleanupErrors,realHealthDataTouched:false,retainedAuditRecords,appCheckBrowserAttestationTested:false});
  console.log(JSON.stringify({checksPassed:checks.length,passed:!failure&&!cleanupErrors.length,failure:failure??null,cleanupErrors:cleanupErrors.length,retainedQaAuditRecords:retainedAuditRecords,report:path.relative(root,reportFile),realHealthDataTouched:false}));
  if(failure||cleanupErrors.length)process.exitCode=1;
 }
})().catch(()=>{console.error('Production QA setup failed. No credential printed.');process.exitCode=1;});
