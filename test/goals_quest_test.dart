import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/daily_quest/domain/quest_engine.dart';
import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_goals_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

final today = DateTime(2026, 10, 16);
GoalDraft draft(
  GoalType type,
  double target, {
  double? baseline,
  GoalStatus status = GoalStatus.active,
}) => GoalDraft(
  type: type,
  targetValue: target,
  startDate: today,
  endDate: DateTime(2026, 11, 16),
  baselineWeightKg: baseline,
  status: status,
);
TrackingGoal goal(
  String id,
  GoalType type,
  double target, {
  double? baseline,
  GoalStatus status = GoalStatus.active,
}) => TrackingGoal(
  id: id,
  draft: draft(type, target, baseline: baseline, status: status),
);
BodyMetric metric(double weight, DateTime date) => BodyMetric(
  id: 'm',
  weightKg: weight,
  measuredAt: date,
  note: '',
  createdAt: date,
  updatedAt: date,
);

void main() {
  testWidgets(
    'production day clock cancels its timer when its container closes',
    (tester) async {
      final container = ProviderContainer();
      final subscription = container.listen(goalsClockProvider, (_, _) {});
      expect(container.read(goalsClockProvider), isA<DateTime>());
      subscription.close();
      container.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'goal validation rejects nonfinite, bounds, fractions and reversed dates',
    () {
      for (final type in GoalType.values) {
        expect(draft(type, double.nan).validate(), isNotNull);
        expect(draft(type, double.infinity).validate(), isNotNull);
        expect(draft(type, 0).validate(), isNotNull);
        expect(draft(type, type.max + 1).validate(), isNotNull);
      }
      expect(draft(GoalType.meals, 2.5).validate(), isNotNull);
      expect(draft(GoalType.water, 1200).validate(), isNull);
      expect(draft(GoalType.weight, 65).validate(), isNotNull);
      expect(draft(GoalType.weight, 65, baseline: 70).validate(), isNull);
      expect(
        GoalDraft(
          type: GoalType.meals,
          targetValue: 2,
          startDate: today,
          endDate: DateTime(2026, 10, 15),
        ).validate(),
        isNotNull,
      );
    },
  );

  test(
    'daily progress resets, excludes other days, caps fractions and respects term',
    () {
      final g = goal('water', GoalType.water, 500);
      final logs = [
        WaterLog(
          id: '1',
          amountMl: 750,
          consumedAt: today,
          dateKey: '2026-10-16',
          timezoneOffsetMinutes: 420,
        ),
        WaterLog(
          id: '2',
          amountMl: 2000,
          consumedAt: DateTime(2026, 10, 15),
          dateKey: '2026-10-15',
          timezoneOffsetMinutes: 420,
        ),
      ];
      GoalProgress progress(DateTime day) => goalProgress(
        g,
        day,
        meals: [],
        water: logs,
        activities: [],
        metrics: [],
      );
      expect(progress(today).value, 750);
      expect(progress(today).fraction, 1);
      expect(progress(DateTime(2026, 10, 17)).value, 0);
      expect(progress(DateTime(2026, 10, 15)).fraction, isNull);
      expect(progress(DateTime(2026, 11, 17)).label, 'Đã hết thời hạn');
    },
  );

  test(
    'weight progress uses direction and baseline, ignores old/future metrics',
    () {
      GoalProgress progress(TrackingGoal g, List<BodyMetric> data) =>
          goalProgress(
            g,
            today,
            meals: [],
            water: [],
            activities: [],
            metrics: data,
          );
      final data = [
        metric(67.5, today),
        metric(20, DateTime(2026, 10, 17)),
        metric(99, DateTime(2026, 10, 15)),
      ];
      expect(
        progress(
          goal('loss', GoalType.weight, 65, baseline: 70),
          data,
        ).fraction,
        0.5,
      );
      expect(
        progress(goal('gain', GoalType.weight, 75, baseline: 65), [
          metric(70, today),
        ]).fraction,
        0.5,
      );
      expect(
        progress(goal('away', GoalType.weight, 65, baseline: 70), [
          metric(72, today),
        ]).fraction,
        0,
      );
      expect(
        progress(goal('same', GoalType.weight, 70, baseline: 70), [
          metric(70, today),
        ]).fraction,
        1,
      );
      expect(
        progress(goal('empty', GoalType.weight, 65, baseline: 70), []).fraction,
        isNull,
      );
    },
  );

  test(
    'meal progress counts logged meals and activity counts recorded minutes',
    () {
      final meals = [
        MealLog(
          id: 'meal',
          type: MealType.lunch,
          consumedAt: today,
          items: [],
          totals: const NutritionTotals(),
          source: MealSource.manual,
          dateKey: '2026-10-16',
        ),
      ];
      final activities = [
        ActivityLog(
          id: 'walk',
          type: ActivityType.walking,
          durationMinutes: 15,
          performedAt: today,
          dateKey: '2026-10-16',
          timezoneOffsetMinutes: 420,
          note: '',
        ),
      ];
      final mealProgress = goalProgress(
        goal('m', GoalType.meals, 3),
        today,
        meals: meals,
        water: [],
        activities: activities,
        metrics: [],
      );
      final activityProgress = goalProgress(
        goal('a', GoalType.activity, 30),
        today,
        meals: meals,
        water: [],
        activities: activities,
        metrics: [],
      );
      expect(mealProgress.value, 1);
      expect(mealProgress.fraction, closeTo(1 / 3, 0.0001));
      expect(activityProgress.value, 15);
      expect(activityProgress.fraction, 0.5);
    },
  );

  test(
    'quest rules are deterministic and water/activity require explicit active goals',
    () {
      DailyQuest suggest(
        List<TrackingGoal> goals, {
        int meals = 0,
        int water = 0,
        int activity = 0,
        DateTime? day,
      }) => suggestQuest(
        day: day ?? today,
        goals: goals,
        mealCount: meals,
        waterMl: water,
        activityMinutes: activity,
      );
      expect(suggest([]).type, QuestType.meal);
      expect(suggest([], meals: 1).type, QuestType.reflection);
      expect(suggest([goal('w', GoalType.water, 1000)]).type, QuestType.water);
      expect(
        suggest([goal('w', GoalType.water, 1000)], water: 990).targetValue,
        10,
      );
      expect(suggest([goal('a', GoalType.activity, 7)]).targetValue, 7);
      expect(
        suggest([
          goal('w', GoalType.water, 1000, status: GoalStatus.paused),
        ], meals: 1).type,
        QuestType.reflection,
      );
      final goals = [
        goal('a', GoalType.activity, 10),
        goal('w', GoalType.water, 1500),
        goal('m', GoalType.meals, 3),
      ];
      expect(suggest(goals).type, suggest(goals.reversed.toList()).type);
      expect(
        suggest(goals, day: DateTime(2026, 11, 17), meals: 1).type,
        QuestType.reflection,
      );
      expect(suggest(goals).reason, contains('chưa đủ số bữa'));
    },
  );

  test(
    'repository contract preserves same-day terminal state and separates UID/day',
    () async {
      final repo = FakeGoalsRepository();
      addTearDown(repo.dispose);
      final q = suggestQuest(
        day: today,
        goals: [],
        mealCount: 0,
        waterMl: 0,
        activityMinutes: 0,
      );
      await repo.ensureQuest('alice', q);
      await repo.finishQuest('alice', q.dateKey, QuestStatus.skipped);
      await repo.ensureQuest('alice', q);
      expect(repo.quests['alice/2026-10-16']!.status, QuestStatus.skipped);
      expect(repo.createQuestCalls, 1);
      await repo.ensureQuest('bob', q);
      await repo.ensureQuest(
        'alice',
        suggestQuest(
          day: DateTime(2026, 10, 17),
          goals: [],
          mealCount: 0,
          waterMl: 0,
          activityMinutes: 0,
        ),
      );
      expect(repo.quests.length, 3);
      expect(await repo.watchGoals('bob').first, isEmpty);
    },
  );

  testWidgets(
    'goal save error retains input, retry saves and edit/delete work',
    (tester) async {
      final repo = FakeGoalsRepository();
      final container = await pumpApp(
        tester,
        goalsRepository: repo,
        dashboardNow: today,
      );
      container.read(appRouterProvider).go(AppRoutes.quest);
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('add-goal'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Giá trị cần nằm'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('goal-target')), '3');
      repo.failSave = true;
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Thông tin bạn nhập vẫn được giữ'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('goal-target')))
            .controller!
            .text,
        '3',
      );
      repo.failSave = false;
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(repo.goals['test-uid']!.single.draft.targetValue, 3);
      await tester.ensureVisible(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('goal-target')), '4');
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(repo.goals['test-uid']!.single.draft.targetValue, 4);
      await tester.ensureVisible(find.text('Xóa mục tiêu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa mục tiêu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(repo.goals['test-uid'], isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in [QuestStatus.completed, QuestStatus.skipped]) {
    testWidgets(
      'quest $status survives revisit and next day gets a new document',
      (tester) async {
        final repo = FakeGoalsRepository();
        var clock = today;
        final container = await pumpApp(
          tester,
          goalsRepository: repo,
          dashboardNow: today,
          goalsNow: () => clock,
          textScale: 1.5,
        );
        container.read(appRouterProvider).go(AppRoutes.quest);
        await tester.pumpAndSettle();
        final button = find.byKey(
          ValueKey(
            status == QuestStatus.completed ? 'complete-quest' : 'skip-quest',
          ),
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(repo.quests['test-uid/2026-10-16']!.status, status);
        container.read(appRouterProvider).go(AppRoutes.profile);
        await tester.pumpAndSettle();
        container.read(appRouterProvider).go(AppRoutes.quest);
        await tester.pumpAndSettle();
        expect(repo.createQuestCalls, 1);
        expect(find.byKey(const ValueKey('complete-quest')), findsNothing);
        clock = DateTime(2026, 10, 17);
        container.invalidate(goalsClockProvider);
        await tester.pumpAndSettle();
        expect(
          repo.quests['test-uid/2026-10-17']!.status,
          QuestStatus.available,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('loading journal never creates a quest from assumed zeroes', (
    tester,
  ) async {
    final repo = FakeGoalsRepository();
    final nutrition = FakeNutritionRepository(emitImmediately: false);
    final container = await pumpApp(
      tester,
      goalsRepository: repo,
      nutritionRepository: nutrition,
      dashboardNow: today,
    );
    container.read(appRouterProvider).go(AppRoutes.quest);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.quests, isEmpty);
    nutrition.emitPending();
    await tester.pumpAndSettle();
    expect(repo.quests.length, 1);
  });

  testWidgets('read errors are visible and generation can be retried', (
    tester,
  ) async {
    final repo = FakeGoalsRepository()..failLoad = true;
    final container = await pumpApp(
      tester,
      goalsRepository: repo,
      dashboardNow: today,
    );
    container.read(appRouterProvider).go(AppRoutes.quest);
    await tester.pumpAndSettle();
    expect(repo.quests, isEmpty);
    expect(
      find.textContaining('Chưa thể tải hoặc tạo nhiệm vụ'),
      findsOneWidget,
    );
    repo.failLoad = false;
    container.invalidate(goalsProvider);
    container.invalidate(dailyQuestProvider('2026-10-16'));
    container.invalidate(questSetupProvider(today));
    await tester.pumpAndSettle();
    expect(repo.quests.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal form fits a small phone with larger text and keyboard', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      dashboardNow: today,
      size: const Size(320, 640),
      textScale: 1.5,
    );
    container.read(appRouterProvider).go(AppRoutes.quest);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-goal')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-goal')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
