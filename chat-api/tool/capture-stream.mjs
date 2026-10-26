import { writeFile } from 'node:fs/promises';
import { cloudflareSession, accountRequest } from './cloudflare-session.mjs';
import { ANSWER_MODEL, answerMessages } from '../src/protocol.mjs';
// Public synthetic question only; no Firebase, identity tokens or journal data.
try {
  const session = cloudflareSession();
  const r = { question: 'Protein có vai trò gì trong bữa ăn?', history: [],
    today: '2026-10-25', selectedDate: '2026-10-25', timezoneOffsetMinutes: 420, results: [] };
  const response = await accountRequest(session, `/ai/run/${ANSWER_MODEL}`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: answerMessages(r), max_tokens: 1400, temperature: 0.2, stream: true }),
  });
  if (!response.ok) throw new Error('HTTP failure');
  const sse = await response.text();
  await writeFile(new URL('../../build/chat-api-live-stream.sse', import.meta.url), sse);
  const events = sse.split('\n\n').filter(x => x.startsWith('data:'));
  console.log(JSON.stringify({ bytes: Buffer.byteLength(sse), events: events.length, firstEvent: events[0], lastEvent: events.at(-1) }));
} catch { console.error('Synthetic stream capture failed; no credentials printed.'); process.exitCode = 1; }
