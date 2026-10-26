'use strict';
// Reviewable MVP rollout candidate only. This script never deploys anything.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
if(process.argv.slice(2).some(a=>!['--wellness','--insights'].includes(a)) || process.argv.length>3) throw new Error('Unknown candidate option');
const wellness = process.argv.includes('--wellness');
const insights = process.argv.includes('--insights');
const out = path.resolve(insights ? 'build/wellness-insights-production-candidate' : wellness ? 'build/wellness-production-candidate' : 'build/stage10-production-candidate');
const hash = s=>crypto.createHash('sha256').update(s.replace(/\r\n/g,'\n').trim()).digest('hex');
let source=fs.readFileSync('firestore.rules','utf8');
function replaceBlock(prefix,replacement) {
  const hits=[...source.matchAll(new RegExp('^'+prefix.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'gm'))];
  if(hits.length!==1) throw new Error('Expected one reviewed Rules block: '+prefix);
  const at=hits[0].index;
  const lineEnd=source.indexOf('\n',at),start=source.lastIndexOf('{',lineEnd);
  let depth=1,end=start+1;
  for(;end<source.length&&depth;end++) depth+=source[end]==='{'?1:source[end]==='}'?-1:0;
  if(depth) throw new Error('Unbalanced Rules block');
  source=source.slice(0,at)+replacement+source.slice(end);
}
for(const name of ['accountAllowed','admin','adminFields','audited','alias','aliases','catalogFields','validAdminFood']) {
  replaceBlock(`    function ${name}(`,'');
}
replaceBlock('    function owns(',`    function owns(uid) {
      return request.auth != null && request.auth.token.email_verified == true
        && request.auth.uid == uid;
    }`);
replaceBlock('    match /food_catalog/',`    match /food_catalog/{foodId} {
      allow read: if request.auth != null && request.auth.token.email_verified == true;
      allow write: if false;
    }`);
for(const collection of ['admin_roles','user_directory','account_controls','app_config','admin_audit']) {
  replaceBlock(`    match /${collection}/`,'');
}
if(/admin_roles|account_controls|admin_audit|function admin\(/.test(source)) throw new Error('Unexpected admin scope');
const base=JSON.parse(fs.readFileSync(insights ? 'build/wellness-rollout-after-20261026/metadata.json' : 'build/stage10-production-review/metadata.json','utf8'));
if(base.project!=='healthmate-app-20261013') throw new Error('Wrong baseline project');
fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'firestore.rules'),source);
fs.writeFileSync(path.join(out,'firebase.json'),JSON.stringify({firestore:{rules:'firestore.rules'}},null,2));
fs.writeFileSync(path.join(out,'metadata.json'),JSON.stringify({project:base.project,baseRuleset:base.rulesetName,
  baseSha256:base.deployedSha256,candidateSha256:hash(source),status:'prepared, not deployed',
  scope:insights ? 'wellness preferences and confirmed step budgets; retains reviewed MVP and no admin rollout' : wellness ? 'verified-email owner access + nutrient snapshots + sleep/plans/steps; no admin rollout' :
    'verified-email owner access + current MVP nutrition snapshots; no admin rollout'},null,2));
console.log(JSON.stringify({directory:out,candidateSha256:hash(source),status:'prepared, not deployed'}));
