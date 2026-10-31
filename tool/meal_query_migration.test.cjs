'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {planMigration, verifyInventory, validDateKey, applyEmulator} = require('./meal_query_migration.cjs');
const options = {legacyTimezoneOffsetMinutes: 420};
function apply(documents, plan) {
  return documents.map(doc => ({id: doc.id, data: {...doc.data, ...plan.patches.find(p => p.id === doc.id)?.patch}}));
}
test('dry-run inventories mixed old/current records, partitions without changing snapshots', () => {
  const fixture = [
    {id: 'old', data: {consumedAt: '2026-01-01T18:00:00.000Z', totalKcal: 500}},
    {id: 'new', data: {consumedAt: '2026-01-01T08:00:00.000Z', dateKey: '2026-01-01', totalKcal: 200}},
  ];
  const original = JSON.stringify(fixture);
  const plan = planMigration(fixture, options);
  assert.deepEqual(plan.counts, {documents: 2, current: 1, legacy: 1, invalid: 0, writes: 2});
  assert.equal(JSON.stringify(fixture), original);
  assert.deepEqual(plan.patches.find(p => p.id === 'old').patch, {queryPartition: 'legacy'});
  const partitioned = apply(fixture, plan);
  assert.equal(verifyInventory(partitioned, 'partitioned'), true);
  assert.equal(planMigration(partitioned, options).patches.length, 0);
  assert.equal(partitioned[0].data.totalKcal, 500);
});
test('complete backfills legacy with explicit offset, preserves existing local day and nutrition', () => {
  const fixture = [
    {id: 'legacy-vn', data: {consumedAt: '2026-01-01T18:00:00.000Z', queryPartition: 'legacy', totalKcal: 500}},
    {id: 'legacy-minus', data: {consumedAt: '2026-01-01T02:00:00.000Z', timezoneOffsetMinutes: -480}},
    {id: 'current', data: {consumedAt: '2026-01-01T18:00:00.000Z', dateKey: '2026-01-02', queryPartition: 'current'}},
  ];
  const complete = planMigration(fixture, {...options, targetState: 'complete'});
  const after = apply(fixture, complete);
  assert.equal(after[0].data.dateKey, '2026-01-02');
  assert.equal(after[1].data.dateKey, '2025-12-31');
  assert.equal(after[2].data.dateKey, '2026-01-02');
  assert.equal(after[0].data.totalKcal, 500);
  assert.equal(verifyInventory(after, 'complete'), true);
  assert.equal(planMigration(after, {...options, targetState: 'complete'}).patches.length, 0);
});
test('invalid dates/timestamps/offsets block verification instead of silently dropping records', () => {
  assert.equal(validDateKey('2026-02-29'), false);
  assert.equal(validDateKey('2024-02-29'), true);
  const fixture = [
    {id: 'bad-date', data: {consumedAt: '2026-01-01T00:00:00Z', dateKey: '2026-02-30'}},
    {id: 'bad-time', data: {consumedAt: 'broken'}},
    {id: 'bad-offset', data: {consumedAt: '2026-01-01T00:00:00Z', timezoneOffsetMinutes: 999}},
  ];
  const plan = planMigration(fixture, options);
  assert.equal(plan.blockers.length, 3);
  assert.equal(plan.patches.length, 0);
  assert.equal(verifyInventory(fixture, 'complete'), false);
  assert.throws(() => planMigration([], {}), /Explicit legacy timezone/);
});
test('resume re-enumerates inventory and is idempotent after a partial patch/checkpoint', () => {
  const fixture = Array.from({length: 205}, (_, n) => ({id: `meal-${String(n).padStart(3, '0')}`, data: {consumedAt: '2026-01-01T18:00:00Z'}}));
  const first = planMigration(fixture, {...options, targetState: 'complete'});
  const partial = apply(fixture, {...first, patches: first.patches.slice(0, 100)});
  const resumed = planMigration(partial, {...options, targetState: 'complete'});
  assert.equal(resumed.patches.length, 105);
  assert.equal(verifyInventory(partial, 'complete'), false);
  assert.equal(verifyInventory(apply(partial, resumed), 'complete'), true);
});
test('emulator apply fails closed without exact loopback opt-in, never falls back to production', async () => {
  const saved = process.env.FIRESTORE_EMULATOR_HOST;
  try {
    process.env.FIRESTORE_EMULATOR_HOST = 'cloud.example:8080';
    await assert.rejects(applyEmulator('fixture', {...options, targetState: 'complete'}), /explicit FIRESTORE_EMULATOR_HOST/);
  } finally {
    if (saved == null) delete process.env.FIRESTORE_EMULATOR_HOST;
    else process.env.FIRESTORE_EMULATOR_HOST = saved;
  }
});
