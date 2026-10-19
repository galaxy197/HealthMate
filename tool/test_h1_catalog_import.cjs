'use strict';
// Only ever execute under emulators:exec. No CLI login/production fallback.
const assert = require('node:assert/strict');
const {buildCatalog, createWrites, planCatalogChanges} = require('./import_food_catalog.cjs');
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (host !== '127.0.0.1:8080') throw Error('Requires the explicit localhost Firestore emulator.');
const base = `http://${host}/v1/projects/demo-healthmate-rules/databases/(default)/documents`;
const request = async (url, body) => {
  const r = await fetch(url, {method: body ? 'POST':'GET', headers: {'Authorization':'Bearer owner','Content-Type':'application/json'}, body: body ? JSON.stringify(body):undefined});
  assert.equal(r.status, 200); return r.json();
};
(async () => {
  // Prefix only the fixture names so a catalog entry left by the independent
  // Rules suite cannot conflict by normalized name. No database reset needed.
  const catalog = buildCatalog().map(food => ({...food, name: `QA H1 ${food.name}`}));
  const read = async () => {
    const documents = [];
    let page;
    do {
      const query = new URLSearchParams({pageSize:'300'});
      if (page) query.set('pageToken', page);
      const response = await request(`${base}/food_catalog?${query}`);
      documents.push(...(response.documents || []));
      page = response.nextPageToken;
    } while (page);
    return documents;
  };
  const before = await read();
  const plan = planCatalogChanges(catalog, before);
  if (plan.creates.length) await request(`${base}:commit`, {writes: createWrites('demo-healthmate-rules', plan.creates)});
  const after = await read();
  const retry = planCatalogChanges(catalog, after);
  console.log(JSON.stringify({created:plan.creates.length, retryCreates:retry.creates.map(f=>f.id), retryUpdates:retry.updates, retryConflicts:retry.conflicts, retrySkips:retry.skips.length}));
  assert.equal(retry.creates.length, 0);
  assert.equal(retry.updates.length, 0);
  assert.equal(retry.conflicts.length, 0, JSON.stringify(retry.conflicts));
  assert.equal(retry.skips.length, catalog.length);
  const pho = after.find(d => d.name.endsWith('/vn-pho-bo'));
  assert.equal(pho.fields.servingGrams.doubleValue, 600);
  console.log(`H1 emulator import: ${plan.creates.length} creates; retry 0 creates/updates/conflicts; ${retry.skips.length} skips; no users writes.`);
})().catch(e => { console.error(e.stack); process.exitCode=1; });
