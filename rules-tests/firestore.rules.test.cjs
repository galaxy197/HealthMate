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
  collectionGroup,
  writeBatch,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  runTransaction,
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

// Stage 9: exact client transaction shape; both messages and parent are atomic.
async function saveChatTurn(db, uid, sessionId, turnId, overrides = {}, assistantOverrides = {}) {
  const parent = doc(db, `users/${uid}/chat_sessions/${sessionId}`);
  const user = doc(db, `users/${uid}/chat_sessions/${sessionId}/messages/${turnId}_u`);
  const assistant = doc(db, `users/${uid}/chat_sessions/${sessionId}/messages/${turnId}_a`);
  return runTransaction(db, async (transaction) => {
    const existing = await transaction.get(user);
    if (existing.exists()) return;
    const snapshot = await transaction.get(parent);
    const count = snapshot.data()?.messageCount ?? 0;
    const fields = { messageCount: count + 2, lastTurnId: turnId, updatedAt: serverTimestamp() };
    if (snapshot.exists()) transaction.update(parent, fields);
    else transaction.set(parent, {
      ...fields, title: 'Trò chuyện HealthMate', createdAt: serverTimestamp(), schemaVersion: 1,
    });
    const message = (role, sequence) => ({
      role, sequence, turnId, text: role === 'user' ? 'Hôm nay tôi ăn bao nhiêu kcal?' : 'Chưa có bản ghi.',
      source: 'journal', createdAt: serverTimestamp(), schemaVersion: 1, ...overrides,
      ...(role === 'assistant' ? assistantOverrides : {}),
    });
    transaction.set(user, message('user', count));
    transaction.set(assistant, message('assistant', count + 1));
  });
}

test('chat owner can atomically save, read ordered history, retry idempotently and delete children', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const turn = 'a'.repeat(20);
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  const sessions = await assertSucceeds(getDocs(query(collection(alice, 'users/alice/chat_sessions'),
    orderBy('updatedAt', 'desc'), limit(20))));
  if (sessions.size !== 1 || sessions.docs[0].data().messageCount !== 2) throw new Error('Retry duplicated turn');
  const messages = await assertSucceeds(getDocs(query(collection(alice, 'users/alice/chat_sessions/session1/messages'),
    orderBy('sequence'), limit(40))));
  if (messages.size !== 2 || messages.docs[0].data().role !== 'user' || messages.docs[1].data().role !== 'assistant') {
    throw new Error('History order or atomic pairing failed');
  }
  await assertFails(updateDoc(messages.docs[0].ref, { text: 'overwrite' }));
  for (const message of messages.docs) await assertSucceeds(deleteDoc(message.ref));
  await assertSucceeds(deleteDoc(sessions.docs[0].ref));
});

test('chat denies cross-UID and unauthenticated session/message reads, writes and deletes', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const turn = 'a'.repeat(20);
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  for (const db of [bob, guest]) {
    for (const path of ['users/alice/chat_sessions/session1', `users/alice/chat_sessions/session1/messages/${turn}_u`]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(updateDoc(doc(db, path), { text: 'hijack' }));
      await assertFails(deleteDoc(doc(db, path)));
    }
    await assertFails(getDocs(collection(db, 'users/alice/chat_sessions')));
    await assertFails(getDocs(collection(db, 'users/alice/chat_sessions/session1/messages')));
    await assertFails(saveChatTurn(db, 'alice', 'session2', turn));
  }
  await assertSucceeds(saveChatTurn(bob, 'bob', 'session1', turn));
});

