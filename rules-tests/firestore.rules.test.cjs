const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} = require('firebase/firestore');

let environment;

const profileData = (email = 'alice@example.com') => ({
  displayName: 'Alice',
  email,
  heightCm: 168,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 1,
});

const metricData = () => ({
  weightKg: 62.5,
  measuredAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
  note: 'Buổi sáng',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const mealData = () => ({
  mealType: 'lunch',
  consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  items: [{
    foodId: 'rice-cooked',
    name: 'Cơm trắng chín',
    grams: 150,
    kcal: 195,
    proteinG: 4.04,
    carbsG: 42.26,
    fatG: 0.42,
    sourceLabel: 'USDA FoodData Central — tham khảo/100 g',
    isEstimated: true,
  }],
  totalKcal: 195,
  totalProteinG: 4.04,
  totalCarbsG: 42.26,
  totalFatG: 0.42,
  source: 'manual',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 1,
});

const waterData = () => ({
  amountMl: 250,
  consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const activityData = () => ({
  activityType: 'walking',
  durationMinutes: 30,
  performedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  note: 'Đi bộ trong công viên',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-healthmate-rules',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

test('owner can create, read and update only allowed profile fields', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const reference = doc(alice.firestore(), 'users/alice');

  await assertSucceeds(setDoc(reference, profileData()));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      heightCm: 170.5,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(reference, { schemaVersion: 2 }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertFails(deleteDoc(reference));
});

test('other users and anonymous clients cannot access a profile', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const bob = environment.authenticatedContext('bob', {
    email: 'bob@example.com',
  });
  const anonymous = environment.unauthenticatedContext();

  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'users/alice'), profileData()),
  );
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice')));
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice'), profileData('bob@example.com')),
  );
  await assertFails(getDoc(doc(anonymous.firestore(), 'users/alice')));
});

test('profile schema rejects extra fields, bad email and invalid height', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const db = alice.firestore();

  await assertFails(
    setDoc(doc(db, 'users/extra'), { ...profileData(), role: 'admin' }),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice'), profileData('other@example.com')),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice'), { ...profileData(), heightCm: 20 }),
  );
});

test('owner can create, list, update and delete valid body metrics', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const db = alice.firestore();
  const reference = doc(db, 'users/alice/body_metrics/metric-1');

  await assertSucceeds(setDoc(reference, metricData()));
  await assertSucceeds(
    getDocs(collection(db, 'users/alice/body_metrics')),
  );
  await assertSucceeds(
    updateDoc(reference, {
      weightKg: 63.1,
      note: '',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(deleteDoc(reference));
});

test('body metric rules block cross-UID and invalid writes', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const bob = environment.authenticatedContext('bob', {
    email: 'bob@example.com',
  });
  const aliceReference = doc(
    alice.firestore(),
    'users/alice/body_metrics/metric-1',
  );

  await assertSucceeds(setDoc(aliceReference, metricData()));
  await assertFails(
    getDoc(doc(bob.firestore(), 'users/alice/body_metrics/metric-1')),
  );
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice/body_metrics/metric-2'), metricData()),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'users/alice/body_metrics/bad'), {
      ...metricData(),
      weightKg: 10,
    }),
  );
  await assertFails(
    updateDoc(aliceReference, { createdAt: serverTimestamp() }),
  );
});

test('signed-in users can read catalog but clients cannot write it', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'food_catalog/rice-cooked'), {
      name: 'Cơm trắng chín',
    });
  });
  const alice = environment.authenticatedContext('alice');
  const anonymous = environment.unauthenticatedContext();
  await assertSucceeds(getDoc(doc(alice.firestore(), 'food_catalog/rice-cooked')));
  await assertFails(getDoc(doc(anonymous.firestore(), 'food_catalog/rice-cooked')));
  await assertFails(
    setDoc(doc(alice.firestore(), 'food_catalog/hacked'), { name: 'Hacked' }),
  );
});

test('owner can create, list, update and delete a valid meal log', async () => {
  const alice = environment.authenticatedContext('alice');
  const db = alice.firestore();
  const reference = doc(db, 'users/alice/meal_logs/meal-1');
  await assertSucceeds(setDoc(reference, mealData()));
  await assertSucceeds(getDocs(collection(db, 'users/alice/meal_logs')));
  await assertSucceeds(
    updateDoc(reference, {
      mealType: 'dinner',
      source: 'ai_assisted',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(deleteDoc(reference));
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/meal_logs/five-items'), {
      ...mealData(),
      items: Array(5).fill(mealData().items[0]),
    }),
  );
});

test('meal rules block cross-UID, invalid fields and oversized item lists', async () => {
  const alice = environment.authenticatedContext('alice');
  const bob = environment.authenticatedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/meal_logs/meal-1');
  await assertSucceeds(setDoc(reference, mealData()));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/meal_logs/meal-1')));
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice/meal_logs/meal-2'), mealData()),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'users/alice/meal_logs/bad-type'), {
      ...mealData(),
      mealType: 'midnight',
    }),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'users/alice/meal_logs/too-many'), {
      ...mealData(),
      items: Array(6).fill(mealData().items[0]),
    }),
  );
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
});

test('owner can CRUD water logs while invalid and cross-UID access is blocked', async () => {
  const alice = environment.authenticatedContext('alice');
  const bob = environment.authenticatedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/water_logs/water-1');

  await assertSucceeds(setDoc(reference, waterData()));
  await assertSucceeds(getDocs(collection(alice.firestore(), 'users/alice/water_logs')));
  await assertSucceeds(updateDoc(reference, { amountMl: 350, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/water_logs/water-1')));
  await assertFails(setDoc(doc(bob.firestore(), 'users/alice/water_logs/water-2'), waterData()));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad'), {
    ...waterData(),
    amountMl: 20,
  }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

test('owner can CRUD activity logs while invalid and cross-UID access is blocked', async () => {
  const alice = environment.authenticatedContext('alice');
  const bob = environment.authenticatedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/activity_logs/activity-1');

  await assertSucceeds(setDoc(reference, activityData()));
  await assertSucceeds(getDocs(collection(alice.firestore(), 'users/alice/activity_logs')));
  await assertSucceeds(updateDoc(reference, {
    durationMinutes: 45,
    note: '',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/activity_logs/activity-1')));
  await assertFails(setDoc(doc(bob.firestore(), 'users/alice/activity_logs/activity-2'), activityData()));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/activity_logs/bad'), {
    ...activityData(),
    activityType: 'swimming',
  }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});
