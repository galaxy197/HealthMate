// Opt-in ONLY. Exercises the production REST transaction adapter against a
// loopback demo Firestore. OAuth/IAM and Auth lookup use explicit test adapters.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, exportPKCS8 } from 'jose';
import { TrustedFirestore } from '../src/trusted-firestore.mjs';
import { AiPolicy, dayKey } from '../src/ai-policy.mjs';

if (process.env.HEALTHMATE_GATEWAY_EMULATOR_TESTS !== 'true' || process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  throw new Error('Requires explicit gateway demo fixture and Firestore emulator 127.0.0.1:8080. No production fallback.');
}
const project = 'demo-healthmate-gateway';
const root = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
let privateKey;
const now = Date.now();
const uidPrefix = `gw-${now}-${Math.random().toString(36).slice(2, 8)}`;
function field(value) {
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'string') return { stringValue: value };
  if (Number.isInteger(value)) return { integerValue: String(value) };
  throw new Error('Unsupported fixture field');
}
async function seed(path, value) {
  const response = await fetch(`${root}/${path}`, { method: 'PATCH', headers: { authorization: 'Bearer owner', 'content-type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(value).map(([k, v]) => [k, field(v)])) }) });
  assert.equal(response.status, 200, await response.text());
}
async function read(path) {
  const response = await fetch(`${root}/${path}`, { headers: { authorization: 'Bearer owner' } });
  assert.equal(response.status, 200); return response.json();
}
function policy() {
  const env = { AI_GATEWAY_ENABLED: 'true', FIREBASE_PROJECT_ID: project,
    GOOGLE_SERVICE_ACCOUNT_EMAIL: 'fixture@example.invalid', GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: privateKey };
  const store = new TrustedFirestore(env, { fetcher: async (url, init) => {
    if (url === 'https://oauth2.googleapis.com/token') return Response.json({ access_token: 'mock-oauth', expires_in: 3600 });
    const prefix = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
    if (!url.startsWith(prefix)) throw new Error('Fixture refuses non-Firestore/network destinations');
    return fetch(root + url.slice(prefix.length), { ...init, headers: { ...init.headers, authorization: 'Bearer owner' } });
  } });
  return new AiPolicy(store, { now: () => now });
}
before(async () => {
  const pair = await generateKeyPair('RS256', { extractable: true }); privateKey = await exportPKCS8(pair.privateKey);
  await seed('app_config/runtime', { chatbotEnabled: true, foodScannerEnabled: true, maintenanceMode: false });
});
async function user(suffix) {
  const uid = `${uidPrefix}-${suffix}`;
  await seed(`users/${uid}`, { birthDate: Date.UTC(2000, 0, 1), onboardingCompletedAt: Date.UTC(2026, 0, 1) });
  return uid;
}
test('real REST Firestore transactions serialize two contenders for the final quota', async () => {
  const uid = await user('race');
  await seed(`ai_gateway_usage/${uid}/days/${dayKey(now)}`, { uid, dayKey: dayKey(now), chats: 4 });
  const results = await Promise.allSettled([policy().reserve(uid, 'real-rest-turn-00001'), policy().reserve(uid, 'real-rest-turn-00002')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.filter(r => r.status === 'rejected' && r.reason.code === 'quota_exceeded').length, 1);
  assert.equal((await read(`ai_gateway_usage/${uid}/days/${dayKey(now)}`)).fields.chats.integerValue, '5');
});
test('real REST reservation is idempotent and duplicate phase cannot be claimed twice', async () => {
  const uid = await user('idempotent'), id = 'real-rest-turn-00003';
  const p = policy(); const result = await p.reserve(uid, id); await policy().reserve(uid, id);
  const claims = await Promise.allSettled([p.claim(uid, id, 'plan', result.dayKey), policy().claim(uid, id, 'plan', result.dayKey)]);
  assert.equal(claims.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(claims.filter(r => r.status === 'rejected' && r.reason.code === 'request_already_sent').length, 1);
  await p.finish(uid, id, 'plan', result.dayKey, 'completed');
  await p.claim(uid, id, 'answer', result.dayKey);
  await p.finish(uid, id, 'answer', result.dayKey, 'unknown');
  assert.equal((await read(`ai_gateway_usage/${uid}/days/${result.dayKey}`)).fields.chats.integerValue, '1');
  assert.equal((await read(`ai_gateway_reservations/${uid}/requests/${id}`)).fields.state.stringValue, 'unknown');
});
test('real REST transaction sees deletion marker and cannot recreate removed reservation on late finish', async () => {
  const uid = await user('deletion'), id = 'real-rest-turn-00004', p = policy();
  const result = await p.reserve(uid, id); await p.claim(uid, id, 'plan', result.dayKey);
  await seed(`account_deletions/${uid}`, { uid, state: 'requested' });
  const deleted = await fetch(`${root}/ai_gateway_reservations/${uid}/requests/${id}`, { method: 'DELETE', headers: { authorization: 'Bearer owner' } });
  assert.equal(deleted.status, 200);
  await assert.rejects(p.finish(uid, id, 'plan', result.dayKey, 'completed'), e => e.code === 'account_deleting');
  assert.equal((await fetch(`${root}/ai_gateway_reservations/${uid}/requests/${id}`, { headers: { authorization: 'Bearer owner' } })).status, 404);
});
