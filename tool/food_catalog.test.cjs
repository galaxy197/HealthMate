const {test} = require('node:test');
const assert = require('node:assert/strict');
const {buildCatalog, validateFood, planAdditions, createWrites} = require('./import_food_catalog.cjs');
const catalog = buildCatalog();
const find = id => catalog.find(food => food.id === id);

test('Vietnamese expansion has complete sources, finite macros, estimates and distinct names/IDs', () => {
  assert.equal(catalog.length, 148);
  assert.equal(new Set(catalog.map(food => food.id)).size, catalog.length);
  assert.equal(new Set(catalog.map(food => food.name)).size, catalog.length);
  assert.equal(catalog.filter(food => food.sourceDetails.method === 'reference_table').length, 101);
  assert.equal(catalog.filter(food => food.sourceDetails.method === 'recipe_estimate').length, 47);
  for (const food of catalog) {
    assert.equal(validateFood(food), food);
    assert.match(food.sourceUrl, /^https:\/\/www\.fao\.org\//);
    assert.ok(food.sourceLabel.includes('Ước tính'));
    if (food.sourceDetails.method === 'reference_table') {
      assert.ok(food.sourceDetails.pdfPage >= 14 && food.sourceDetails.pdfPage <= 567);
      assert.match(food.sourceDetails.foodCode, /^\d+$/);
    } else {
      assert.ok(food.sourceDetails.yieldGrams > 0);
      assert.ok(food.sourceDetails.ingredients.length > 0);
      assert.match(food.sourceDetails.note, /không phải kết quả phân tích/);
    }
  }
});

test('reference food state is explicit and bread/pho nutrients match their cited rows', () => {
  const noodles = find('vn2007-1013');
  assert.deepEqual([noodles.kcalPer100g, noodles.proteinGPer100g, noodles.carbsGPer100g, noodles.fatGPer100g], [143, 3.2, 31.7, 0.4]);
  assert.equal(noodles.sourceDetails.pdfPage, 26);
  assert.equal(find('vn2007-1012').kcalPer100g, 249);
  assert.match(find('vn2007-7017').name, /sống/);
  assert.match(find('vn2007-8022').name, /Cá lóc/);
  assert.equal(find('vn2007-8022').sourceDetails.pdfPage, 410);
});

test('pho recipe uses all ingredient energy and finished weight, not 100g as one bowl', () => {
  const pho = find('vn-pho-bo');
  const bowlKcal = 143 * 2 + 118 * .9 + 41 * .25 + 44 * .3 + 897 * .05 + 390 * .04;
  assert.ok(Math.abs(pho.kcalPer100g * 6 - bowlKcal) < .04);
  assert.equal(pho.sourceDetails.yieldGrams, 600);
  assert.equal(pho.kcalPer100g, 79.35);
  // The NIN bun row has a missing fat value: estimate from flour/yield instead.
  assert.equal(find('vn2007-1020'), undefined);
  assert.equal(find('vn-bun-tuoi').sourceDetails.method, 'recipe_estimate');
  assert.ok(find('vn-bun-tuoi').fatGPer100g > 0);
});

test('recipes can use another recipe and normalize final cooked yield once', () => {
  const fried = find('vn-com-chien-trung');
  const energy = (344 / 270 * 280 + 166 * .6 + 39 * .35 + 41 * .2 + 897 * .12) / 4;
  assert.ok(Math.abs(fried.kcalPer100g - energy) < .01);
  assert.equal(find('vn-rice-base'), undefined); // Internal base is not a duplicate catalog rice.
});

test('import is additive/idempotent and detects matching normalized names with another id', () => {
  const existing = catalog.map(food => ({name: `projects/demo-test/databases/(default)/documents/food_catalog/${food.id}`, fields: {name: {stringValue: food.name}}}));
  assert.equal(planAdditions(catalog, existing).additions.length, 0);
  assert.equal(planAdditions(catalog, existing).skipped, 148);
  const renamedId = [{name: 'food_catalog/legacy-pho', fields: {name: {stringValue: 'PHO BO'}}}];
  const plan = planAdditions(catalog, renamedId);
  assert.equal(plan.skipped, 1);
  assert.ok(!plan.additions.some(food => food.id === 'vn-pho-bo'));
});

test('every write is a catalog create with a server timestamp, never user-data mutation', () => {
  const writes = createWrites('demo-healthmate-rules', catalog);
  for (const write of writes) {
    assert.match(write.update.name, /^projects\/demo-healthmate-rules\/databases\/\(default\)\/documents\/food_catalog\/[a-z0-9-]+$/);
    assert.deepEqual(write.currentDocument, {exists: false});
    assert.deepEqual(write.updateTransforms, [{fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'}]);
    assert.equal(write.update.fields.isEstimated.booleanValue, true);
    assert.equal(write.update.fields.servingBasis.stringValue, 'per_100g');
  }
  assert.throws(() => createWrites('bad/project', catalog));
  assert.throws(() => createWrites('demo-healthmate-rules', [{...catalog[0], id: '../users/uid'}]));
});

test('import rejects non-finite, missing, impossible or misleading nutrition metadata', () => {
  for (const replacement of [NaN, Infinity, -1, 1001]) assert.throws(() => validateFood({...catalog[0], kcalPer100g: replacement}));
  assert.throws(() => validateFood({...catalog[0], fatGPer100g: undefined}));
  assert.throws(() => validateFood({...catalog[0], proteinGPer100g: 90, fatGPer100g: 30}));
  assert.throws(() => validateFood({...catalog[0], servingBasis: 'per_bowl'}));
  assert.throws(() => validateFood({...catalog[0], isEstimated: false}));
});
