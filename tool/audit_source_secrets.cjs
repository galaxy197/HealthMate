'use strict';
// Source inventory only; never prints matched values or scans user credential stores.
const {execFileSync} = require('node:child_process');
const fs = require('node:fs');
const paths = [...new Set(execFileSync('git', ['-c','core.quotepath=false','ls-files','-z','--cached','--others','--exclude-standard'], {encoding:'utf8'}).split('\0').filter(Boolean))];
const patterns = [
  ['private-key', /-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----/g],
  ['service-account', /"type"\s*:\s*"service_account"/g],
  ['oauth-access-token', /ya29\.[A-Za-z0-9_-]{30,}/g],
  ['github-token', /(?:ghp_|github_pat_)[A-Za-z0-9_]{30,}/g],
  ['provider-secret', /sk-(?:proj-|live-)[A-Za-z0-9_-]{20,}/g],
  ['embedded-app-check-debug-token', /"HEALTHMATE_APP_CHECK_DEBUG_TOKEN"\s*:\s*"[A-Za-z0-9-]{20,}"/g],
  ['embedded-app-check-debug-argument', /HEALTHMATE_APP_CHECK_DEBUG_TOKEN=[A-Za-z0-9-]{20,}/g],
];
const findings = []; let scanned = 0;
for (const file of paths) {
  if (!/\.(?:dart|mjs|cjs|js|jsonc?|ya?ml|toml|xml|kt|kts|md|ps1|properties|env|txt)$/.test(file) || !fs.existsSync(file)) continue;
  const text = fs.readFileSync(file, 'utf8'); scanned++;
  for (const [kind, regex] of patterns) {
    for (const hit of text.matchAll(regex)) findings.push({file,kind,line:text.slice(0,hit.index).split('\n').length});
  }
}
console.log(JSON.stringify({scannedTextFiles:scanned,findings,scope:'tracked and non-ignored untracked source; not an APK/credential-store audit'}));
if (findings.length) process.exitCode=1;
