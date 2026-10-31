import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, exportPKCS8, jwtVerify } from 'jose';
import { TrustedFirestore } from '../src/trusted-firestore.mjs';
import { ApiError } from '../src/protocol.mjs';

let privateKey, publicKey;
before(async () => {
  const key = await generateKeyPair('RS256', { extractable: true }); publicKey = key.publicKey; privateKey = await exportPKCS8(key.privateKey);
});
const env = () => ({ AI_GATEWAY_ENABLED: 'true', FIREBASE_PROJECT_ID: 'demo-healthmate-gateway',
  GOOGLE_SERVICE_ACCOUNT_EMAIL: 'local-fixture@example.invalid', GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: privateKey });
const goodUser = { localId: 'user-a', validSince: '100', emailVerified: true, disabled: false };
function adapter({ user = goodUser, missing = false } = {}) {
  const calls = [];
  const store = new TrustedFirestore(env(), { fetcher: async (url, init) => {
    calls.push({ url, init });
    if (url === 'https://oauth2.googleapis.com/token') {
      const assertion = init.body.get('assertion');
      const { payload } = await jwtVerify(assertion, publicKey, { algorithms: ['RS256'], audience: url, issuer: 'local-fixture@example.invalid' });
      assert.equal(payload.exp - payload.iat, 3600);
      assert.equal(payload.scope, 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/identitytoolkit');
      return Response.json({ access_token: 'local-mock-oauth-token', expires_in: 3600 });
    }
    assert.equal(url, 'https://identitytoolkit.googleapis.com/v1/projects/demo-healthmate-gateway/accounts:lookup');
    assert.deepEqual(JSON.parse(init.body), { localId: ['user-a'] });
    assert.equal(init.headers.authorization, 'Bearer local-mock-oauth-token');
    return Response.json({ users: missing ? [] : [user] });
  } });
  return { store, calls };
}
test('runtime OAuth signer and privileged lookup validate current identity and cache short-lived access token', async () => {
  const { store, calls } = adapter();
  await store.assertIdentity({ uid: 'user-a', authTime: 100 });
  await store.assertIdentity({ uid: 'user-a', authTime: 101 });
  assert.equal(calls.filter(c => c.url.endsWith('/token')).length, 1);
  assert.equal(calls.filter(c => c.url.endsWith('accounts:lookup')).length, 2);
});
for (const [label, changes] of [
  ['disabled', { disabled: true }], ['revoked', { validSince: '102' }],
  ['unverified current email', { emailVerified: false }], ['missing revocation timestamp', { validSince: undefined }],
  ['invalid revocation timestamp', { validSince: 'NaN' }], ['wrong UID', { localId: 'user-b' }],
]) test(`privileged identity lookup rejects ${label}`, async () => {
  const { store } = adapter({ user: { ...goodUser, ...changes } });
  await assert.rejects(store.assertIdentity({ uid: 'user-a', authTime: 101 }), e => e instanceof ApiError && e.status === 401);
});
test('deleted identity and unavailable privilege fail closed', async () => {
  await assert.rejects(adapter({ missing: true }).store.assertIdentity({ uid: 'user-a', authTime: 101 }), e => e.status === 401);
  const store = new TrustedFirestore(env(), { fetcher: async () => Response.json({ error: 'private IAM diagnostic' }, { status: 403 }) });
  await assert.rejects(store.assertIdentity({ uid: 'user-a', authTime: 101 }), e => e.code === 'policy_unavailable' && !e.message.includes('private'));
});
