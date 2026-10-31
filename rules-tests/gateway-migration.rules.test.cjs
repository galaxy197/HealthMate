const fs = require('node:fs');
const path = require('node:path');
const {test, before, beforeEach, after} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
const owner = (uid = 'alice') => env.authenticatedContext(uid, {
  email_verified: true, auth_time: Math.floor(Date.now()/1000),
}).firestore();
const marker = 'users/alice/data_migrations/meal_date_key_v1';
const mealPath = 'users/alice/meal_logs/ordinary';
const meal = (patch = {}) => ({mealType:'lunch', consumedAt:Timestamp.fromDate(new Date('2026-10-01T05:00:00Z')),
  dateKey:'2026-10-01', timezoneOffsetMinutes:0,
  items:[{foodId:'rice',name:'Rice fixture',grams:100,kcal:130,proteinG:3,carbsG:28,fatG:1,sourceLabel:'Synthetic',isEstimated:true}],
  totalKcal:130,totalProteinG:3,totalCarbsG:28,totalFatG:1,source:'manual',
  createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:2,...patch});
async function seed(values) {
  await env.withSecurityRulesDisabled(async context => {
    for (const [name,value] of Object.entries(values)) await setDoc(doc(context.firestore(),name),value);
  });
}
async function deletion() {
  await setDoc(doc(owner(),'account_deletions/alice'),{uid:'alice',schemaVersion:1,executor:'client',state:'requested',checkpoint:0,
    requestedAt:serverTimestamp(),updatedAt:serverTimestamp()});
}
before(async () => {
  const [host,port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({projectId:'demo-healthmate-gateway-migration-rules',firestore:{host,port:Number(port),
    rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')}});
});
beforeEach(() => env.clearFirestore());
after(() => env?.cleanup());

test('gateway quota/reservation are owner-readable but never client-authorized writes', async () => {
  const names = ['ai_gateway_usage/alice','ai_gateway_usage/alice/days/2026-10-31',
    'ai_gateway_reservations/alice','ai_gateway_reservations/alice/requests/opaque-request-1234'];
  await seed(Object.fromEntries(names.map(name => [name,{chats:1,state:'sent'}])));
  for (const name of names) {
    await assertSucceeds(getDoc(doc(owner(),name)));
    for (const client of [owner(),owner('bob'),env.unauthenticatedContext().firestore()]) {
      await assertFails(setDoc(doc(client,name),{chats:0,state:'completed'}));
      await assertFails(updateDoc(doc(client,name),{chats:0}));
      await assertFails(deleteDoc(doc(client,name)));
    }
    await assertFails(getDoc(doc(owner('bob'),name)));
  }
  await deletion();
  for (const name of names.reverse()) {
    await assertSucceeds(getDoc(doc(owner(),name)));
    await assertSucceeds(deleteDoc(doc(owner(),name)));
    await assertFails(setDoc(doc(owner(),name),{chats:0}));
  }
});

test('migration certificate cannot be forged or removed to reopen legacy writes', async () => {
  await assertFails(setDoc(doc(owner(),marker),{state:'complete'}));
  await seed({[marker]:{schemaVersion:1,state:'partitioned'}});
  await assertSucceeds(getDoc(doc(owner(),marker)));
  await assertFails(getDoc(doc(owner('bob'),marker)));
  await assertFails(updateDoc(doc(owner(),marker),{state:'complete'}));
  await assertFails(deleteDoc(doc(owner(),marker)));
  await deletion();
  await assertSucceeds(deleteDoc(doc(owner(),marker)));
});

test('before migration legacy clients remain compatible but cannot invent routing fields', async () => {
  await assertSucceeds(setDoc(doc(owner(),mealPath),meal()));
  await assertSucceeds(setDoc(doc(owner(),'users/alice/meal_logs/new'),meal({queryPartition:'current'})));
  await assertFails(setDoc(doc(owner(),'users/alice/meal_logs/forged'),meal({queryPartition:'legacy'})));
  await assertFails(setDoc(doc(owner(),'users/alice/meal_logs/extra'),meal({unrecognized:true})));
});

test('migration write lock denies create/update without preventing deletion cleanup', async () => {
  await assertSucceeds(setDoc(doc(owner(),mealPath),meal({queryPartition:'current'})));
  await seed({[marker]:{schemaVersion:1,state:'migrating'}});
  await assertFails(setDoc(doc(owner(),'users/alice/meal_logs/new'),meal({queryPartition:'current'})));
  await assertFails(updateDoc(doc(owner(),mealPath),{updatedAt:serverTimestamp()}));
  await deletion();
  await assertSucceeds(deleteDoc(doc(owner(),mealPath)));
});

test('certified partition requires routed new writes and preserves legacy partition on edit', async () => {
  await seed({[marker]:{schemaVersion:1,state:'partitioned'},[mealPath]:meal({queryPartition:'legacy'})});
  await assertFails(setDoc(doc(owner(),'users/alice/meal_logs/old-client'),meal()));
  await assertSucceeds(setDoc(doc(owner(),'users/alice/meal_logs/new'),meal({queryPartition:'current'})));
  await assertSucceeds(updateDoc(doc(owner(),mealPath),{updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(owner(),mealPath),{queryPartition:'current',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(owner(),'users/alice/meal_logs/new'),{queryPartition:'legacy',updatedAt:serverTimestamp()}));
  await seed({[marker]:{schemaVersion:1,state:'complete'},[mealPath]:meal({queryPartition:'legacy'})});
  await assertFails(updateDoc(doc(owner(),mealPath),{updatedAt:serverTimestamp()}));
});
