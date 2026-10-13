import '../models/activity_log.dart';

abstract interface class ActivityRepository {
  Stream<List<ActivityLog>> watchLogs(String uid, String dateKey);

  Future<String> add({required String uid, required ActivityLogDraft draft});

  Future<void> update({
    required String uid,
    required String logId,
    required ActivityLogDraft draft,
  });

  Future<void> delete({required String uid, required String logId});
}
