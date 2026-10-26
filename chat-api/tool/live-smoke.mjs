import { writeFile } from 'node:fs/promises';
import { cloudflareSession, accountRequest } from './cloudflare-session.mjs';
import { MODEL, planMessages, parsePlan } from '../src/protocol.mjs';
try {
  const session = cloudflareSession();
  const body = { version: 1, phase: 'plan', question: 'Đạm có vai trò gì trong bữa ăn?',
    history: [], today: '2026-10-25', selectedDate: '2026-10-25', timezoneOffsetMinutes: 420 };
  const started = Date.now();
  const response = await accountRequest(session, `/ai/run/${MODEL}`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: planMessages(body), max_tokens: 700,
      temperature: 0, response_format: { type: 'json_object' } }),
  });
  const data = await response.json();
  const report = { model: MODEL, status: response.status, elapsedMs: Date.now() - started,
    success: data.success, result: data.result,
    errors: data.errors?.map(e => ({ code: e.code, message: String(e.message).replaceAll(session.token, '[redacted]') })) };
  await writeFile(new URL('../../build/chat-api-live-smoke.json', import.meta.url), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report));
  if (response.ok && data.success) console.log(JSON.stringify({ parsedPlan: parsePlan(data.result, body.today) }));
  else process.exitCode = 1;
} catch (error) {
  console.error(error?.code ?? error?.message === 'Wrangler session unavailable; run wrangler login.' ? 'Cloudflare session unavailable.' : 'Live smoke did not complete; inspect the sanitized report.');
  process.exitCode = 1;
}
