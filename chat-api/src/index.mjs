import { verifyIdentityClaims } from './auth.mjs';
import { createTrustedPolicy, REQUEST_ID } from './ai-policy.mjs';
import { ApiError, BODY_LIMIT, MODEL, ANSWER_MODEL, validateRequest, parsePlan, planMessages, answerMessages } from './protocol.mjs';

const headers = { 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' };
function json(value, status = 200) { return Response.json(value, { status, headers }); }
async function readBody(request) {
  if (!request.headers.get('content-type')?.startsWith('application/json')) throw new ApiError(415, 'json_required');
  const reader = request.body?.getReader();
  if (!reader) throw new ApiError(400, 'invalid_request');
  const chunks = []; let size = 0;
  const deadline = Date.now() + 8000;
  try {
    while (true) {
      const { value, done } = await waitBounded(reader.read(), Math.max(1, deadline - Date.now()), request.signal, 'request_timeout'); if (done) break;
      size += value.byteLength;
      if (size > BODY_LIMIT) { await reader.cancel(); throw new ApiError(413, 'request_too_large'); }
      chunks.push(value);
    }
  } catch (error) { await reader.cancel().catch(() => {}); throw error; }
  finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let at = 0;
  for (const chunk of chunks) { bytes.set(chunk, at); at += chunk.length; }
  try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { throw new ApiError(400, 'invalid_request'); }
}
const MODEL_TIMEOUT_MS = 40000;
const OUTPUT_BYTES = 64000;
function waitBounded(promise, milliseconds, signal, timeoutCode = 'model_timeout') {
  let timer, abort;
  const stopped = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new ApiError(504, timeoutCode)), milliseconds);
    abort = () => reject(new ApiError(499, 'request_cancelled'));
    if (signal?.aborted) abort(); else signal?.addEventListener('abort', abort, { once: true });
  });
  return Promise.race([promise, stopped]).finally(() => { clearTimeout(timer); signal?.removeEventListener('abort', abort); });
}
function modelFailure(error) {
  if (error instanceof ApiError) return error;
  const quota = /quota|limit|429|neurons/i.test(String(error?.message ?? ''));
  return new ApiError(quota ? 429 : 503, quota ? 'quota_exceeded' : 'service_unavailable');
}
// Dependency injection is local-test code only; request/config cannot select it.
export function createHandler(verify = verifyIdentityClaims, { policyFactory = createTrustedPolicy, modelTimeoutMs = MODEL_TIMEOUT_MS } = {}) {
  return async (request, env) => {
    let policy, identity, id, reservation, phase, claimed = false;
    try {
      if (new URL(request.url).pathname !== '/v1/chat') return json({ error: 'not_found' }, 404);
      if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
      if (!env.AI || !env.USER_LIMIT || !env.GLOBAL_LIMIT || !env.FIREBASE_PROJECT_ID ||
          !env.FIREBASE_PROJECT_NUMBER || !env.FIREBASE_ANDROID_APP_ID) throw new ApiError(503, 'not_configured');
      try {
        const verified = await verify(request, env);
        identity = typeof verified === 'string' ? { uid: verified, authTime: 0 } : verified;
      } catch { throw new ApiError(401, 'unauthorized'); }
      const uid = identity.uid;
      const userLimit = await env.USER_LIMIT.limit({ key: uid });
      const globalLimit = await env.GLOBAL_LIMIT.limit({ key: 'chat' });
      if (!userLimit.success || !globalLimit.success) throw new ApiError(429, 'rate_limited');
      const r = validateRequest(await readBody(request));
      phase = r.phase;
      id = request.headers.get('x-healthmate-request-id');
      if (!REQUEST_ID.test(id ?? '')) throw new ApiError(400, 'request_id_required');
      if (request.signal.aborted) throw new ApiError(499, 'request_cancelled');
      policy = policyFactory(env);
      await policy.authorize(identity);
      reservation = await policy.reserve(uid, id);
      // Recheck Auth after network/transaction waits, then atomically check
      // Firestore policy again when claiming this one model invocation.
      await policy.authorize(identity);
      await policy.claim(uid, id, phase, reservation.dayKey);
      claimed = true;
      if (request.signal.aborted) throw new ApiError(499, 'request_cancelled');
      if (r.phase === 'plan') {
        const output = await waitBounded(env.AI.run(MODEL, {
          messages: planMessages(r), max_tokens: 700, temperature: 0,
          response_format: { type: 'json_object' },
        }), modelTimeoutMs, request.signal);
        const result = parsePlan(output, r.today);
        await policy.finish(uid, id, phase, reservation.dayKey, 'completed');
        claimed = false;
        return json(result);
      }
      const stream = await waitBounded(env.AI.run(ANSWER_MODEL, {
        messages: answerMessages(r), max_tokens: 1400, temperature: 0.2, stream: true,
      }), modelTimeoutMs, request.signal);
      if (!(stream instanceof ReadableStream)) throw new ApiError(502, 'invalid_model_response');
      const reader = stream.getReader();
      const deadline = Date.now() + modelTimeoutMs;
      let settled = false, bytes = 0, tail = '', complete = false;
      const decoder = new TextDecoder();
      const settle = async outcome => {
        if (settled) return;
        settled = true;
        await policy.finish(uid, id, phase, reservation.dayKey, outcome);
      };
      const safeStream = new ReadableStream({
        async pull(controller) {
          try {
            const next = await waitBounded(reader.read(), Math.max(1, deadline - Date.now()), request.signal);
            if (settled) return;
            if (next.done) {
              if (!complete) throw new ApiError(502, 'incomplete_response');
              await settle('completed'); controller.close(); return;
            }
            bytes += next.value.byteLength;
            if (bytes > OUTPUT_BYTES) throw new ApiError(502, 'response_too_large');
            tail = (tail + decoder.decode(next.value, { stream: true })).slice(-100);
            if (/(?:^|\n)data:\s*\[DONE\]\s*(?:\r?\n|$)/.test(tail)) complete = true;
            controller.enqueue(next.value);
          } catch {
            await reader.cancel().catch(() => {});
            await settle('unknown').catch(() => {});
            controller.error(new Error('stream_incomplete'));
          }
        },
        async cancel() {
          await reader.cancel().catch(() => {});
          await settle('unknown').catch(() => {});
        },
      });
      claimed = false; // Stream owns finalization from this point.
      return new Response(safeStream, { headers: { ...headers, 'content-type': 'text/event-stream; charset=utf-8' } });
    } catch (error) {
      const failure = modelFailure(error);
      if (claimed) {
        const outcome = failure.status === 429 || failure.code === 'invalid_model_response' ? 'failed' : 'unknown';
        await policy.finish(identity.uid, id, phase, reservation.dayKey, outcome).catch(() => {});
      }
      // No exception bodies, prompts, tokens, health context or provider debug logs.
      return json({ error: failure.code }, failure.status);
    }
  };
}
export default { fetch: createHandler() };
