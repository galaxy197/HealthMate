import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const cli = fileURLToPath(new URL('../node_modules/wrangler/bin/wrangler.js', import.meta.url));
const cwd = fileURLToPath(new URL('..', import.meta.url));
function command(args) {
  try {
    return JSON.parse(execFileSync(process.execPath, [cli, ...args, '--json'], {
      cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 45000,
    }));
  } catch { throw new Error('Wrangler session unavailable; run wrangler login.'); }
}
// Deployment tooling only. OAuth credentials stay in memory, never logged/saved here.
export function cloudflareSession() {
  const info = command(['whoami']);
  const auth = command(['auth', 'token']);
  if (!info.loggedIn || info.accounts?.length !== 1 || typeof auth.token !== 'string') {
    throw new Error('Expected one explicitly selected Cloudflare account.');
  }
  return { accountId: info.accounts[0].id, token: auth.token };
}
export async function accountRequest(session, path, options = {}) {
  if (!path.startsWith('/') || path.includes('..')) throw new Error('Invalid account path.');
  return fetch(`https://api.cloudflare.com/client/v4/accounts/${session.accountId}${path}`, {
    ...options, signal: options.signal ?? AbortSignal.timeout(45000),
    headers: { ...options.headers, authorization: `Bearer ${session.token}` },
  });
}
