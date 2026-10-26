'use strict';
// Read-only project metadata. OAuth remains in memory; response bodies are never logged.
const fs = require('node:fs');
const path = require('node:path');
const project = 'healthmate-app-20261013', number = '471712188542';
(async()=>{
  const [cliRoot, output] = process.argv.slice(2);
  if (!cliRoot || !output || !path.resolve(output).startsWith(path.resolve('build')+path.sep)) throw {safeCode:'invalid-local-output'};
  const auth = require(path.join(cliRoot,'lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw {safeCode:'cli-not-signed-in'};
  const token = await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  async function get(url) {
    const r = await fetch(url,{headers:{Authorization:`Bearer ${token.access_token}`},signal:AbortSignal.timeout(20000)});
    return {status:r.status,data:r.ok?await r.json():null};
  }
  const services = await get(`https://firebaseappcheck.googleapis.com/v1/projects/${number}/services`);
  const firestore = await get(`https://firebaseappcheck.googleapis.com/v1/projects/${number}/services/firestore.googleapis.com`);
  const config = await get(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`);
  const report = {checkedAtUtc:new Date().toISOString(),project,
    appCheck:{status:services.status,services:services.data?.services?.map(s=>({name:s.name,enforcementMode:s.enforcementMode}))??[],
      firestore:{status:firestore.status,enforcementMode:firestore.data?.enforcementMode??null}},
    auth:{status:config.status,emailEnumerationProtection:config.data?.emailPrivacyConfig?.enableImprovedEmailPrivacy??null,
      emailPasswordEnabled:config.data?.signIn?.email?.enabled??null}};
  fs.writeFileSync(output,JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));
})().catch(e=>{console.error(JSON.stringify({blocked:true,code:e.safeCode||'configuration-read-failed'}));process.exitCode=1;});
