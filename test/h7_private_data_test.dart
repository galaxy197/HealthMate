import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/data_export/data/journal_export_service.dart';
import 'package:healthmate/features/data_export/presentation/journal_export_dialog.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/auth/models/account_action_failure.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_account_data_repository.dart';
import 'support/test_app.dart';

final _now = DateTime(2026, 10, 18, 12);
SavedMealDraft saved(String id, {DateTime? updatedAt}) => SavedMealDraft(
  operationId: id,
  updatedAt: updatedAt ?? _now,
  draft: MealDraft(
    type: MealType.lunch,
    consumedAt: _now,
    timezoneOffsetOverride: 420,
    source: MealSource.manual,
    minimumSchemaVersion: 4,
    items: [
      const MealItemSnapshot(
        foodId: 'qa',
        name: 'Sữa, "QA"',
        grams: 0,
        quantityUnit: 'ml',
        quantityValue: 250,
        sourceLabel: 'Synthetic',
        isEstimated: true,
        nutrition: NutritionTotals(
          kcal: 150,
          proteinKnown: false,
          carbsKnown: false,
          fatKnown: false,
          fiberKnown: false,
          fiberG: 3,
        ),
      ),
    ],
  ),
);

void main() {
  test(
    'changing account during profile bootstrap does not start disposed profile/metric streams',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final profile = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      )..pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          healthProfileRepositoryProvider.overrideWithValue(profile),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(profile.dispose);
      final changed = Completer<void>();
      final authWatch = container.listen(authSessionProvider, (_, next) {
        if (next.value?.uid == 'B' && !changed.isCompleted) changed.complete();
      });
      addTearDown(authWatch.close);
      await container.read(authSessionProvider.future);
      final userProfile = container.listen(userProfileProvider, (_, _) {});
      addTearDown(userProfile.close);
      final metrics = container.listen(bodyMetricsProvider, (_, _) {});
      addTearDown(metrics.close);
      container.read(profileBootstrapProvider.future);
      expect(profile.ensureCalls, 1);
      auth.emitUser(
        const AuthUser(emailVerified: true, uid: 'B', email: 'b@example.com'),
      );
      await changed.future.timeout(const Duration(seconds: 2));
      container.read(profileBootstrapProvider.future);
      expect(profile.ensureCalls, 2);
      profile.pending!.complete();
      await container
          .read(bodyMetricsProvider.future)
          .timeout(const Duration(seconds: 2));
      expect(profile.fullMetricWatchCalls, 1);
    },
  );
  test(
    'durable codec keeps UID, operation ID, day, offset and partial nutrients; TTL, bounds and explicit deletion',
    () async {
      final local = FakePrivateLocalData();
      final store = MealDraftStore(local, now: () => _now);
      await Future.wait([
        store.put('A', saved('a')),
        store.put('A', saved('b')),
      ]);
      await store.put('B', saved('b'));
      final restored = await MealDraftStore(local, now: () => _now).list('A');
      expect(restored.map((d) => d.operationId), containsAll(['a', 'b']));
      final d = restored.first.draft;
      expect(d.dateKey, saved('a').draft.dateKey);
      expect(d.timezoneOffsetMinutes, 420);
      expect(d.items.single.quantityUnit, 'ml');
      expect(d.totals.proteinKnown, false);
      expect(d.totals.fiberKnown, false);
      expect(d.totals.fiberG, 3);
      await store.put(
        'A',
        saved('expired', updatedAt: _now.subtract(const Duration(days: 8))),
      );
      expect((await store.list('A')).length, 2);
      for (var i = 2; i < 20; i++) {
        await store.put('A', saved('id$i'));
      }
      await expectLater(store.put('A', saved('overflow')), throwsStateError);
      await store.remove('A', 'a');
      expect((await store.list('A')).length, 19);
      await store.clearForAccountDeletion('A');
      expect(await store.list('A'), isEmpty);
      expect((await store.list('B')).single.operationId, 'b');
      await expectLater(store.put('A', saved('late')), throwsStateError);
      local.drafts['B'] = local.drafts['B']!.replaceFirst(
        '"uid":"B"',
        '"uid":"A"',
      );
      await expectLater(store.list('B'), throwsFormatException);
    },
  );

  test(
    'failed disk write preserves previous payload and queue remains usable',
    () async {
      final local = FakePrivateLocalData();
      final store = MealDraftStore(local, now: () => _now);
      await store.put('A', saved('original'));
      local.failWrite = true;
      await expectLater(store.put('A', saved('new')), throwsStateError);
      local.failWrite = false;
      expect((await store.list('A')).single.operationId, 'original');
      await store.put('A', saved('new'));
      expect((await store.list('A')).length, 2);
    },
  );

  test(
    'export cancels safely on load or picker UID changes, source failure, invalid range, cancellation and exact bytes',
    () async {
      var uid = 'A';
      final local = FakePrivateLocalData();
      final nutrition = FakeNutritionRepository();
      addTearDown(nutrition.dispose);
      final service = JournalExportService(
        local: local,
        nutrition: nutrition,
        water: FakeWaterRepository(),
        activity: FakeActivityRepository(),
        profile: FakeHealthProfileRepository(),
        currentUid: () => uid,
      );
      final start = DateTime(2026, 10, 18), end = DateTime(2026, 10, 19);
      await expectLater(service.export(end, start), throwsFormatException);
      expect(nutrition.rangeCalls, 0);
      nutrition.rangePending = Completer<void>();
      final loading = service.export(start, end);
      await Future<void>.delayed(Duration.zero);
      uid = 'B';
      nutrition.rangePending!.complete();
      await expectLater(loading, throwsStateError);
      expect(local.picked, 0);
      uid = 'A';
      nutrition.rangePending = null;
      local.picker = () async {
        uid = 'B';
        return 'empty-ticket';
      };
      await expectLater(service.export(start, end), throwsStateError);
      expect(local.written, 0);
      expect(local.cancelled, 1);
      uid = 'A';
      nutrition.rangeError = StateError('server offline');
      await expectLater(service.export(start, end), throwsA(anything));
      expect(local.picked, 1);
      nutrition.rangeError = null;
      local.picker = () async => null;
      expect(await service.export(start, end), isNull);
      local.picker = null;
      expect(await service.export(start, end), greaterThan(100));
      expect(local.csv!.take(3), [239, 187, 191]);
      expect(utf8.decode(local.csv!), startsWith('"export_schema"'));
      expect(local.written, 1);
    },
  );

  testWidgets(
    'restore is explicit, no auto-submit; save clears only after acknowledgement and account cleanup keeps B',
    (tester) async {
      final local = FakePrivateLocalData();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final nutrition = FakeNutritionRepository();
      final container = await pumpApp(
        tester,
        privateLocalData: local,
        repository: auth,
        nutritionRepository: nutrition,
      );
      final uid = FakeAuthRepository.testUser.uid;
      final store = container.read(mealDraftStoreProvider);
      await store.put(uid, saved('restored').copyForTestNow());
      await store.put('B', saved('b').copyForTestNow());
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('open-meal-drafts')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-meal-drafts')));
      await tester.pumpAndSettle();
      expect(find.text('Bản nháp chưa xác nhận'), findsOneWidget);
      expect(nutrition.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('restore-draft-restored')));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.text('Đã giữ nháp trên thiết bị'), findsOneWidget);
      expect(nutrition.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(nutrition.addCalls, 1);
      expect(await store.list(uid), isEmpty);
      await store.put(uid, saved('cleanup').copyForTestNow());
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('password'),
        true,
      );
      expect(await store.list(uid), isEmpty);
      expect((await store.list('B')).single.operationId, 'b');
    },
  );

  testWidgets(
    'disk failure prevents sending a meal; retry keeps the durable operation ID',
    (tester) async {
      final local = FakePrivateLocalData();
      final nutrition = FakeNutritionRepository();
      final container = await pumpApp(
        tester,
        privateLocalData: local,
        nutritionRepository: nutrition,
      );
      final uid = FakeAuthRepository.testUser.uid;
      final store = container.read(mealDraftStoreProvider);
      await store.put(uid, saved('safe-retry').copyForTestNow());
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('open-meal-drafts')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-meal-drafts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-draft-safe-retry')));
      await tester.pumpAndSettle();
      local.failWrite = true;
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(nutrition.addCalls, 0);
      expect((await store.list(uid)).single.operationId, 'safe-retry');
      expect(find.byType(MealFormDialog), findsOneWidget);
      local.failWrite = false;
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(nutrition.operationIds, ['safe-retry']);
      expect(await store.list(uid), isEmpty);
    },
  );

  test(
    'an A -> B -> A session change still invalidates the pending export',
    () async {
      final local = FakePrivateLocalData();
      final nutrition = FakeNutritionRepository()
        ..rangePending = Completer<void>();
      addTearDown(nutrition.dispose);
      var generation = 1;
      final service = JournalExportService(
        local: local,
        nutrition: nutrition,
        water: FakeWaterRepository(),
        activity: FakeActivityRepository(),
        profile: FakeHealthProfileRepository(),
        currentUid: () => 'A',
        sessionVersion: () => generation,
      );
      final pending = service.export(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 19),
      );
      await Future<void>.delayed(Duration.zero);
      generation += 2;
      nutrition.rangePending!.complete();
      await expectLater(pending, throwsStateError);
      expect(local.picked, 0);
      expect(local.written, 0);
    },
  );

  testWidgets(
    'discard stays reachable after scrolling; disk failure preserves draft and retry removes only it',
    (tester) async {
      final local = FakePrivateLocalData();
      final nutrition = FakeNutritionRepository();
      final container = await pumpApp(
        tester,
        privateLocalData: local,
        nutritionRepository: nutrition,
        size: const Size(360, 844),
        textScale: 2,
        initialThemeMode: ThemeMode.dark,
      );
      final uid = FakeAuthRepository.testUser.uid;
      final store = container.read(mealDraftStoreProvider);
      await store.put(uid, saved('discard-test').copyForTestNow());
      await store.put('B', saved('b-private').copyForTestNow());
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('open-meal-drafts'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      final restore = find.byKey(const ValueKey('restore-draft-discard-test'));
      await tester.ensureVisible(restore);
      await tester.pumpAndSettle();
      await tester.tap(restore);
      await tester.pumpAndSettle();
      final scroll = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last;
      await tester.drag(scroll, const Offset(0, -1200));
      await tester.pumpAndSettle();
      final discard = find.byKey(const ValueKey('discard-local-draft'));
      expect(discard.hitTestable(), findsOneWidget);
      local.failWrite = true;
      await tester.tap(discard);
      await tester.pumpAndSettle();
      expect(find.text('Chưa xóa được nháp; hãy thử lại.'), findsOneWidget);
      expect((await store.list(uid)).single.operationId, 'discard-test');
      local.failWrite = false;
      await tester.tap(discard);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsNothing);
      expect(await store.list(uid), isEmpty);
      expect((await store.list('B')).single.operationId, 'b-private');
      expect(nutrition.addCalls, 0);
    },
  );

  testWidgets(
    'account deletion retains Auth and drafts on data/local cleanup failures; retry cleans only its UID',
    (tester) async {
      final local = FakePrivateLocalData();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final accountData = FakeAccountDataRepository();
      final container = await pumpApp(
        tester,
        repository: auth,
        privateLocalData: local,
        accountDataRepository: accountData,
      );
      final uid = FakeAuthRepository.testUser.uid;
      final store = container.read(mealDraftStoreProvider);
      await store.put(uid, saved('delete-retry').copyForTestNow());
      await store.put('B', saved('keep-b').copyForTestNow());
      accountData.failure = const AccountDataFailure();
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('password'),
        false,
      );
      expect((await store.list(uid)).single.operationId, 'delete-retry');
      expect(auth.deleteUserCalls, 0);
      accountData.failure = null;
      local.failClear = true;
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('password'),
        false,
      );
      expect(auth.deleteUserCalls, 0);
      expect(auth.currentUid, uid);
      expect(
        (container.read(accountSecurityControllerProvider).error
                as AccountActionFailure)
            .dataMayBeDeleted,
        true,
      );
      expect((await store.list(uid)).single.operationId, 'delete-retry');
      local.failClear = false;
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('password'),
        true,
      );
      expect(auth.deleteUserCalls, 1);
      expect(await local.read(uid), isNull);
      expect((await store.list('B')).single.operationId, 'keep-b');
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    for (final size in [360.0, 390.0, 412.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'export privacy consent and controls reachable ${size}px scale $scale $mode',
          (tester) async {
            await pumpApp(
              tester,
              size: Size(size, 844),
              textScale: scale,
              initialThemeMode: mode,
            );
            final context = tester.element(find.byType(Scaffold).first);
            unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => const JournalExportDialog(),
              ),
            );
            await tester.pumpAndSettle();
            final consent = find.byKey(const ValueKey('export-consent'));
            await tester.scrollUntilVisible(
              consent,
              220,
              scrollable: find.byType(Scrollable).last,
            );
            await Scrollable.ensureVisible(
              tester.element(consent),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await tester.tap(consent);
            await tester.pumpAndSettle();
            final button = find.byKey(const ValueKey('export-csv'));
            await tester.scrollUntilVisible(
              button,
              180,
              scrollable: find.byType(Scrollable).last,
            );
            await Scrollable.ensureVisible(
              tester.element(button),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(find.textContaining('hiện hỗ trợ Android'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

extension on SavedMealDraft {
  SavedMealDraft copyForTestNow() => SavedMealDraft(
    operationId: operationId,
    mealId: mealId,
    draft: draft,
    updatedAt: DateTime.now(),
  );
}
