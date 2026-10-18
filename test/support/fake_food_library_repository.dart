import 'dart:async';
import 'dart:convert';
import 'package:healthmate/features/food_library/data/food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';

class FakeFoodLibraryRepository implements FoodLibraryRepository {
  final byUid = <String, Map<String, LibraryEntry>>{};
  final _changes = StreamController<void>.broadcast();
  bool failRead = false,
      failWrite = false,
      fromCache = false,
      emitImmediately = true;
  Completer<void>? pending;
  Completer<LibraryEntry?>? loadPending;
  int _counter = 0,
      saveCalls = 0,
      deleteCalls = 0,
      watchCalls = 0,
      loadCalls = 0;
  final writtenUids = <String>[];
  final savedIds = <String>[];
  void seed(String uid, LibraryEntry entry) =>
      byUid.putIfAbsent(uid, () => {})['${entry.kind.name}:${entry.id}'] =
          entry;
  @override
  String newId() => 'library-${++_counter}';
  @override
  Stream<LibraryPage> watch(
    String uid,
    FoodSourceKind kind, {
    int limit = 40,
  }) => Stream.multi((controller) {
    watchCalls++;
    void emit() {
      if (failRead) {
        controller.addError(const FoodLibraryFailure());
        return;
      }
      controller.add(
        LibraryPage(
          items:
              byUid[uid]?.values
                  .where((entry) => entry.kind == kind)
                  .take(limit)
                  .toList() ??
              [],
          fromCache: fromCache,
        ),
      );
    }

    if (emitImmediately) emit();
    final sub = _changes.stream.listen((_) => emit());
    controller.onCancel = sub.cancel;
  });
  @override
  Future<LibraryEntry?> load(String uid, FoodSourceKind kind, String id) async {
    loadCalls++;
    if (loadPending != null) return loadPending!.future;
    if (failRead) throw const FoodLibraryFailure();
    return byUid[uid]?['${kind.name}:$id'];
  }

  @override
  Future<void> save(
    String uid,
    LibraryEntry entry, {
    required bool create,
  }) async {
    saveCalls++;
    writtenUids.add(uid);
    savedIds.add(entry.id);
    await pending?.future;
    if (failWrite) throw const FoodLibraryFailure();
    entry.validate();
    final previous = byUid[uid]?['${entry.kind.name}:${entry.id}'];
    if (create &&
        previous != null &&
        jsonEncode(previous.toData()) != jsonEncode(entry.toData())) {
      throw const FoodLibraryFailure('Thao tác trước đã lưu nội dung khác.');
    }
    if (!create && previous == null) {
      throw const FoodLibraryFailure('Món đã bị xóa.');
    }
    seed(uid, entry);
    _changes.add(null);
  }

  @override
  Future<void> delete(String uid, FoodSourceKind kind, String id) async {
    deleteCalls++;
    writtenUids.add(uid);
    await pending?.future;
    if (failWrite) throw const FoodLibraryFailure();
    byUid[uid]?.remove('${kind.name}:$id');
    _changes.add(null);
  }

  void refresh() => _changes.add(null);
  Future<void> dispose() => _changes.close();
}
