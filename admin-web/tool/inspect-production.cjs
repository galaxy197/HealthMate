'use strict';
// Read-only account/config checks. Never prints tokens or unrelated accounts.
const fs=require('node:fs'),path=require('node:path');
(async()=>{
  const [cliRoot,email,out]=process.argv.slice(2);
  if(!cliRoot||!email||!out||!path.resolve(out).startsWith(path.resolve('build')+path.sep))throw Error('invalid-arguments');
  const auth=require(path.join(cliRoot,'lib/auth.js'));
  const account=auth.getGlobalDefaultAccount();if(!account)throw Error('cli-not-signed-in');
  const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  const project='healthmate-app-20261013',number='471712188542',appId='1:471712188542:web:55c79778766d3cf71eb02f';
  async function request(url,body){
    const r=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(20000)});
    return {status:r.status,data:r.ok?await r.json():null};
  }
  const lookup=await request(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:lookup`,{email:[email]});
  const web=await request(`https://firebase.googleapis.com/v1beta1/projects/${project}/webApps/${appId}/config`);
  const check=await request(`https://firebaseappcheck.googleapis.com/v1/projects/${number}/apps/${appId}/recaptchaEnterpriseConfig`);
  const hosting=await request(`https://firebasehosting.googleapis.com/v1beta1/projects/${project}/sites`);
  const user=lookup.data?.users?.find(u=>u.email?.toLowerCase()===email.toLowerCase());
  const report={checkedAtUtc:new Date().toISOString(),project,
    accountLookupStatus:lookup.status,requestedAdmin:user?{uid:user.localId,email:user.email,emailVerified:user.emailVerified===true,disabled:user.disabled===true}:null,
    webConfigStatus:web.status,webConfig:web.data,appCheckStatus:check.status,appCheck:check.data,
    hostingStatus:hosting.status,hostingSites:hosting.data?.sites?.map(s=>({name:s.name,defaultUrl:s.defaultUrl}))??[]};
  fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,JSON.stringify(report,null,2));
  console.log(JSON.stringify({project,accountLookupStatus:lookup.status,adminExists:!!user,adminVerified:user?.emailVerified===true,
    webConfigStatus:web.status,appCheckStatus:check.status,appCheckConfigured:!!check.data?.siteKey,hostingStatus:hosting.status,hostingSites:report.hostingSites.length,
    scope:'read-only; no role granted or deployment'}));
})().catch(()=>{console.error('Read-only admin readiness check failed; inspect local setup. No response body or credential printed.');process.exitCode=1;});
