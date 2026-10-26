import { mkdir, writeFile } from 'node:fs/promises';
import { cloudflareSession, accountRequest } from './cloudflare-session.mjs';
import { MODEL, ANSWER_MODEL, planMessages, answerMessages, parsePlan } from '../src/protocol.mjs';
import { cases, resultFor } from './live-cases.mjs';
// QA CLI only: never makes the production Worker model caller-selectable.
const model = process.env.HEALTHMATE_BENCHMARK_MODEL ?? MODEL;
const answerModel = process.env.HEALTHMATE_BENCHMARK_ANSWER_MODEL ?? ANSWER_MODEL;
const report = { model, answerModel, runAt: new Date().toISOString(), synthetic: true, cases: [] };
async function consume(response, start) {
  let buffer = '', answer = '', firstTokenMs = null, completed = false, usage = null;
  const decoder = new TextDecoder();
  for await (const chunk of response.body) {
    buffer += decoder.decode(chunk, { stream: true });
    let at;
    while ((at = buffer.indexOf('\n\n')) >= 0) {
      const event = buffer.slice(0, at); buffer = buffer.slice(at + 2);
      const data = event.split('\n').filter(l => l.startsWith('data:')).map(l => l.slice(5).trim()).join('\n');
      if (!data) continue;
      if (data === '[DONE]') { completed = true; continue; }
      const value = JSON.parse(data);
      if (value.error) throw new Error('upstream_stream_error');
      usage = value.usage ?? usage;
      const choice = value.choices?.[0];
      if (choice?.finish_reason) {
        if (choice.finish_reason !== 'stop') throw new Error('incomplete_stream');
        completed = true;
      }
      const text = choice?.delta?.content ?? value.response;
      if (typeof text === 'string') {
        if (text.trim() && firstTokenMs == null) firstTokenMs = Date.now() - start;
        answer += text;
      }
    }
  }
  if (!completed) throw new Error('truncated_stream');
  return { answer, firstTokenMs, usage };
}
try {
  const session = cloudflareSession();
  const selected = process.argv.slice(2);
  for (const c of cases.filter(c => !selected.length || selected.includes(c.id))) {
    const r = { version: 1, phase: 'plan', question: c.question, history: c.history ?? [],
      today: '2026-10-25', selectedDate: '2026-10-25', timezoneOffsetMinutes: 420 };
    const started = Date.now();
    const row = { id: c.id, question: c.question, history: r.history };
    try {
      const response = await accountRequest(session, `/ai/run/${model}`, { method: 'POST',
        headers: { 'content-type': 'application/json' }, body: JSON.stringify({
          messages: planMessages(r), max_tokens: 700, temperature: 0, response_format: { type: 'json_object' },
        }) });
      const data = await response.json();
      if (!response.ok || !data.success) throw new Error(`plan_http_${response.status}_${data.errors?.[0]?.code ?? ''}`);
      row.planMs = Date.now() - started; row.planUsage = data.result?.usage;
      row.rawPlan = data.result?.choices?.[0]?.message?.content ?? data.result?.response;
      row.plan = parsePlan(data.result, r.today);
      row.expectedKinds = c.kinds;
      row.routingMatches = c.kinds.every(k => row.plan.requests.some(r => r.kind === k)) &&
        (c.kinds.length > 0 || row.plan.requests.length === 0);
      row.dayMatches = !c.day || row.plan.requests.every(r => r.startDate === c.day && r.endDate === (c.endDay ?? c.day));
      row.results = row.plan.requests.map(request => resultFor(request, c));
      const answerStarted = Date.now();
      const output = await accountRequest(session, `/ai/run/${answerModel}`, { method: 'POST',
        headers: { 'content-type': 'application/json' }, body: JSON.stringify({
          messages: answerMessages({ ...r, results: row.results }), max_tokens: 1400, temperature: 0.2, stream: true,
        }) });
      if (!output.ok) throw new Error(`answer_http_${output.status}`);
      Object.assign(row, await consume(output, answerStarted));
      row.elapsedMs = Date.now() - started;
    } catch (e) { row.error = String(e.message).replaceAll(session.token, '[redacted]').slice(0, 160); }
    report.cases.push(row);
    await mkdir(new URL('../../build', import.meta.url), { recursive: true });
    await writeFile(new URL('../../build/chat-api-live-benchmark.json', import.meta.url), JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ id: row.id, routing: row.routingMatches, dates: row.dayMatches,
      ms: row.elapsedMs, error: row.error }));
  }
} catch { console.error('Benchmark could not start; no credentials printed.'); process.exitCode = 1; }
