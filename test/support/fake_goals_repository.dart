import 'dart:async';

import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/goals/data/goals_repository.dart';
import 'package:healthmate/features/goals/models/goal_failure.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';

class FakeGoalsRepository implements GoalsRepository {
  final Map<String, List<TrackingGoal>> goals = {};
  final Map<String, DailyQuest> quests = {};
  final _changes = StreamController<void>.broadcast();
  bool failSave = false;
  bool failLoad = false;
  int createQuestCalls = 0;
  int _sequence = 0;

  Stream<T> _stream<T>(T Function() read) => Stream.multi((c) {
    void emit() {
      if (failLoad) {
        c.addError(const GoalFailure());
      } else {
        c.add(read());
      }
    }

    emit();
    final sub = _changes.stream.listen((_) => emit());
    c.onCancel = sub.cancel;
  });
  @override
  Stream<List<TrackingGoal>> watchGoals(String uid) =>
      _stream(() => [...?goals[uid]]);
  @override
  Stream<DailyQuest?> watchQuest(String uid, String dateKey) =>
      _stream(() => quests['$uid/$dateKey']);
  @override
  Future<void> saveGoal(String uid, GoalDraft draft, {String? id}) async {
    if (failSave) throw const GoalFailure();
    final error = draft.validate();
    if (error != null) throw GoalFailure(error);
    final list = goals.putIfAbsent(uid, () => []);
    final goal = TrackingGoal(id: id ?? 'goal-${++_sequence}', draft: draft);
    list.removeWhere((g) => g.id == goal.id);
    list.add(goal);
    _changes.add(null);
  }

  @override
  Future<void> deleteGoal(String uid, String id) async {
    if (failSave) throw const GoalFailure();
    goals[uid]?.removeWhere((g) => g.id == id);
    _changes.add(null);
  }

  @override
  Future<void> ensureQuest(String uid, DailyQuest candidate) async {
    if (failSave) throw const GoalFailure();
    final key = '$uid/${candidate.dateKey}';
    if (!quests.containsKey(key)) {
      quests[key] = candidate;
      createQuestCalls++;
      _changes.add(null);
    }
  }

  @override
  Future<void> finishQuest(
    String uid,
    String dateKey,
    QuestStatus status,
  ) async {
    if (failSave) throw const GoalFailure();
    final key = '$uid/$dateKey';
    if (quests[key]?.status == QuestStatus.available) {
      quests[key] = quests[key]!.withStatus(status);
    }
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
