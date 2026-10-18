import '../../../core/utils/subscription_stream.dart';
import '../../../core/errors/operation_diagnostics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../activity/providers/activity_providers.dart';
import '../../activity/models/activity_log.dart';
import '../../auth/providers/auth_providers.dart';
import '../../daily_quest/domain/quest_engine.dart';
import '../../daily_quest/models/daily_quest.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/providers/water_providers.dart';
import '../../water/models/water_log.dart';
import '../data/firebase_goals_repository.dart';
import '../data/goals_repository.dart';
import '../models/goal_failure.dart';
import '../models/tracking_goal.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => FirebaseGoalsRepository(FirebaseFirestore.instance),
);

final goalsClockProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(localClockProvider),
);

final goalsTodayProvider = Provider.autoDispose<DateTime>(
  (ref) => localDateOnly(ref.watch(goalsClockProvider)),
);

final goalsProvider = StreamProvider.autoDispose<List<TrackingGoal>>((ref) {
  final user = ref.watch(authSessionProvider).value;
  return user == null
      ? Stream.value(const [])
      : subscriptionStream(
          ref.watch(goalsRepositoryProvider).watchGoals(user.uid),
        );
}, retry: (_, _) => null);

final dailyQuestProvider = StreamProvider.autoDispose
    .family<DailyQuest?, String>((ref, key) {
      final user = ref.watch(authSessionProvider).value;
      return user == null
          ? Stream.value(null)
          : subscriptionStream(
              ref.watch(goalsRepositoryProvider).watchQuest(user.uid, key),
            );
    }, retry: (_, _) => null);

// Read the current quest first. A saved quest needs no regeneration, even when
// goals/logs change. Dependency reads below only run once per setup attempt.
final questSetupProvider = FutureProvider.autoDispose.family<void, DateTime>((
  ref,
  day,
) async {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) return;
  final repository = ref.watch(goalsRepositoryProvider);
  final key = localDateKey(day);
  GoalFailure? firstFailure;
  Future<T> load<T>(String stage, Future<T> source) async {
    final clock = Stopwatch()..start();
    operationDiagnostic('quest', stage, 'start', clock);
    try {
      final result = await source.timeout(const Duration(seconds: 15));
      operationDiagnostic('quest', stage, 'success', clock);
      return result;
    } catch (error) {
      final failure = GoalFailure.at(error, stage);
      firstFailure ??= failure;
      operationDiagnostic('quest', stage, 'error', clock, code: failure.code);
      throw failure;
    }
  }

  final existing = await load(
    'quest-read',
    ref.watch(dailyQuestProvider(key).future),
  );
  if (existing != null || !ref.mounted) return;
  try {
    final sources = await (
      load('goals-read', ref.watch(goalsProvider.future)),
      load('meals-read', ref.watch(mealLogsProvider(day).future)),
      load('water-read', ref.watch(waterLogsProvider(key).future)),
      load('activity-read', ref.watch(activityLogsProvider(key).future)),
    ).wait;
    if (!ref.mounted) return;
    await repository.ensureQuest(
      user.uid,
      suggestQuest(
        day: day,
        goals: sources.$1,
        mealCount: sources.$2.length,
        waterMl: totalWaterMl(sources.$3),
        activityMinutes: totalActivityMinutes(sources.$4),
      ),
    );
  } catch (error) {
    throw firstFailure ??
        (error is GoalFailure ? error : GoalFailure.at(error, 'quest-create'));
  }
}, retry: (_, _) => null);

final goalActionsProvider = NotifierProvider<GoalActions, AsyncValue<void>>(
  GoalActions.new,
);

class GoalActions extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> save(GoalDraft draft, {String? id, bool create = false}) =>
      _perform(
        (repo, uid) => repo.saveGoal(uid, draft, id: id, create: create),
      );
  Future<bool> delete(String id) =>
      _perform((repo, uid) => repo.deleteGoal(uid, id));
  Future<bool> finish(String key, QuestStatus status) =>
      _perform((repo, uid) => repo.finishQuest(uid, key, status));

  Future<bool> _perform(
    Future<void> Function(GoalsRepository, String) action,
  ) async {
    if (state.isLoading) return false;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    final repository = ref.read(goalsRepositoryProvider);
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        _generation == generation &&
        ref.read(authSessionProvider).value?.uid == uid;
    state = const AsyncLoading();
    try {
      await action(repository, uid);
      if (current()) {
        state = const AsyncData(null);
      }
      return current();
    } catch (e, stack) {
      if (current()) {
        state = AsyncError(e is GoalFailure ? e : const GoalFailure(), stack);
      }
      return false;
    }
  }
}
