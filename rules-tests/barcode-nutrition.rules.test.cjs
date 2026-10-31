const fs = require('node:fs');
const path = require('node:path');
const { before, after, beforeEach, test } = require('node:test');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, serverTimestamp, Timestamp } = require('firebase/firestore');
const assert = require('node:assert/strict');
let env;
before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({ projectId: 'demo-healthmate-barcode',
    firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') } });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());
const db = () => env.authenticatedContext('alice', { email_verified: true }).firestore();
const item = (patch = {}) => ({ foodId: 'barcode_123', name: 'Label fixture', grams: 100,
  kcal: 100, proteinG: 10, carbsG: 10, fatG: 2, sourceLabel: 'Fixture', isEstimated: true, ...patch });
const meal = (i, version = 2) => ({ mealType: 'lunch', consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01', timezoneOffsetMinutes: 420, items: [i], totalKcal: i.kcal,
  totalProteinG: i.proteinG, totalCarbsG: i.carbsG, totalFatG: i.fatG, source: 'manual',
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), schemaVersion: version });
const compact = i => { const { grams, ...rest } = i; return { ...rest, quantity: grams, quantityUnit: 'g' }; };

test('gram snapshots reject impossible macro, fiber and kcal in every meal schema', async () => {
  const a = db();
  for (const version of [2, 3, 4, 5]) {
    for (const patch of [{ proteinG: 500 }, { carbsG: 500 }, { fatG: 500 }, { fiberG: 500 }, { kcal: 1100 }]) {
      let i = item(patch);
      if (version === 3) i[Object.hasOwn(patch, 'carbsG') ? 'proteinG' : 'carbsG'] = null;
      if (version === 5) i = { ...compact(i), nutrientVectorV1: '[null,null,null,null,null,null,null,null]' };
      await assertFails(setDoc(doc(a, `users/alice/meal_logs/bad-${version}`), meal(i, version)));
    }
  }
});

test('mass bounds scale with grams; partial, ml, servings and quick-add remain valid', async () => {
  const a = db();
  const fixtures = [
    [item({ grams: 500, kcal: 1500, proteinG: 150 }), 2],
    [item({ proteinG: null, carbsG: null, fatG: null }), 3],
    [item({ grams: null, quantity: 100, quantityUnit: 'ml', proteinG: 110, kcal: 500 }), 3],
    [item({ grams: null, quantity: 1, quantityUnit: 'serving', proteinG: 110, kcal: 500 }), 3],
    [item({ grams: null, quantity: 1, quantityUnit: 'entry', proteinG: null, carbsG: null, fatG: null, kcal: 250 }), 3],
    [item({ carbsG: 90, fiberG: 30 }), 4],
  ];
  for (let n = 0; n < fixtures.length; n++) {
    await assertSucceeds(setDoc(doc(a, `users/alice/meal_logs/valid-${n}`), meal(...fixtures[n])));
  }
});

test('custom per-100-g foods, recipe ingredients and saved meal templates cannot bypass mass bounds', async () => {
  const a = db();
  const bad = item({ proteinG: 500 });
  const stamps = { createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
  await assertFails(setDoc(doc(a, 'users/alice/custom_foods/bad'), { name: 'Invalid fixture', alternateNames: [],
    servingBasis: 'per_100g', kcalPer100g: 100, proteinGPer100g: 500, carbsGPer100g: 0, fatGPer100g: 0,
    defaultServingGrams: 100, servingLabel: null, servingGrams: null, sourceLabel: 'Fixture', isEstimated: true,
    schemaVersion: 1, ...stamps }));
  await assertFails(setDoc(doc(a, 'users/alice/recipes/bad'), { name: 'Invalid recipe', ingredients: [bad],
    yieldGrams: 100, servingsCount: 1, sourceLabel: 'Fixture', isEstimated: true, schemaVersion: 1, ...stamps }));
  for (const version of [1, 2, 3, 4]) {
    const data = { name: 'Invalid template', items: [version < 3 ? bad : compact(bad)], schemaVersion: version, ...stamps };
    if (version >= 3) data.fiberValues = [null];
    if (version === 4) data.nutrientVectorsV1 = '[null,null,null,null,null,null,null,null]';
    await assertFails(setDoc(doc(a, `users/alice/meal_templates/bad-${version}`), data));
  }
  for (const version of [3, 4]) {
    const data = { name: 'Invalid fiber', items: [compact(item())], fiberValues: [101], schemaVersion: version, ...stamps };
    if (version === 4) data.nutrientVectorsV1 = '[null,null,null,null,null,null,null,null]';
    await assertFails(setDoc(doc(a, `users/alice/meal_templates/fiber-${version}`), data));
    await assertSucceeds(setDoc(doc(a, `users/alice/meal_templates/valid-${version}`), { ...data, fiberValues: [0] }));
  }
});

test('legacy snapshots remain readable and unchanged; invalid rewrite is rejected', async () => {
  const original = meal(item({ proteinG: 500 }));
  await env.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), 'users/alice/meal_logs/legacy'), original));
  const ref = doc(db(), 'users/alice/meal_logs/legacy');
  const stored = await assertSucceeds(getDoc(ref));
  assert.equal(stored.data().items[0].proteinG, 500);
  await assertFails(updateDoc(ref, { updatedAt: serverTimestamp() }));
  assert.equal((await getDoc(ref)).data().items[0].proteinG, 500);
});
