import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:healthmate/core/errors/operation_diagnostics.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/goals/models/goal_failure.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';
import 'support/test_app.dart';
import 'support/fake_goals_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';

class _Goals extends FakeGoalsRepository {
  bool reject = false;
  @override
  Stream<List<TrackingGoal>> watchGoals(String uid) => reject
      ? Stream.error(GoalFailure.detail('goals-read', 'permission-denied'))
      : super.watchGoals(uid);
}

class _Meals extends FakeNutritionRepository {
  bool reject = false;
  @override
  Stream<List<MealLog>> watchMealLogs(String uid, DateTime day) => reject
      ? Stream.error(
          const NutritionFailure('fixture', code: 'permission-denied'),
        )
      : super.watchMealLogs(uid, day);
}

class _Water extends FakeWaterRepository {
  bool reject = false;
  @override
  Stream<List<WaterLog>> watchLogs(String uid, String day) => reject
      ? Stream.error(
          const DailyLogFailure('fixture', code: 'permission-denied'),
        )
      : super.watchLogs(uid, day);
}

class _Activity extends FakeActivityRepository {
  bool reject = false;
  @override
  Stream<List<ActivityLog>> watchLogs(String uid, String day) => reject
      ? Stream.error(
          const DailyLogFailure('fixture', code: 'permission-denied'),
        )
      : super.watchLogs(uid, day);
}

void main() {
  test(
    'diagnostic failures expose stage/code without raw private exception text',
    () {
      const raw = NutritionFailure(
        'private UID / meal contents must not escape',
        code: 'permission-denied',
      );
      final failure = GoalFailure.at(raw, 'meals-read');
      expect(failure.code, 'permission-denied');
      expect(failure.stage, 'meals-read');
      expect(failure.message, contains('Tải bữa ăn'));
      expect(failure.message, contains('Rules'));
      expect(failure.message, isNot(contains('private UID')));
      expect(
        diagnosticErrorCode(TimeoutException('private request')),
        'timeout',
      );
      expect(diagnosticErrorCode(Exception('429 private response')), 'quota');
    },
  );
  for (final stage in [
    'goals-read',
    'meals-read',
    'water-read',
    'activity-read',
  ]) {
    testWidgets(
      'F03 reports $stage and actual retry reloads that source without inventing data',
      (tester) async {
        final goals = _Goals()..reject = stage == 'goals-read';
        final meals = _Meals()..reject = stage == 'meals-read';
        final water = _Water()..reject = stage == 'water-read';
        final activity = _Activity()..reject = stage == 'activity-read';
        final day = DateTime(2026, 10, 17);
        final c = await pumpApp(
          tester,
          goalsRepository: goals,
          nutritionRepository: meals,
          waterRepository: water,
          activityRepository: activity,
          dashboardNow: day,
        );
        c.read(appRouterProvider).go(AppRoutes.quest);
        await tester.pumpAndSettle();
        final failure = c.read(questSetupProvider(day)).error;
        expect(failure, isA<GoalFailure>());
        expect((failure as GoalFailure).stage, stage);
        expect(failure.code, 'permission-denied');
        expect(goals.createQuestCalls, 0);
        goals.reject = false;
        meals.reject = false;
        water.reject = false;
        activity.reject = false;
        final retry = find.text('Thử lại').first;
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(c.read(questSetupProvider(day)).hasError, isFalse);
        expect(goals.createQuestCalls, 1);
        c.invalidate(questSetupProvider(day));
        await tester.pumpAndSettle();
        expect(goals.createQuestCalls, 1);
      },
    );
  }
}
