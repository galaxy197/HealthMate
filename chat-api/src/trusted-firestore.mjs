import { importPKCS8, SignJWT } from 'jose';
import { ApiError } from './protocol.mjs';

const tokenCache = new WeakMap();
const DEADLINE_MS = 8000;
const encode = value => {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'string') return { stringValue: value };
  if (Number.isSafeInteger(value)) return { integerValue: String(value) };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encode) } };
  if (typeof value === 'object') return { mapValue: { fields: fields(value) } };
  throw new ApiError(503, 'policy_invalid');
};
const fields = value => Object.fromEntries(Object.entries(value).map(([k, v]) => [k, encode(v)]));
function decode(value) {
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return Date.parse(value.timestampValue);
  if ('arrayValue' in value) return (value.arrayValue.values ?? []).map(decode);
  if ('mapValue' in value) return decodeFields(value.mapValue.fields ?? {});
  throw new ApiError(503, 'policy_invalid');
}
const decodeFields = value => Object.fromEntries(Object.entries(value).map(([k, v]) => [k, decode(v)]));

export class TrustedFirestore {
  constructor(env, { fetcher = fetch, now = Date.now } = {}) {
    if (env.AI_GATEWAY_ENABLED !== 'true' || !/^[a-z0-9-]{6,63}$/.test(env.FIREBASE_PROJECT_ID ?? '') ||
      !env.GOOGLE_SERVICE_ACCOUNT_EMAIL || !env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY) {
      throw new ApiError(503, 'policy_not_configured');
    }
    this.env = env; this.fetcher = fetcher; this.now = now;
    this.root = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;
  }
  async accessToken() {
    const cached = tokenCache.get(this.env);
    if (cached?.expiresAt > this.now() + 60000) return cached.token;
    const key = await importPKCS8(this.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY, 'RS256');
    const issued = Math.floor(this.now() / 1000);
    const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/identitytoolkit' })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' }).setIssuer(this.env.GOOGLE_SERVICE_ACCOUNT_EMAIL)
      .setSubject(this.env.GOOGLE_SERVICE_ACCOUNT_EMAIL).setAudience('https://oauth2.googleapis.com/token')
      .setIssuedAt(issued).setExpirationTime(issued + 3600).sign(key);
    const response = await this.fetcher('https://oauth2.googleapis.com/token', {
      method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
      signal: AbortSignal.timeout(DEADLINE_MS),
    });
    if (!response.ok) throw new ApiError(503, 'policy_unavailable');
    const data = await response.json();
    if (typeof data.access_token !== 'string' || !data.access_token || !Number.isFinite(data.expires_in)) {
      throw new ApiError(503, 'policy_unavailable');
    }
    tokenCache.set(this.env, { token: data.access_token, expiresAt: this.now() + data.expires_in * 1000 });
    return data.access_token;
  }
  async call(url, body) {
    const token = await this.accessToken();
    const response = await this.fetcher(url, {
      method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify(body), signal: AbortSignal.timeout(DEADLINE_MS),
    });
    if (!response.ok) {
      if (response.status === 409) throw Object.assign(new Error('transaction_conflict'), { retryable: true });
      throw new ApiError(503, 'policy_unavailable');
    }
    return response.json();
  }
  async assertIdentity(identity) {
    const data = await this.call(`https://identitytoolkit.googleapis.com/v1/projects/${this.env.FIREBASE_PROJECT_ID}/accounts:lookup`, {
      localId: [identity.uid],
    });
    const user = data.users?.find(u => u.localId === identity.uid);
    if (!user || user.disabled === true || user.emailVerified !== true || !Number.isInteger(identity.authTime) || identity.authTime < 0 ||
      typeof user.validSince !== 'string' || !/^\d+$/.test(user.validSince) ||
      !Number.isSafeInteger(Number(user.validSince)) || identity.authTime < Number(user.validSince)) {
      throw new ApiError(401, 'unauthorized');
    }
  }
  async transaction(paths, operation) {
    for (let attempt = 0; attempt < 5; attempt++) {
      const { transaction } = await this.call(`${this.root}:beginTransaction`, { options: { readWrite: {} } });
      if (typeof transaction !== 'string' || !transaction) throw new ApiError(503, 'policy_unavailable');
      try {
        const documents = paths.map(p => `${this.root.slice('https://firestore.googleapis.com/v1/'.length)}/${p}`);
        const rows = await this.call(`${this.root}:batchGet`, { documents, transaction });
        if (!Array.isArray(rows)) throw new ApiError(503, 'policy_unavailable');
        const records = new Map();
        for (const row of rows) {
          const name = row.found?.name ?? row.missing;
          const index = documents.indexOf(name);
          if (index >= 0) records.set(paths[index], row.found ? decodeFields(row.found.fields ?? {}) : null);
        }
        if (records.size !== paths.length) throw new ApiError(503, 'policy_unavailable');
        const result = operation(records);
        const writes = (result.writes ?? []).map(({ path, value }) => ({
          update: { name: `${this.root.slice('https://firestore.googleapis.com/v1/'.length)}/${path}`, fields: fields(value) },
        }));
        await this.call(`${this.root}:commit`, { transaction, writes });
        return result.value;
      } catch (error) {
        // Rollback is best effort. Never replace an application denial with a
        // transport failure, and never log the token or document payload.
        await this.call(`${this.root}:rollback`, { transaction }).catch(() => {});
        if (error.retryable && attempt < 4) continue;
        throw error;
      }
    }
    throw new ApiError(503, 'policy_unavailable');
  }
}
