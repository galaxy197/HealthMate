'use strict';
// Tooling only: reuse the signed-in Firebase CLI; no service account/API secret.
// Network calls below are GETs to configuration endpoints, never documents APIs.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const project = 'healthmate-app-20261013';
const normalized = value => value.replace(/\r\n/g, '\n').trim();
const hash = value => crypto.createHash('sha256').update(normalized(value)).digest('hex');

(async () => {
  const [cliRoot, output] = process.argv.slice(2);
  if (!cliRoot || !output) throw {safeCode: 'use-powershell-wrapper'};
  const destination = path.resolve(output);
  const build = path.resolve('build') + path.sep;
  if (!destination.startsWith(build)) throw {safeCode: 'output-must-be-under-build'};
  if (fs.existsSync(destination)) throw {safeCode: 'choose-a-new-backup-directory'};
  const configured = JSON.parse(fs.readFileSync('.firebaserc', 'utf8')).projects.default;
  const appOptions = fs.readFileSync('lib/firebase_options.dart', 'utf8');
  const googleServices = JSON.parse(fs.readFileSync('android/app/google-services.json', 'utf8'));
  if (configured !== project || googleServices.project_info.project_id !== project ||
      !appOptions.includes(`projectId: '${project}'`)) throw {safeCode: 'project-config-mismatch'};
  // This internal CLI helper is used only by this local read-only tool. If the
  // CLI changes its auth API, fail closed; never print its raw credential error.
  const auth = require(path.join(cliRoot, 'lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw {safeCode: 'cli-not-signed-in'};
  const token = await auth.getAccessToken(account.tokens.refresh_token,
    ['https://www.googleapis.com/auth/cloud-platform']);
  async function get(url) {
    const response = await fetch(url, {
      headers: {Authorization: `Bearer ${token.access_token}`},
      signal: AbortSignal.timeout(20000),
    });
    if (!response.ok) throw {safeCode: `configuration-get-http-${response.status}`};
    return response.json();
  }
  const release = await get(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
  if (!release.rulesetName.startsWith(`projects/${project}/rulesets/`)) throw {safeCode: 'unexpected-ruleset'};
  const ruleset = await get(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
  if (ruleset.source.files.length !== 1) throw {safeCode: 'multiple-rule-files-need-review'};
  const source = ruleset.source.files[0].content;
  const local = fs.readFileSync('firestore.rules', 'utf8');
  const database = await get(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)`);
  const indexes = await get(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/collectionGroups/-/indexes`);
  const report = {
    checkedAtUtc: new Date().toISOString(), project,
    commit: execFileSync('git', ['rev-parse', 'HEAD'], {encoding: 'utf8'}).trim(),
    firebaseCliVersion: JSON.parse(fs.readFileSync(path.join(cliRoot, 'package.json'), 'utf8')).version,
    database: {name: database.name, locationId: database.locationId, type: database.type},
    releaseName: release.name, releaseUpdatedAt: release.updateTime, rulesetName: release.rulesetName,
    deployedSha256: hash(source), localSha256: hash(local), matchesLocal: normalized(source) === normalized(local),
    collections: Object.fromEntries(['body_metrics','meal_logs','water_logs','activity_logs',
      'nutrition_targets','favorite_foods','custom_foods','recipes','goals','daily_quests','chat_sessions']
      .map(name => [name, source.includes(`match /${name}/`)])),
    indexes: (indexes.indexes || []).map(index => ({
      collectionGroup: index.name.split('/collectionGroups/')[1].split('/')[0],
      state: index.state, queryScope: index.queryScope, fields: index.fields,
    })),
  };
  fs.mkdirSync(destination, {recursive: true});
  fs.writeFileSync(path.join(destination, 'firestore.rules'), source);
  fs.writeFileSync(path.join(destination, 'metadata.json'), JSON.stringify(report, null, 2));
  // Passive rollback config, never executed here; use only in an authorized U2.
  fs.writeFileSync(path.join(destination, 'firebase.rollback.json'), JSON.stringify({
    firestore: {rules: 'firestore.rules'},
  }, null, 2));
  console.log(JSON.stringify({backupDirectory: destination, ...report}, null, 2));
})().catch(error => {
  console.error(JSON.stringify({blocked: true, code: error.safeCode || 'inspection-or-cli-auth-unavailable'}));
  process.exitCode = 1;
});
