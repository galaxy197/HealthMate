'use strict';
// Privileged migration preparation. No cloud apply route or credential support.
const fs = require('node:fs');
const {createHash} = require('node:crypto');
const PROJECT = 'demo-healthmate-rules';
const HOST = '127.0.0.1:8080';
const ROOT = `http://${HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;

function validDateKey(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) || Number(value.slice(0, 4)) < 1) return false;
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0, 10) === value;
}
function validOffset(value) { return Number.isInteger(value) && value >= -720 && value <= 840; }
function planMigration(documents, {targetState = 'partitioned', legacyTimezoneOffsetMinutes} = {}) {
  if (!['partitioned', 'complete'].includes(targetState)) throw Error('Unknown target state');
  if (!validOffset(legacyTimezoneOffsetMinutes)) throw Error('Explicit legacy timezone offset is required (-720..840)');
  const counts = {documents: documents.length, current: 0, legacy: 0, invalid: 0, writes: 0};
  const patches = [], blockers = [];
  const ids = new Set();
  for (const doc of [...documents].sort((a, b) => a.id.localeCompare(b.id))) {
    if (typeof doc.id !== 'string' || !doc.id || doc.id.includes('/') || ids.has(doc.id)) throw Error('Unique document IDs required');
    ids.add(doc.id);
    const data = doc.data;
    const consumedAt = typeof data?.consumedAt === 'string' ? new Date(data.consumedAt) : null;
    if (!consumedAt || Number.isNaN(consumedAt.valueOf()) || !validDateKey(data.consumedAt.slice(0, 10)) ||
        (data.dateKey != null && !validDateKey(data.dateKey)) ||
        (data.timezoneOffsetMinutes != null && !validOffset(data.timezoneOffsetMinutes))) {
      counts.invalid++;
      blockers.push({id: doc.id, code: 'invalid_date_or_offset'});
      continue;
    }
    const current = validDateKey(data.dateKey);
    counts[current ? 'current' : 'legacy']++;
    const patch = {};
    if (targetState === 'complete' && !current) {
      const offset = data.timezoneOffsetMinutes ?? legacyTimezoneOffsetMinutes;
      patch.dateKey = new Date(consumedAt.valueOf() + offset * 60000).toISOString().slice(0, 10);
      patch.timezoneOffsetMinutes = offset;
    }
    const route = current || targetState === 'complete' ? 'current' : 'legacy';
    if (data.queryPartition !== route) patch.queryPartition = route;
    if (Object.keys(patch).length) patches.push({id: doc.id, patch});
  }
  counts.writes = patches.length;
  const inventoryHash = createHash('sha256').update(JSON.stringify(documents.map(d => ({id: d.id, data: d.data})).sort((a,b)=>a.id.localeCompare(b.id)))).digest('hex');
  return {schemaVersion: 1, targetState, legacyTimezoneOffsetMinutes, counts, blockers, patches, inventoryHash};
}
function verifyInventory(documents, targetState) {
  return documents.every(doc => targetState === 'complete'
    ? validDateKey(doc.data.dateKey) && doc.data.queryPartition === 'current'
    : doc.data.queryPartition === (validDateKey(doc.data.dateKey) ? 'current' : 'legacy'));
}
function wire(value) {
  if (value === null) return {nullValue: null};
  if (typeof value === 'string') return {stringValue: value};
  if (typeof value === 'number' && Number.isInteger(value)) return {integerValue: String(value)};
  throw Error('Unsupported metadata value');
}
function decode(fields) {
  return Object.fromEntries(Object.entries(fields ?? {}).map(([key, value]) => [key,
    value.timestampValue ?? value.stringValue ?? (value.integerValue != null ? Number(value.integerValue) : null)]));
}
async function emulatorRequest(path, {method = 'GET', body} = {}) {
  if (process.env.FIRESTORE_EMULATOR_HOST !== HOST) throw Error('Requires explicit FIRESTORE_EMULATOR_HOST=127.0.0.1:8080');
  const response = await fetch(`${ROOT}${path.startsWith(':') ? '' : '/'}${path}`, {method, headers: {Authorization: 'Bearer owner', 'Content-Type': 'application/json'}, body: body ? JSON.stringify(body) : undefined});
  if (response.status === 404 && method === 'GET') return null;
  if (!response.ok) throw Error(`Local demo request failed: ${response.status}`);
  return response.json();
}
async function inventory(uid) {
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(uid ?? '')) throw Error('Explicit safe UID required');
  const docs = []; let pageToken;
  do {
    // ListDocuments defaults to document-name order. The local emulator does
    // not support combining an explicit orderBy with its returned pageToken.
    const query = new URLSearchParams({pageSize: '100'});
    if (pageToken) query.set('pageToken', pageToken);
    const page = await emulatorRequest(`users/${uid}/meal_logs?${query}`);
    for (const doc of page?.documents ?? []) docs.push({id: doc.name.split('/').at(-1), data: decode(doc.fields)});
    pageToken = page?.nextPageToken;
  } while (pageToken);
  return docs;
}
async function checkNotDeleting(uid) {
  if (await emulatorRequest(`account_deletions/${uid}`)) throw Error('Account deletion is pending; do not migrate');
}
async function marker(uid, fields) {
  const encoded = Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, wire(value)]));
  encoded.updatedAt = {timestampValue: new Date().toISOString()};
  if (fields.state !== 'migrating') encoded.verifiedAt = {timestampValue: new Date().toISOString()};
  return emulatorRequest(`users/${uid}/data_migrations/meal_date_key_v1`, {method: 'PATCH', body: {fields: encoded}});
}
async function applyEmulator(uid, options) {
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(uid)) throw Error('Explicit safe UID required');
  await checkNotDeleting(uid);
  const previous = await emulatorRequest(`users/${uid}/data_migrations/meal_date_key_v1`);
  if (previous?.fields?.state?.stringValue === 'complete' && options.targetState !== 'complete') {
    throw Error('A completed migration must not be downgraded');
  }
  const initial = planMigration(await inventory(uid), options);
  if (initial.blockers.length) throw Error(`Inventory has ${initial.blockers.length} invalid records; resolve before locking`);
  // A fresh lock and full re-enumeration on every resume; a stale checkpoint is
  // only diagnostic, never proof allowing records to be skipped.
  await marker(uid, {schemaVersion: 1, state: 'migrating', targetState: options.targetState,
    checkpoint: null, legacyTimezoneOffsetMinutes: options.legacyTimezoneOffsetMinutes});
  const plan = planMigration(await inventory(uid), options);
  if (plan.blockers.length) throw Error('Inventory changed to invalid data after lock; remains locked for review');
  let written = 0;
  for (let at = 0; at < plan.patches.length; at += 100) {
    await checkNotDeleting(uid);
    const slice = plan.patches.slice(at, at + 100);
    const writes = slice.map(item => ({update: {
      name: `projects/${PROJECT}/databases/(default)/documents/users/${uid}/meal_logs/${item.id}`,
      fields: Object.fromEntries(Object.entries(item.patch).map(([key, value]) => [key, wire(value)])),
    }, updateMask: {fieldPaths: Object.keys(item.patch)}, currentDocument: {exists: true}}));
    // Fixed localhost/demo endpoint. No writes to health snapshots/timestamps.
    await emulatorRequest(':commit', {method: 'POST', body: {writes}});
    written += slice.length;
    await marker(uid, {schemaVersion: 1, state: 'migrating', targetState: options.targetState,
      checkpoint: slice.at(-1).id, legacyTimezoneOffsetMinutes: options.legacyTimezoneOffsetMinutes});
  }
  await checkNotDeleting(uid);
  const after = await inventory(uid);
  if (!verifyInventory(after, options.targetState) || after.length !== plan.counts.documents) throw Error('Final full inventory verification failed; marker remains migrating');
  await marker(uid, {schemaVersion: 1, state: options.targetState, targetState: options.targetState,
    checkpoint: after.at(-1)?.id ?? null, legacyTimezoneOffsetMinutes: options.legacyTimezoneOffsetMinutes});
  return {mode: 'local-demo-apply', project: PROJECT, uid, written, verifiedDocuments: after.length, state: options.targetState};
}
async function main(args) {
  const option = key => {const at = args.indexOf(key); return at < 0 ? undefined : args[at+1];};
  const options = {targetState: option('--target') ?? 'partitioned', legacyTimezoneOffsetMinutes: Number(option('--legacy-offset-minutes'))};
  const uid = option('--uid');
  if (args.includes('--apply-emulator')) {
    if (args.includes('--fixture')) throw Error('Apply never consumes an unchecked fixture');
    console.log(JSON.stringify(await applyEmulator(uid, options)));
  } else {
    const fixture = option('--fixture');
    const docs = fixture ? JSON.parse(fs.readFileSync(fixture, 'utf8')) : await inventory(uid);
    console.log(JSON.stringify({mode: 'dry-run', ...planMigration(docs, options)}, null, 2));
  }
}
module.exports = {validDateKey, planMigration, verifyInventory, applyEmulator};
if (require.main === module) main(process.argv.slice(2)).catch(error => {console.error(error.message); process.exitCode = 1;});
