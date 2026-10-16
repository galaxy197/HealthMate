// Opt-in real SDK test: the filename deliberately does not end in _test.dart.
// Keep this at test/ root for the Windows web runner's path handling.
// Run only with the demo Auth + Firestore emulators; see docs/test-report.md.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/chatbot/data/firebase_chat_repository.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS');
  const projectId = 'demo-healthmate-rules';
  if (!enabled || !projectId.startsWith('demo-')) {
    throw StateError(
      'Requires HEALTHMATE_EMULATOR_TESTS=true and a demo project. No production fallback.',
    );
  }
  late FirebaseApp app;
  late FirebaseAuth auth;
  late FirebaseFirestore db;
  late FirebaseAuthRepository authentication;
  late FirebaseHealthProfileRepository profiles;
  late FirebaseNutritionRepository nutrition;
  late FirebaseWaterRepository water;
  late FirebaseActivityRepository activities;
  late FirebaseGoalsRepository goals;
  late FirebaseChatRepository chats;
  late String alice;
  late String bob;
  late String chatSessionId;
  late String chatTurnId;
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final aliceEmail = 'alice-$suffix@example.com';
  final bobEmail = 'bob-$suffix@example.com';
  const password = 'Emulator-only-test-123!';
  final day = localDateOnly(DateTime.now());

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    app = await Firebase.initializeApp(
      name: 'stage10-emulator',
      options: const FirebaseOptions(
        apiKey: 'emulator-only-fake-api-key',
        appId: '1:1234567890:web:stage10emulator',
        messagingSenderId: '1234567890',
        projectId: projectId,
        authDomain: 'localhost',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    await auth.setPersistence(Persistence.NONE);
    db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    authentication = FirebaseAuthRepository(auth);
    profiles = FirebaseHealthProfileRepository(db);
    nutrition = FirebaseNutritionRepository(db);
    water = FirebaseWaterRepository(db);
    activities = FirebaseActivityRepository(db);
    goals = FirebaseGoalsRepository(db);
    chats = FirebaseChatRepository(db);
    await authentication.register(email: aliceEmail, password: password);
    alice = auth.currentUser!.uid;
  });

  tearDownAll(() async {
    await db.enableNetwork();
    await auth.signOut();
    await app.delete();
  });

  test(
    'real Flutter repositories persist and reload onboarding, logs, goal, quest and chat',
    () async {
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      final draft = OnboardingDraft(
        displayName: 'Emulator Alice',
        birthDate: DateTime(2000, 1, 15),
        heightCm: 170,
        currentWeightKg: 70,
        healthGoal: HealthGoal.maintainWeight,
        targetWeightKg: null,
      );
      await profiles.completeOnboarding(uid: alice, draft: draft);
      final first =
          (await db
                  .doc('users/$alice')
                  .get(const GetOptions(source: Source.server)))
              .data()!['onboardingCompletedAt'];
      // Repeating setup must preserve the immutable completion marker.
      await profiles.completeOnboarding(uid: alice, draft: draft);
      final profile = await profiles.watchProfile(alice).first;
      expect(profile!.isOnboardingComplete, isTrue);
      expect(profile.onboardingCompletedAt, (first as Timestamp).toDate());
      expect((await profiles.watchBodyMetrics(alice).first).length, 1);
      final now = DateTime.now();
      await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.lunch,
          consumedAt: now,
          source: MealSource.manual,
          items: const [
            MealItemSnapshot(
              foodId: 'test-rice',
              name: 'Cơm kiểm thử',
              grams: 150,
              nutrition: NutritionTotals(
                kcal: 195,
                proteinG: 4,
                carbsG: 42,
                fatG: 0.4,
              ),
              sourceLabel: 'Emulator fixture',
              isEstimated: true,
            ),
          ],
        ),
      );
      await water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 250, consumedAt: now),
      );
      await activities.add(
        uid: alice,
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 20,
          performedAt: now,
        ),
      );
      final end = DateTime(day.year, day.month, day.day + 1);
      expect(
        totalMealNutrition(await nutrition.loadRange(alice, day, end)).kcal,
        195,
      );
      expect(totalWaterMl(await water.loadRange(alice, day, end)), 250);
      expect(
        totalActivityMinutes(await activities.loadRange(alice, day, end)),
        20,
      );
      expect(
        (await nutrition.watchMealLogs(alice, day).first).single.totals.kcal,
        195,
      );
      await goals.saveGoal(
        alice,
        GoalDraft(
          type: GoalType.water,
          targetValue: 500,
          startDate: day,
          endDate: end,
        ),
      );
      expect(
        (await goals.watchGoals(alice).first).single.draft.targetValue,
        500,
      );
      final quest = DailyQuest(
        dateKey: localDateKey(day),
        type: QuestType.water,
        title: 'Ghi nước',
        description: 'Ghi một lần uống nước.',
        reason: 'Kiểm thử',
        targetValue: 250,
        unit: 'ml',
      );
      await goals.ensureQuest(alice, quest);
      await goals.finishQuest(alice, quest.dateKey, QuestStatus.completed);
      await goals.ensureQuest(alice, quest);
      expect(
        (await goals.watchQuest(alice, quest.dateKey).first)!.status,
        QuestStatus.completed,
      );
      final session = chats.newId();
      chatSessionId = session;
      final turn = ChatTurn(
        id: chats.newId(),
        question: 'Kcal đã ghi',
        answer: '195 kcal theo dữ liệu kiểm thử.',
        source: ChatSource.journal,
      );
      chatTurnId = turn.id;
      await chats.saveTurn(alice, session, turn);
      await chats.saveTurn(alice, session, turn);
      expect((await chats.loadSessions(alice)).single.messageCount, 2);
      expect(
        (await chats.loadMessages(
          alice,
          session,
        )).map((message) => message.isUser),
        [true, false],
      );
    },
  );

  test(
    'real Auth credentials cannot read or write another UID through Firestore',
    () async {
      await authentication.signOut();
      await authentication.register(email: bobEmail, password: password);
      bob = auth.currentUser!.uid;
      expect(bob, isNot(alice));
      await expectLater(
        db.doc('users/$alice').get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await expectLater(
        water.add(
          uid: alice,
          draft: WaterLogDraft(amountMl: 250, consumedAt: DateTime.now()),
        ),
        throwsA(anything),
      );
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
      expect(auth.currentUser!.uid, alice);
    },
  );

  test(
    'offline writes stay pending locally and commit once after reconnect',
    () async {
      final reference = db.collection('users/$alice/water_logs');
      await db.disableNetwork();
      var confirmed = false;
      final local = reference
          .snapshots(includeMetadataChanges: true)
          .firstWhere(
            (snapshot) =>
                snapshot.metadata.hasPendingWrites &&
                snapshot.docs.any((doc) => doc.data()['amountMl'] == 333),
          );
      final write = water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 333, consumedAt: DateTime.now()),
      );
      final confirmation = write.then((value) {
        confirmed = true;
        return value;
      });
      try {
        final snapshot = await local.timeout(const Duration(seconds: 10));
        expect(snapshot.metadata.isFromCache, isTrue);
        expect(confirmed, isFalse);
      } finally {
        await db.enableNetwork();
      }
      final id = await confirmation;
      expect(
        (await reference.doc(id).get(const GetOptions(source: Source.server)))
            .data()!['amountMl'],
        333,
      );
      expect(
        totalWaterMl(
          await water.loadRange(
            alice,
            day,
            DateTime(day.year, day.month, day.day + 1),
          ),
        ),
        583,
      );
    },
  );

  test(
    'reauthenticated password change and account cleanup remove data before Auth',
    () async {
      await authentication.reauthenticateWithPassword(password);
      await authentication.updatePassword('Changed-emulator-only-123!');
      await FirebaseAccountDataRepository(db).deleteAllUserData(alice);
      expect(auth.currentUser!.uid, alice);
      expect(
        (await db
                .doc('users/$alice')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      for (final name in [
        'body_metrics',
        'meal_logs',
        'water_logs',
        'activity_logs',
        'goals',
        'daily_quests',
        'chat_sessions',
      ]) {
        expect(
          (await db
                  .collection('users/$alice/$name')
                  .get(const GetOptions(source: Source.server)))
              .docs,
          isEmpty,
        );
      }
      for (final suffix in ['u', 'a']) {
        expect(
          (await db
                  .doc(
                    'users/$alice/chat_sessions/$chatSessionId/messages/${chatTurnId}_$suffix',
                  )
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
      }
      await authentication.deleteCurrentUser();
      expect(auth.currentUser, isNull);
    },
  );
}
