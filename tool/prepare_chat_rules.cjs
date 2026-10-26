'use strict';
// Prepare a minimal candidate from the production backup, never local dirty Rules.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const before = path.resolve('build/chat-limits-production-before');
const after = path.resolve('build/chat-limits-production-candidate');
const metadata = JSON.parse(fs.readFileSync(path.join(before, 'metadata.json')));
const hash = s => crypto.createHash('sha256').update(s.replace(/\r\n/g, '\n').trim()).digest('hex');
const source = fs.readFileSync(path.join(before, 'firestore.rules'), 'utf8');
if (metadata.project !== 'healthmate-app-20261013' || hash(source) !== metadata.deployedSha256) throw new Error('Production backup mismatch');
function chatBlock(s) {
  const at = s.indexOf('match /chat_sessions/{sessionId}');
  if (at < 0 || s.indexOf('match /chat_sessions/{sessionId}', at + 1) >= 0) throw new Error('Expected one chat block');
  // The first brace is the path parameter, the second is the block delimiter.
  const start = s.indexOf('{', s.indexOf('}', at) + 1);
  let depth = 1, i = start + 1;
  for (; i < s.length && depth; i++) depth += (s[i] === '{' ? 1 : s[i] === '}' ? -1 : 0);
  if (depth) throw new Error('Unbalanced chat rules');
  return { at, end: i, text: s.slice(at, i) };
}
const block = chatBlock(source);
const old = '&& d.messageCount <= 40 && d.messageCount % 2 == 0';
if (block.text.split(old).length !== 2) throw new Error('Expected one old limit');
const changed = block.text.replace(old, old.replace('<= 40', '<= 100'));
if (hash(changed) !== hash(chatBlock(fs.readFileSync('firestore.rules', 'utf8')).text)) throw new Error('Local and production chat rules differ beyond approved limit');
const candidate = source.slice(0, block.at) + changed + source.slice(block.end);
if (candidate.replace('&& d.messageCount <= 100 && d.messageCount % 2 == 0', old) !== source) throw new Error('Unexpected rules delta');
fs.mkdirSync(after, { recursive: true });
fs.writeFileSync(path.join(after, 'firestore.rules'), candidate);
fs.writeFileSync(path.join(after, 'firebase.json'), JSON.stringify({ firestore: { rules: 'firestore.rules' } }, null, 2));
fs.writeFileSync(path.join(after, 'metadata.json'), JSON.stringify({ project: metadata.project, baseRuleset: metadata.rulesetName,
  baseSha256: hash(source), candidateSha256: hash(candidate), change: 'chat messageCount 40 -> 100 only' }, null, 2));
console.log(JSON.stringify({ candidateDirectory: after, baseSha256: hash(source), candidateSha256: hash(candidate), change: 'chat messageCount 40 -> 100 only' }));
