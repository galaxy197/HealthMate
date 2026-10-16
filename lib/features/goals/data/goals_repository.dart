import '../../daily_quest/models/daily_quest.dart';
import '../models/tracking_goal.dart';

abstract interface class GoalsRepository {
  Stream<List<TrackingGoal>> watchGoals(String uid);
  Future<void> saveGoal(String uid, GoalDraft draft, {String? id});
  Future<void> deleteGoal(String uid, String id);
  Stream<DailyQuest?> watchQuest(String uid, String dateKey);
  Future<void> ensureQuest(String uid, DailyQuest candidate);
  Future<void> finishQuest(String uid, String dateKey, QuestStatus status);
}
