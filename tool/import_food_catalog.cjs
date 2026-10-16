// Admin-only catalog maintenance using the existing Firebase CLI login.
// Dry run by default; no service-account files, app client write access or deps.
const fs = require('node:fs');
const path = require('node:path');
const {execSync} = require('node:child_process');

const root = path.resolve(__dirname, '..');
const source = JSON.parse(fs.readFileSync(path.join(root, 'data/food_catalog/ingredients.json'), 'utf8'));
const recipes = JSON.parse(fs.readFileSync(path.join(root, 'data/food_catalog/recipes.json'), 'utf8'));
const normalize = text => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
  .toLowerCase().replace(/đ/g, 'd').trim().replace(/\s+/g, ' ');
const metrics = ['kcal', 'proteinG', 'carbsG', 'fatG'];

function validateFood(food) {
  if (!/^[a-z0-9-]{1,100}$/.test(food.id) || typeof food.name !== 'string' || !food.name.trim() || food.name.length > 100) {
    throw Error('Invalid catalog id/name.');
  }
  if (!Array.isArray(food.alternateNames) || food.alternateNames.some(name => typeof name !== 'string' || !name.trim() || name.length > 100)) {
    throw Error(`Invalid aliases: ${food.id}`);
  }
  if (!food.category || food.servingBasis !== 'per_100g' || food.unit !== 'g' || food.isEstimated !== true || !food.sourceLabel || food.sourceLabel.length > 160) {
    throw Error(`Invalid units/source/estimate label: ${food.id}`);
  }
  for (const field of ['kcalPer100g', 'proteinGPer100g', 'carbsGPer100g', 'fatGPer100g']) {
    const value = food[field];
    if (!Number.isFinite(value) || value < 0 || value > (field === 'kcalPer100g' ? 1000 : 100)) {
      throw Error(`Invalid nutrition ${field}: ${food.id}`);
    }
  }
  if (food.proteinGPer100g + food.carbsGPer100g + food.fatGPer100g > 101) throw Error(`Macros exceed mass: ${food.id}`);
  return food;
}

function buildCatalog() {
  const definitions = new Map();
  for (const item of [...source.foods, ...recipes.recipes]) {
    if (definitions.has(item.id)) throw Error(`Duplicate id: ${item.id}`);
    definitions.set(item.id, item);
  }
  const memo = new Map();
  const inProgress = new Set();
  const evaluate = id => {
    const key = /^\d+$/.test(id) ? `vn2007-${id}` : id;
    if (memo.has(key)) return memo.get(key);
    const item = definitions.get(key);
    if (!item) throw Error(`Unknown ingredient: ${id}`);
    if (inProgress.has(key)) throw Error(`Recipe cycle: ${id}`);
    inProgress.add(key);
    let per100g = item.per100g;
    if (per100g) {
      if (!Number.isInteger(item.sourcePdfPage) || !/^\d+$/.test(item.sourceFoodCode)) throw Error(`Missing source: ${key}`);
    } else {
      if (!Number.isFinite(item.yieldGrams) || item.yieldGrams <= 0 || !item.ingredients?.length) throw Error(`Invalid recipe yield: ${key}`);
      per100g = Object.fromEntries(metrics.map(metric => [metric, 0]));
      for (const [ingredient, grams] of item.ingredients) {
        if (!Number.isFinite(grams) || grams <= 0) throw Error(`Invalid ingredient mass: ${key}`);
        const reference = evaluate(ingredient);
        for (const metric of metrics) per100g[metric] += reference[metric] * grams / item.yieldGrams;
      }
    }
    for (const metric of metrics) {
      if (!Number.isFinite(per100g[metric]) || per100g[metric] < 0) throw Error(`Missing/invalid nutrient: ${key}`);
    }
    inProgress.delete(key);
    memo.set(key, per100g);
    return per100g;
  };
  const names = new Set();
  return [...definitions.values()].filter(item => item.publish !== false).map(item => {
    const values = evaluate(item.id);
    const name = normalize(item.name);
    if (names.has(name)) throw Error(`Duplicate food name: ${item.name}`);
    names.add(name);
    return validateFood({
      id: item.id, name: item.name, alternateNames: item.alternateNames || [],
      category: item.category, servingBasis: 'per_100g', unit: 'g',
      kcalPer100g: +values.kcal.toFixed(2), proteinGPer100g: +values.proteinG.toFixed(2),
      carbsGPer100g: +values.carbsG.toFixed(2), fatGPer100g: +values.fatG.toFixed(2),
      isEstimated: true,
      sourceLabel: item.per100g
        ? `Viện Dinh dưỡng 2007 · mã ${item.sourceFoodCode} · Ước tính`
        : 'HealthMate · Công thức tham khảo từ VDD 2007 · Ước tính',
      sourceUrl: source.sourceUrl,
      catalogVersion: recipes.version,
      sourceDetails: item.per100g
        ? {method: 'reference_table', foodCode: item.sourceFoodCode, pdfPage: item.sourcePdfPage, basis: source.basis}
        : {method: 'recipe_estimate', yieldGrams: item.yieldGrams,
            ingredients: item.ingredients.map(([reference, grams]) => ({reference, grams})),
            note: recipes.method + ' ' + recipes.limitation},
    });
  });
}

