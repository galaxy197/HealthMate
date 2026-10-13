import '../models/water_log.dart';

abstract interface class WaterRepository {
  Stream<List<WaterLog>> watchLogs(String uid, String dateKey);

  Future<String> add({required String uid, required WaterLogDraft draft});

  Future<void> update({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  });

  Future<void> delete({required String uid, required String logId});
}
