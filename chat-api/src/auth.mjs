import { createRemoteJWKSet, jwtVerify } from 'jose';

const authKeys = createRemoteJWKSet(new URL(
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
));
const appKeys = createRemoteJWKSet(new URL('https://firebaseappcheck.googleapis.com/v1/jwks'));

// Public signing keys only. No Admin SDK, service-account secret or Firestore access.
export async function verifyIdentity(request, env, keys = { authKeys, appKeys }) {
  const bearer = request.headers.get('authorization');
  const appToken = request.headers.get('x-firebase-appcheck');
  if (!bearer?.startsWith('Bearer ') || !appToken || bearer.length > 8192 || appToken.length > 8192) {
    throw new Error('unauthorized');
  }
  const now = Math.floor(Date.now() / 1000);
  const { payload: auth } = await jwtVerify(bearer.slice(7), keys.authKeys, {
    algorithms: ['RS256'], issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
    audience: env.FIREBASE_PROJECT_ID, requiredClaims: ['exp', 'iat', 'auth_time', 'sub'],
  });
  if (typeof auth.sub !== 'string' || !auth.sub || auth.sub.length > 128 ||
      auth.aud !== env.FIREBASE_PROJECT_ID || auth.email_verified !== true ||
      !Number.isInteger(auth.iat) || auth.iat < 0 || auth.iat > now ||
      !Number.isInteger(auth.auth_time) || auth.auth_time < 0 || auth.auth_time > auth.iat) throw new Error('unauthorized');
  const { payload: app, protectedHeader } = await jwtVerify(appToken, keys.appKeys, {
    algorithms: ['RS256'], issuer: `https://firebaseappcheck.googleapis.com/${env.FIREBASE_PROJECT_NUMBER}`,
    audience: `projects/${env.FIREBASE_PROJECT_NUMBER}`, requiredClaims: ['exp', 'iat', 'sub'],
  });
  if (protectedHeader.typ !== 'JWT' || app.sub !== env.FIREBASE_ANDROID_APP_ID ||
      !Array.isArray(app.aud) || !app.aud.includes(`projects/${env.FIREBASE_PROJECT_NUMBER}`) ||
      !Number.isFinite(app.iat) || app.iat > now) throw new Error('unauthorized');
  return auth.sub;
}