function planAdditions(catalog, existing) {
  const ids = new Set(existing.map(doc => doc.name.split('/').pop()));
  const names = new Set(existing.map(doc => normalize(doc.fields?.name?.stringValue || '')));
  const additions = catalog.filter(food => !ids.has(food.id) && !names.has(normalize(food.name)));
  return {additions, skipped: catalog.length - additions.length};
}

function value(data) {
  if (typeof data === 'string') return {stringValue: data};
  if (typeof data === 'boolean') return {booleanValue: data};
  if (typeof data === 'number' && Number.isFinite(data)) return {doubleValue: data};
  if (Array.isArray(data)) return {arrayValue: {values: data.map(value)}};
  if (data && typeof data === 'object') return {mapValue: {fields: Object.fromEntries(Object.entries(data).map(([key, item]) => [key, value(item)]))}};
  throw Error('Unsupported Firestore value.');
}

function createWrites(project, foods) {
  if (!/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/.test(project)) throw Error('Invalid project id.');
  return foods.map(food => {
    validateFood(food);
    const {id, ...fields} = food;
    return {
      update: {name: `projects/${project}/databases/(default)/documents/food_catalog/${id}`,
        fields: Object.fromEntries(Object.entries(fields).map(([key, data]) => [key, value(data)]))},
      currentDocument: {exists: false}, // Never overwrite an existing catalog entry.
      updateTransforms: [{fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'}],
    };
  });
}

async function main(args) {
  const projectIndex = args.indexOf('--project');
  const project = projectIndex >= 0 ? args[projectIndex + 1] : null;
  if (!project) throw Error('Pass --project <project-id>. Default is dry run; add --apply to create new catalog entries.');
  const catalog = buildCatalog();
  createWrites(project, []); // Validate before authentication/network requests.
  // Fixed command only: no project, file paths or user text interpolated in shell.
  const globalModules = execSync('npm root -g', {encoding: 'utf8', windowsHide: true}).trim();
  const auth = require(path.join(globalModules, 'firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('Firebase CLI login is required. Run firebase login.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const api = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
  const request = async (url, body) => {
    const response = await fetch(url, {method: body ? 'POST' : 'GET',
      headers: {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'},
      body: body ? JSON.stringify(body) : undefined});
    if (!response.ok) throw Error(`Firestore HTTP ${response.status}; no credentials or response body logged. Re-read catalog before retrying.`);
    return response.json();
  };
  const existing = [];
  let page;
  do {
    const query = new URLSearchParams({pageSize: '300'});
    if (page) query.set('pageToken', page);
    const response = await request(`${api}/food_catalog?${query}`);
    existing.push(...(response.documents || []));
    page = response.nextPageToken;
  } while (page);
  const {additions, skipped} = planAdditions(catalog, existing);
  const writes = createWrites(project, additions);
  if (writes.length > 450) throw Error('Too many additions for this atomic import; review dataset first.');
  const summary = {project, mode: args.includes('--apply') ? 'apply' : 'dry-run', existing: existing.length,
    additions: additions.length, skipped, version: recipes.version};
  console.log(JSON.stringify(summary));
  if (!args.includes('--apply') || !writes.length) return;
  await request(`${api}:commit`, {writes});
  console.log(`Created ${writes.length} catalog entries atomically. Existing entries and users/* were not modified.`);
}

module.exports = {buildCatalog, validateFood, planAdditions, createWrites};
if (require.main === module) main(process.argv.slice(2)).catch(error => {console.error(error.message); process.exitCode = 1;});
