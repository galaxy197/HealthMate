import 'dart:async';

import 'package:healthmate/features/water/data/water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';

class FakeWaterRepository implements WaterRepository {
  FakeWaterRepository({List<WaterLog>? logs}) : _logs = [...?logs];

  final List<WaterLog> _logs;
  final _changes = StreamController<void>.broadcast();
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Stream<List<WaterLog>> watchLogs(String uid, String dateKey) =>
      Stream.multi((controller) {
        void emit() => controller.add(_forDate(dateKey));
        emit();
        final subscription = _changes.stream.listen((_) => emit());
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<String> add({
    required String uid,
    required WaterLogDraft draft,
  }) async {
    addCalls++;
    final id = 'water-$addCalls';
    _logs.add(_toLog(id, draft));
    _changes.add(null);
    return id;
  }

  @override
  Future<void> update({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) async {
    updateCalls++;
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index >= 0) _logs[index] = _toLog(logId, draft);
    _changes.add(null);
  }

  @override
  Future<void> delete({required String uid, required String logId}) async {
    deleteCalls++;
    _logs.removeWhere((log) => log.id == logId);
    _changes.add(null);
  }

  List<WaterLog> _forDate(String dateKey) =>
      _logs.where((log) => log.dateKey == dateKey).toList()
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

  WaterLog _toLog(String id, WaterLogDraft draft) => WaterLog(
    id: id,
    amountMl: draft.amountMl,
    consumedAt: draft.consumedAt,
    dateKey: draft.dateKey,
    timezoneOffsetMinutes: draft.timezoneOffsetMinutes,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<void> dispose() => _changes.close();
}