test('chat rejects unpaired, oversized, unknown-role/source/schema messages and invalid counters', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const turn = 'a'.repeat(20);
  const parent = doc(alice, 'users/alice/chat_sessions/session1');
  await assertFails(setDoc(parent, { title: 'orphan', messageCount: 2,
    lastTurnId: turn, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), schemaVersion: 1 }));
  for (const invalid of [{ text: 'x'.repeat(1001) }, { role: 'system' }, { source: 'admin' }, { extra: 'secret' },
    { sequence: -1 }, { schemaVersion: 2 }, { createdAt: Timestamp.fromMillis(0) }]) {
    await assertFails(saveChatTurn(alice, 'alice', 'session1', turn, invalid));
  }
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  await assertFails(updateDoc(parent, { messageCount: 4, updatedAt: serverTimestamp() }));
  await assertFails(saveChatTurn(alice, 'alice', 'session1', 'c'.repeat(20), {}, { text: 'x'.repeat(6001) }));
  const batch = writeBatch(alice);
  batch.set(doc(alice, `users/alice/chat_sessions/session1/messages/${'b'.repeat(20)}_a`), {
    role: 'assistant', sequence: 3, turnId: 'b'.repeat(20), text: 'x'.repeat(6001), source: 'ai',
    createdAt: serverTimestamp(), schemaVersion: 1,
  });
  await assertFails(batch.commit());
});

test('chat enforces maximum 20 turns even with a direct client', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  for (let index = 0; index < 20; index++) {
    await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', String(index).padStart(20, '0')));
  }
  await assertFails(saveChatTurn(alice, 'alice', 'session1', 'z'.repeat(20)));
  const data = await getDoc(doc(alice, 'users/alice/chat_sessions/session1'));
  if (data.data().messageCount !== 40) throw new Error('Invalid session size');
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

test('audit: date keys must match the timestamp in the recorded timezone, including midnight and leap day', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const fixtures = [
    ['meal_logs', mealData(), 'consumedAt'],
    ['water_logs', waterData(), 'consumedAt'],
    ['activity_logs', activityData(), 'performedAt'],
  ];
  for (const [name, original, timeField] of fixtures) {
    const boundary = { ...original, [timeField]: Timestamp.fromDate(new Date('2026-10-15T17:00:00Z')),
      dateKey: '2026-10-16', timezoneOffsetMinutes: 420 };
    await assertSucceeds(setDoc(doc(db, `users/alice/${name}/boundary`), boundary));
    await assertFails(setDoc(doc(db, `users/alice/${name}/mismatch`), { ...boundary, dateKey: '2026-10-15' }));
    await assertFails(setDoc(doc(db, `users/alice/${name}/impossible`), { ...boundary, dateKey: '2026-02-30' }));
    await assertSucceeds(setDoc(doc(db, `users/alice/${name}/leap`), {
      ...original, [timeField]: Timestamp.fromDate(new Date('2024-02-29T00:00:00Z')),
      dateKey: '2024-02-29', timezoneOffsetMinutes: 0,
    }));
    for (const offset of [-721, 841, '420', null]) {
      await assertFails(setDoc(doc(db, `users/alice/${name}/invalid-offset`), { ...boundary, timezoneOffsetMinutes: offset }));
    }
  }
});

