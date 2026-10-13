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
  birthDate: null,
  healthGoal: null,
  targetWeightKg: null,
  onboardingCompletedAt: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 2,
});

const metricData = () => ({
  weightKg: 62.5,
  measuredAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
  note: 'Buổi sáng',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const mealItem = (overrides = {}) => ({
  foodId: 'rice-cooked',
  name: 'Cơm trắng chín',
  grams: 150,
  kcal: 195,
  proteinG: 4.04,
  carbsG: 42.26,
  fatG: 0.42,
  sourceLabel: 'USDA FoodData Central — tham khảo/100 g',
  isEstimated: true,
  ...overrides,
});

const mealData = (items = [mealItem()]) => ({
  mealType: 'lunch',
  consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  items,
  totalKcal: items.reduce((sum, item) => sum + item.kcal, 0),
  totalProteinG: items.reduce((sum, item) => sum + item.proteinG, 0),
  totalCarbsG: items.reduce((sum, item) => sum + item.carbsG, 0),
  totalFatG: items.reduce((sum, item) => sum + item.fatG, 0),
  source: 'manual',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 2,
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

test('owner can create, read, update and delete their profile', async () => {
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
  await assertFails(updateDoc(reference, { schemaVersion: 3 }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

test('owner can complete onboarding only with valid required data', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  });
  const reference = doc(alice.firestore(), 'users/alice');
  await assertSucceeds(setDoc(reference, profileData()));

  await assertFails(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'lose_weight',
      targetWeightKg: null,
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'unsupported_goal',
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'lose_weight',
      targetWeightKg: 58,
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(reference, {
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
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
  await assertFails(deleteDoc(doc(bob.firestore(), 'users/alice')));
});

test('only the owner can delete nested private account data', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users/alice/goals/goal-1'),
      { status: 'active' },
    );
    await setDoc(
      doc(
        context.firestore(),
        'users/alice/chat_sessions/session-1/messages/message-1',
      ),
      { text: 'private' },
    );
  });
  const alice = environment.authenticatedContext('alice');
  const bob = environment.authenticatedContext('bob');
  const goalPath = 'users/alice/goals/goal-1';
  const messagePath =
    'users/alice/chat_sessions/session-1/messages/message-1';

  await assertFails(deleteDoc(doc(bob.firestore(), goalPath)));
  await assertFails(deleteDoc(doc(bob.firestore(), messagePath)));
  await assertFails(getDoc(doc(bob.firestore(), goalPath)));
  await assertSucceeds(getDoc(doc(alice.firestore(), goalPath)));
  await assertSucceeds(deleteDoc(doc(alice.firestore(), goalPath)));
  await assertSucceeds(deleteDoc(doc(alice.firestore(), messagePath)));
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
});

test('meal rules accept exactly one and five valid items', async () => {
  const alice = environment.authenticatedContext('alice');
  const db = alice.firestore();
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/meal_logs/one-item'), mealData()),
  );
  await assertSucceeds(
    setDoc(
      doc(db, 'users/alice/meal_logs/five-items'),
      mealData(Array.from({ length: 5 }, () => mealItem())),
    ),
  );
});

test('meal rules reject empty and oversized item lists', async () => {
  const alice = environment.authenticatedContext('alice');
  const db = alice.firestore();
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/empty'), mealData([])),
  );
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/too-many'),
      mealData(Array.from({ length: 6 }, () => mealItem())),
    ),
  );
});

test('meal rules reject wrong item types and extra fields', async () => {
  const alice = environment.authenticatedContext('alice');
  const db = alice.firestore();
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/wrong-item-type'),
      mealData([mealItem({ grams: '150' })]),
    ),
  );
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/extra-item-field'),
      mealData([mealItem({ secret: true })]),
    ),
  );
});

for (let invalidIndex = 0; invalidIndex < 5; invalidIndex += 1) {
  test(`meal rules reject an invalid item at position ${invalidIndex}`, async () => {
    const alice = environment.authenticatedContext('alice');
    const items = Array.from({ length: 5 }, () => mealItem());
    items[invalidIndex] = mealItem({ grams: 0 });
    await assertFails(
      setDoc(
        doc(
          alice.firestore(),
          `users/alice/meal_logs/invalid-item-${invalidIndex}`,
        ),
        mealData(items),
      ),
    );
  });
}

test('meal rules block cross-UID, invalid fields and createdAt changes', async () => {
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
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
});

test('meal date metadata is required and legacy meals can be upgraded on edit', async () => {
  const alice = environment.authenticatedContext('alice');
  const db = alice.firestore();
  const missingDateKey = mealData();
  delete missingDateKey.dateKey;
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/missing-date'), missingDateKey),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/bad-offset'), {
      ...mealData(),
      timezoneOffsetMinutes: 841,
    }),
  );

  const legacyPath = 'users/alice/meal_logs/legacy';
  await environment.withSecurityRulesDisabled(async (context) => {
    const legacy = mealData();
    delete legacy.dateKey;
    delete legacy.timezoneOffsetMinutes;
    legacy.schemaVersion = 1;
    await setDoc(doc(context.firestore(), legacyPath), legacy);
  });
  const legacyReference = doc(db, legacyPath);
  await assertSucceeds(getDoc(legacyReference));
  await assertSucceeds(
    updateDoc(legacyReference, {
      dateKey: '2026-01-01',
      timezoneOffsetMinutes: 420,
      schemaVersion: 2,
      updatedAt: serverTimestamp(),
    }),
  );
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
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad-date'), {
    ...waterData(),
    dateKey: '2026-13-01',
  }));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad-offset'), {
    ...waterData(),
    timezoneOffsetMinutes: 841,
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
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/activity_logs/bad-date'), {
    ...activityData(),
    dateKey: '2026-01-32',
  }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});
