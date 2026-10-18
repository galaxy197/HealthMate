import 'dart:async';
import 'package:healthmate/features/food_library/data/favorite_food_repository.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';

class FakeFavoriteFoodRepository implements FavoriteFoodRepository {
  final byUid = <String, Map<String, FavoriteFood>>{};
  final _changes = StreamController<void>.broadcast();
  bool failRead = false, failWrite = false, fromCache = false;
  Completer<void>? pending;
  int calls = 0, watchCalls = 0;
  final writtenUids = <String>[];
  @override
  Stream<FavoriteFoodPage> watch(String uid, {int limit = 40}) =>
      Stream.multi((controller) {
        watchCalls++;
        void emit() {
          if (failRead) {
            controller.addError(const FavoriteFoodFailure());
            return;
          }
          controller.add(
            FavoriteFoodPage(
              items: byUid[uid]?.values.take(limit).toList() ?? [],
              fromCache: fromCache,
            ),
          );
        }

        emit();
        final sub = _changes.stream.listen((_) => emit());
        controller.onCancel = sub.cancel;
      });
  @override
  Future<void> setFavorite(
    String uid,
    String sourceId,
    bool selected, {
    FoodSourceKind sourceKind = FoodSourceKind.catalog,
  }) async {
    calls++;
    writtenUids.add(uid);
    await pending?.future;
    if (failWrite) throw const FavoriteFoodFailure();
    final items = byUid.putIfAbsent(uid, () => {});
    if (selected) {
      items[favoriteFoodId(sourceId, sourceKind: sourceKind)] = FavoriteFood(
        sourceId: sourceId,
        sourceKind: sourceKind,
      );
    } else {
      items.remove(favoriteFoodId(sourceId, sourceKind: sourceKind));
    }
    _changes.add(null);
  }

  void refresh() => _changes.add(null);
  Future<void> dispose() => _changes.close();
}