test('audit: unknown paths, collection-group access and privilege injection cannot bypass ownership', async () => {
  const db = environment.authenticatedContext('alice', { email: 'alice@example.com' }).firestore();
  const guest = environment.unauthenticatedContext().firestore();
  for (const path of ['admin/config', 'secrets/keys', 'users/bob/future/data']) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { value: true }));
    await assertFails(deleteDoc(doc(db, path)));
    await assertFails(getDoc(doc(guest, path)));
  }
  await assertFails(setDoc(doc(db, 'users/alice/future/data'), { value: 'unrecognized schema' }));
  await assertSucceeds(setDoc(doc(db, 'users/alice'), profileData()));
  await assertFails(updateDoc(doc(db, 'users/alice'), { role: 'admin', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(collectionGroup(db, 'water_logs')));
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

const goalData = (overrides = {}) => ({
  goalType: 'water', targetValue: 1500, unit: 'ml',
  startDateKey: '2026-10-16', endDateKey: '2026-11-16',
  status: 'active', baselineWeightKg: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), schemaVersion: 1,
  ...overrides,
});
const questData = (dateKey = '2026-10-16') => ({
  dateKey, questType: 'water', title: 'Ghi lại nước đã uống',
  description: 'Chỉ ghi lượng thực tế.', reason: 'Bạn chọn theo dõi nước.',
  targetValue: 250, unit: 'ml', status: 'available', completedAt: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ruleVersion: 1,
});

test('goals CRUD preserves schema, unit, baseline, timestamps and ownership', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const path = 'users/alice/goals/water';
  const ref = doc(alice, path);
  await assertSucceeds(setDoc(ref, goalData()));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/goals')));
  await assertSucceeds(updateDoc(ref, { targetValue: 1000, status: 'paused', updatedAt: serverTimestamp() }));
  for (const db of [bob, guest]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/alice/goals')));
    await assertFails(setDoc(doc(db, 'users/alice/goals/other'), goalData()));
    await assertFails(updateDoc(doc(db, path), { status: 'completed', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db, path)));
  }
  for (const bad of [
    { targetValue: -1 }, { targetValue: 5001 }, { targetValue: 123.5 },
    { unit: 'litres' }, { status: 'unknown' }, { extra: true },
    { endDateKey: '2026-10-01' }, { startDateKey: '2026-13-01' },
    { startDateKey: '2026-02-30' },
    { baselineWeightKg: 70 },
  ]) {
    await assertFails(setDoc(doc(alice, 'users/alice/goals/invalid'), goalData(bad)));
  }
  await assertFails(updateDoc(ref, { createdAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { goalType: 'activity', unit: 'phút', targetValue: 20, updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(alice, 'users/alice/goals/weight'), goalData({
    goalType: 'weight', targetValue: 65, unit: 'kg', baselineWeightKg: 70,
  })));
  await assertFails(updateDoc(doc(alice, 'users/alice/goals/weight'), {
    baselineWeightKg: 80, updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(deleteDoc(ref));
});

test('quests reject cross-UID access and illegal content or status transitions', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const path = 'users/alice/daily_quests/2026-10-16';
  const ref = doc(alice, path);
  await assertSucceeds(setDoc(ref, questData()));
  await assertSucceeds(getDoc(ref));
  for (const db of [bob, guest]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/alice/daily_quests')));
    await assertFails(setDoc(doc(db, 'users/alice/daily_quests/2026-10-17'), questData('2026-10-17')));
    await assertFails(updateDoc(doc(db, path), { status: 'skipped', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db, path)));
  }
  await assertFails(setDoc(doc(alice, 'users/alice/daily_quests/random-id'), questData()));
  await assertFails(setDoc(doc(alice, 'users/alice/daily_quests/2026-02-30'), questData('2026-02-30')));
  await assertFails(updateDoc(ref, { title: 'Changed', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { status: 'completed', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, {
    status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { status: 'available', completedAt: null, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { status: 'skipped', completedAt: null, updatedAt: serverTimestamp() }));
  const skipped = doc(alice, 'users/alice/daily_quests/2026-10-17');
  await assertSucceeds(setDoc(skipped, questData('2026-10-17')));
  await assertSucceeds(updateDoc(skipped, { status: 'skipped', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(skipped, { status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
});

test('create-if-absent transactions do not duplicate or overwrite a finished daily quest', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const ref = doc(alice, 'users/alice/daily_quests/2026-10-16');
  const ensure = () => runTransaction(alice, async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists()) tx.set(ref, questData());
  });
  await Promise.all([ensure(), ensure()]);
  await assertSucceeds(updateDoc(ref, { status: 'skipped', updatedAt: serverTimestamp() }));
  await ensure();
  const documents = await getDocs(collection(alice, 'users/alice/daily_quests'));
  if (documents.size !== 1 || documents.docs[0].data().status !== 'skipped') {
    throw new Error('Daily quest must keep one document and its terminal status');
  }
});

test('weekly range queries keep local date boundaries, legacy meals and UID isolation', async () => {
  const start = Timestamp.fromDate(new Date('2026-10-11T17:00:00Z'));
  const end = Timestamp.fromDate(new Date('2026-10-18T17:00:00Z'));
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const current = { ...mealData(), dateKey: '2026-10-12', consumedAt: start };
    const legacy = (time) => {
      const data = { ...mealData(), consumedAt: time, schemaVersion: 1 };
      delete data.dateKey;
      delete data.timezoneOffsetMinutes;
      return data;
    };
    await setDoc(doc(db, 'users/alice/meal_logs/current'), current);
    await setDoc(doc(db, 'users/alice/meal_logs/start'), legacy(start));
    await setDoc(doc(db, 'users/alice/meal_logs/last'), legacy(Timestamp.fromMillis(end.toMillis() - 1)));
    await setDoc(doc(db, 'users/alice/meal_logs/end'), legacy(end));
    await setDoc(doc(db, 'users/alice/meal_logs/before'), legacy(Timestamp.fromMillis(start.toMillis() - 1)));
    await setDoc(doc(db, 'users/alice/meal_logs/key-wins'), {
      ...current, consumedAt: Timestamp.fromMillis(start.toMillis() - 1),
    });
    for (const [name, data] of [['water_logs', waterData()], ['activity_logs', activityData()]]) {
      await setDoc(doc(db, `users/alice/${name}/start`), { ...data, dateKey: '2026-10-12' });
      await setDoc(doc(db, `users/alice/${name}/end`), { ...data, dateKey: '2026-10-19' });
    }
    for (const [id, measuredAt] of [['start', start], ['last', Timestamp.fromMillis(end.toMillis() - 1)], ['end', end]]) {
      await setDoc(doc(db, `users/alice/body_metrics/${id}`), { ...metricData(), measuredAt });
    }
  });
  const alice = environment.authenticatedContext('alice').firestore();
  const mealCollection = collection(alice, 'users/alice/meal_logs');
  const modern = await assertSucceeds(getDocs(query(mealCollection,
    where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'))));
  const legacy = await assertSucceeds(getDocs(query(mealCollection,
    where('consumedAt', '>=', start), where('consumedAt', '<', end))));
  const byId = new Map(modern.docs.map((d) => [d.id, d.data()]));
  for (const d of legacy.docs) {
    if (typeof d.data().dateKey !== 'string') byId.set(d.id, d.data());
  }
  const ids = [...byId.keys()].sort().join(',');
  if (ids !== 'current,key-wins,last,start') throw new Error(`Unexpected weekly meal IDs: ${ids}`);
  for (const name of ['water_logs', 'activity_logs']) {
    const q = query(collection(alice, `users/alice/${name}`),
      where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'));
    const snapshot = await assertSucceeds(getDocs(q));
    if (snapshot.size !== 1 || snapshot.docs[0].id !== 'start') throw new Error('Range boundary failed');
  }
  const bob = environment.authenticatedContext('bob').firestore();
  const metrics = collection(alice, 'users/alice/body_metrics');
  const metricRange = await assertSucceeds(getDocs(query(metrics,
    where('measuredAt', '>=', start), where('measuredAt', '<', end))));
  if (metricRange.size !== 2) throw new Error('Weight range must exclude next week');
  const latest = await assertSucceeds(getDocs(query(metrics,
    where('measuredAt', '<', end), orderBy('measuredAt', 'desc'), limit(1))));
  if (latest.size !== 1 || latest.docs[0].id !== 'last') throw new Error('Latest weight must be limited to one record');
  await assertFails(getDocs(query(collection(bob, 'users/alice/body_metrics'),
    where('measuredAt', '>=', start), where('measuredAt', '<', end))));
  for (const name of ['meal_logs', 'water_logs', 'activity_logs']) {
    await assertFails(getDocs(query(collection(bob, `users/alice/${name}`),
      where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'))));
  }
});
