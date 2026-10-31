import '../models/nutrition_models.dart';

/// Public food cache only; private foods remain scoped to their Firestore UID.
abstract interface class FoodSearchCache {
  Future<List<FoodCatalogItem>> searchFoods(
    String query, {
    int limit = 25,
    FoodDataSource? filterSource,
  });
  Future<FoodCatalogItem?> getFoodById(String id);
  Future<void> cacheFood(FoodCatalogItem food);
  Future<void> markFoodUsed(String id);
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20});
  Future<void> cleanOldCache();
  Future<Map<String, int>> getCacheStats();
}
