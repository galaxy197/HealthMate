import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/data/bounded_range.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'support/test_app.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_day_review_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_auth_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';

class DelayedOwnerMeals extends FakeNutritionRepository {
  final pending = Completer<List<MealLog>>();
  @override
  Future<List<MealLog>> loadRange(String uid, DateTime start, DateTime end) =>
      uid == 'test-uid' ? pending.future : Future.value([]);
}

MealLog meal(
  String id,
  DateTime day, {
  double kcal = 200,
  DateTime? updated,
  bool partial = false,
}) => MealLog(
  id: id,
  type: MealType.lunch,
  consumedAt: day,
  items: const [],
  totals: NutritionTotals(
    kcal: kcal,
    proteinKnown: !partial,
    carbsKnown: !partial,
    fatKnown: !partial,
  ),
  source: MealSource.manual,
  dateKey: localDateKey(day),
  updatedAt: updated ?? day,
);
Finder scroll() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

void main() {
  test(
    'late range data from A cannot replace the report after switching UID',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser),
          repo = DelayedOwnerMeals();
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          nutritionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      final session = c.listen(authSessionProvider, (_, _) {});
      addTearDown(session.close);
      await c.read(authSessionProvider.future);
      final range = ReportRange(DateTime(2026, 1, 4), 90),
          provider = periodMealsProvider(ReportRange(DateTime(2026, 1, 4), 90));
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
      expect(c.read(provider).isLoading, isTrue);
      auth.emitUser(const AuthUser(emailVerified: true, uid: 'b', email: 'b@example.com'));
      await pumpEventQueue();
      repo.pending.complete([meal('private-A', range.start)]);
      await pumpEventQueue();
      expect(c.read(provider).value, isEmpty);
    },
  );
  test('calendar bounds cross DST/year without using elapsed local hours', () {
    expect(
      calendarRangeDays(DateTime(2025, 12, 15), DateTime(2026, 3, 15)),
      90,
    );
    expect(calendarRangeDays(DateTime(2026, 3, 8), DateTime(2026, 3, 9)), 1);
    expect(
      () => calendarRangeDays(DateTime(2026), DateTime(2026, 4, 2)),
      throwsA(isA<RangeReadFailure>()),
    );
    expect(
      () => calendarRangeDays(DateTime(2026), DateTime(2026)),
      throwsA(isA<RangeReadFailure>()),
    );
  });
  test(
    'sparse, partial, unknown nutrient and explicit confirmation use correct denominators and revisions',
    () {
      final range = ReportRange(DateTime(2026, 1, 5), 7);
      final one = meal('a', DateTime(2025, 12, 30), kcal: 500, partial: true),
          two = meal('b', DateTime(2026, 1, 2), kcal: 1000);
      final review = DayReview(
        dateKey: '2025-12-30',
        complete: true,
        mealCount: 1,
        latestMealUpdate: latestMealRevision([one]),
      );
      final c = RecordingCoverage(
        range: range,
        today: DateTime(2026, 1, 3),
        meals: [one, one, two, meal('future', DateTime(2026, 1, 4))],
        reviews: [review],
      );
      expect(c.dates.length, 6);
      expect(c.recordedDays, 2);
      expect(c.confirmedRecordedDays, 1);
      expect(c.partialDays, 1);
      expect(c.unrecordedDays, 4);
      expect(c.confirmedAverageKcal, 500);
      expect(
        totalMealNutrition(c.logs(DateTime(2025, 12, 30))).hasCompleteMacros,
        isFalse,
      );
      expect(
        review.matches([
          meal('a', one.consumedAt, updated: DateTime(2026, 1, 1)),
        ]),
        isFalse,
      );
      expect(review.matches([]), isFalse);
      expect(review.matches([one, two]), isFalse);
      final empty = RecordingCoverage(
        range: range,
        today: DateTime(2026, 1, 3),
        meals: [],
        reviews: [
          const DayReview(
            dateKey: '2026-01-01',
            complete: true,
            mealCount: 0,
            latestMealUpdate: null,
          ),
        ],
      );
      expect(empty.confirmedAverageKcal, isNull);
      expect(empty.recordedDays, 0);
      final targets = [
        const NutritionTarget(
          effectiveFromDateKey: '2025-12-01',
          kcalTarget: 1800,
        ),
        const NutritionTarget(
          effectiveFromDateKey: '2026-01-01',
          kcalTarget: 2100,
        ),
      ];
      expect(targetForDate(targets, '2025-12-30')!.kcalTarget, 1800);
      expect(targetForDate(targets, '2026-01-02')!.kcalTarget, 2100);
    },
  );
  testWidgets(
    '30/90 days use bounded sources once; one source error does not hide verified kcal',
    (t) async {
      final now = DateTime(2026, 1, 3, 12),
          nutrition = FakeNutritionRepository(
            meals: [meal('one', DateTime(2025, 12, 30), kcal: 500)],
          ),
          water = FakeWaterRepository()..rangeError = StateError('QA failure');
      final reviews = FakeDayReviewRepository(),
          targets = FakeNutritionTargetRepository();
      final c = await pumpApp(
        t,
        dashboardNow: now,
        nutritionRepository: nutrition,
        waterRepository: water,
        dayReviewRepository: reviews,
        targetRepository: targets,
      );
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      final before = nutrition.rangeCalls;
      await t.tap(find.byKey(const ValueKey('report-window-30')));
      await t.pumpAndSettle();
      expect(find.text('500 kcal đã ghi'), findsOneWidget);
      expect(find.textContaining('1 ngày đang ghi'), findsOneWidget);
      expect(find.textContaining('Chưa tải được nước'), findsOneWidget);
      expect(nutrition.rangeCalls, before + 1);
      await t.tap(find.byKey(const ValueKey('report-window-90')));
      await t.pumpAndSettle();
      expect(nutrition.rangeCalls, before + 2);
      expect(targets.rangeCalls, greaterThanOrEqualTo(2));
      expect(reviews.loadCalls, 2);
      expect(t.takeException(), isNull);
    },
  );
  for (final (width, scale) in [(360.0, 1.0), (390.0, 1.5), (412.0, 2.0)]) {
    for (final mode in ThemeMode.values.where((m) => m != ThemeMode.system)) {
      testWidgets(
        'long report empty/details/keyboardless review $width $scale $mode',
        (t) async {
          final now = DateTime(2026, 1, 3, 12),
              repo = FakeDayReviewRepository();
          final nutrition = FakeNutritionRepository();
          final c = await pumpApp(
            t,
            size: Size(width, 844),
            textScale: scale,
            initialThemeMode: mode,
            dashboardNow: now,
            dayReviewRepository: repo,
            nutritionRepository: nutrition,
          );
          c.read(appRouterProvider).go(AppRoutes.progress);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('report-window-90')));
          await t.pumpAndSettle();
          expect(
            find.textContaining('Chưa ghi bữa ăn trong khoảng này'),
            findsOneWidget,
          );
          await nutrition.addMeal(
            uid: 'test-uid',
            draft: MealDraft(
              type: MealType.lunch,
              consumedAt: DateTime(2025, 12, 30),
              items: [
                MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100),
              ],
              source: MealSource.manual,
            ),
          );
          final refresh = find.byKey(const ValueKey('refresh-period'));
          await t.ensureVisible(refresh);
          await t.pumpAndSettle();
          await t.tap(refresh);
          await t.pumpAndSettle();
          expect(find.text('130 kcal đã ghi'), findsOneWidget);
          final details = find.byKey(const ValueKey('period-day-details'));
          await t.scrollUntilVisible(details, 220, scrollable: scroll());
          await t.pumpAndSettle();
          await t.tap(details);
          await t.pumpAndSettle();
          expect(find.text('Chi tiết từng ngày / xác nhận'), findsOneWidget);
          final prev = find.byKey(const ValueKey('previous-period'));
          await t.ensureVisible(prev);
          await t.pumpAndSettle();
          await t.tap(prev);
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('period-range')), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'day review failure/retry preserves logs and changes only current UID',
    (t) async {
      final repo = FakeDayReviewRepository()..failSave = true;
      final c = await pumpApp(
        t,
        dashboardNow: DateTime(2026, 1, 3),
        dayReviewRepository: repo,
      );
      c.read(journalDateProvider.notifier).select(DateTime(2026, 1, 3));
      c.read(appRouterProvider).go(AppRoutes.journal);
      await t.pumpAndSettle();
      final open = find.byKey(const ValueKey('open-day-review'));
      await t.scrollUntilVisible(open, 250, scrollable: scroll());
      await t.pumpAndSettle();
      await t.tap(open);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('confirm-day-review')));
      await t.pumpAndSettle();
      expect(find.textContaining('Chưa lưu được xác nhận'), findsOneWidget);
      repo.failSave = false;
      await t.tap(find.byKey(const ValueKey('confirm-day-review')));
      await t.pumpAndSettle();
      expect(repo.saveCalls, 2);
      expect(repo.byUid.keys, ['test-uid']);
      expect(repo.byUid['test-uid']!['2026-01-03']!.complete, isTrue);
      c.invalidate(dayReviewsProvider);
    },
  );
}
