import { cloudflareSession, accountRequest } from './cloudflare-session.mjs';
try {
  const session = cloudflareSession();
  console.log(JSON.stringify({ accountId: session.accountId }));
  for (const path of ['/workers/account-settings', '/subscriptions', '/workers/scripts', '/workers/subdomain']) {
    const response = await accountRequest(session, path);
    const data = await response.json();
    let result;
    if (path === '/subscriptions') result = data.result?.map(s => ({ id: s.rate_plan?.id, name: s.rate_plan?.public_name }));
    else if (path === '/workers/scripts') result = data.result?.map(s => ({ id: s.id }));
    else result = data.result;
    console.log(JSON.stringify({ path, status: response.status, success: data.success,
      result, codes: data.errors?.map(e => e.code) }));
  }
} catch { console.error('Account inspection failed; no credentials were printed.'); process.exitCode = 1; }
