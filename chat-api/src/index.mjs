import { verifyIdentity } from './auth.mjs';
import { ApiError, BODY_LIMIT, MODEL, ANSWER_MODEL, validateRequest, parsePlan, planMessages, answerMessages } from './protocol.mjs';

const headers = { 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' };
function json(value, status = 200) { return Response.json(value, { status, headers }); }
async function readBody(request) {
  if (!request.headers.get('content-type')?.startsWith('application/json')) throw new ApiError(415, 'json_required');
  const reader = request.body?.getReader();
  if (!reader) throw new ApiError(400, 'invalid_request');
  const chunks = []; let size = 0;
  try {
    while (true) {
      const { value, done } = await reader.read(); if (done) break;
      size += value.byteLength;
      if (size > BODY_LIMIT) { await reader.cancel(); throw new ApiError(413, 'request_too_large'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let at = 0;
  for (const chunk of chunks) { bytes.set(chunk, at); at += chunk.length; }
  try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { throw new ApiError(400, 'invalid_request'); }
}
// Dependency injection is for local tests, never selected by request/config.
export function createHandler(verify = verifyIdentity) {
  return async (request, env) => {
    try {
      if (new URL(request.url).pathname !== '/v1/chat') return json({ error: 'not_found' }, 404);
      if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
      if (!env.AI || !env.USER_LIMIT || !env.GLOBAL_LIMIT || !env.FIREBASE_PROJECT_ID ||
          !env.FIREBASE_PROJECT_NUMBER || !env.FIREBASE_ANDROID_APP_ID) throw new ApiError(503, 'not_configured');
      let uid;
      try { uid = await verify(request, env); } catch { throw new ApiError(401, 'unauthorized'); }
      const userLimit = await env.USER_LIMIT.limit({ key: uid });
      const globalLimit = await env.GLOBAL_LIMIT.limit({ key: 'chat' });
      if (!userLimit.success || !globalLimit.success) throw new ApiError(429, 'rate_limited');
      const r = validateRequest(await readBody(request));
      if (r.phase === 'plan') {
        const output = await env.AI.run(MODEL, {
          messages: planMessages(r), max_tokens: 700, temperature: 0,
          response_format: { type: 'json_object' },
        });
        return json(parsePlan(output, r.today));
      }
      const stream = await env.AI.run(ANSWER_MODEL, {
        messages: answerMessages(r), max_tokens: 1400, temperature: 0.2, stream: true,
      });
      if (!(stream instanceof ReadableStream)) throw new ApiError(502, 'invalid_model_response');
      return new Response(stream, { headers: { ...headers, 'content-type': 'text/event-stream; charset=utf-8' } });
    } catch (error) {
      if (error instanceof ApiError) return json({ error: error.code }, error.status);
      // No exception bodies, prompts, tokens, health context or provider debug logs.
      const quota = /quota|limit|429|neurons/i.test(String(error?.message ?? ''));
      return json({ error: quota ? 'quota_exceeded' : 'service_unavailable' }, quota ? 429 : 503);
    }
  };
}
export default { fetch: createHandler() };
