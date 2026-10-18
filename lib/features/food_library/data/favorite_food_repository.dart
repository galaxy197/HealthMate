import '../models/favorite_food.dart';

abstract interface class FavoriteFoodRepository {
  Stream<FavoriteFoodPage> watch(String uid, {int limit = 40});
  Future<void> setFavorite(
    String uid,
    String sourceId,
    bool selected, {
    FoodSourceKind sourceKind = FoodSourceKind.catalog,
  });
}
