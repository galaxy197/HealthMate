import 'dart:async';
import 'package:healthmate/features/nutrition_targets/data/nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';

class FakeNutritionTargetRepository implements NutritionTargetRepository {
  final byUid = <String, Map<String, NutritionTarget>>{};
  bool failRead = false;
  bool failSave = false;
  Completer<void>? pendingRead;
  Completer<void>? pendingSave;
  int readCalls = 0;
  int saveCalls = 0;
  final savedUids = <String>[];
  @override
  Future<NutritionTarget?> loadForDay(String uid, String dateKey) async {
    readCalls++;
    await pendingRead?.future;
    if (failRead) throw const NutritionTargetFailure();
    return targetForDate(byUid[uid]?.values ?? [], dateKey);
  }

  int rangeCalls = 0;
  @override
  Future<List<NutritionTarget>> loadForRange(
    String uid,
    String startKey,
    String endKey,
  ) async {
    rangeCalls++;
    await pendingRead?.future;
    if (failRead) throw const NutritionTargetFailure();
    final versions = byUid[uid]?.values ?? <NutritionTarget>[];
    final base = targetForDate(versions, startKey);
    return [
      ?base,
      ...versions.where(
        (t) =>
            t.effectiveFromDateKey.compareTo(startKey) > 0 &&
            t.effectiveFromDateKey.compareTo(endKey) < 0,
      ),
    ];
  }

  @override
  Future<void> save(String uid, NutritionTarget target) async {
    saveCalls++;
    savedUids.add(uid);
    await pendingSave?.future;
    if (failSave) throw const NutritionTargetFailure('Lỗi lưu kiểm thử.');
    byUid.putIfAbsent(uid, () => {})[target.effectiveFromDateKey] = target;
  }
}
