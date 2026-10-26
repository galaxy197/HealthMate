import 'package:flutter/foundation.dart';
import '../models/nutrition_models.dart';
import '../models/food_catalog_search.dart';
import 'food_local_database.dart';
import 'usda_api_service.dart';

/// Result with data source tracking for UI badges
class FoodSearchResult {
  const FoodSearchResult({required this.food, required this.source});

  final FoodCatalogItem food;
  final FoodResultSource source;
}

enum FoodResultSource {
  firestore, // Original 158-item catalog from Firestore
  cache, // SQLite cached USDA results
  usdaApi, // Fresh USDA API results
  user; // User-created foods

  String get displayLabel => switch (this) {
    FoodResultSource.firestore => 'Danh mục local',
    FoodResultSource.cache => 'Đã lưu',
    FoodResultSource.usdaApi => 'USDA',
    FoodResultSource.user => 'Của bạn',
  };
}

/// Unified search across Firestore catalog + SQLite cache + USDA API
/// Priority: Firestore local catalog > SQLite cache > USDA API
class UnifiedFoodSearchService {
  UnifiedFoodSearchService({
    required this.localDatabase,
    required this.usdaService,
  });

  final FoodLocalDatabase localDatabase;
  final UsdaApiService usdaService;

  /// Search strategy:
  /// 1. Search Firestore catalog (passed in) with Vietnamese normalization
  /// 2. If < 10 results, search SQLite cache
  /// 3. If still < 10 results, query USDA API and cache results
  Future<List<FoodSearchResult>> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = <FoodSearchResult>[];
    final seenIds = <String>{};

    // Step 1: Search Firestore catalog (Vietnamese-aware)
    final firestoreResults = searchFoodCatalog(
      firestoreCatalog,
      query,
    ).take(limit).toList();

    for (final food in firestoreResults) {
      if (seenIds.add(food.id)) {
        results.add(
          FoodSearchResult(
            food: food,
            source: food.dataSource == FoodDataSource.user
                ? FoodResultSource.user
                : FoodResultSource.firestore,
          ),
        );
      }
    }

    // Early return if we have enough results
    if (results.length >= 10) {
      return results.take(limit).toList();
    }

    // Step 2: Search SQLite cache
    try {
      final cacheResults = await localDatabase.searchFoods(
        query,
        limit: limit - results.length,
      );

      for (final food in cacheResults) {
        if (seenIds.add(food.id)) {
          results.add(
            FoodSearchResult(food: food, source: FoodResultSource.cache),
          );
        }
      }
    } catch (_) {
      // Cache failure shouldn't block search
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH cache-read failed');
    }

    // Early return if we have enough results
    if (results.length >= 10) {
      return results.take(limit).toList();
    }

    // Step 3: Query USDA API if still need more results
    try {
      final usdaResults = await usdaService.searchFoods(
        query,
        pageSize: limit - results.length,
      );

      // Convert search results to full FoodCatalogItem and cache
      final foodsToCache = <FoodCatalogItem>[];

      for (final result in usdaResults) {
        // Get detailed nutrition info
        final food = await usdaService.getFoodDetail(result.fdcId);
        if (food != null && seenIds.add(food.id)) {
          results.add(
            FoodSearchResult(food: food, source: FoodResultSource.usdaApi),
          );
          foodsToCache.add(food);
        }
      }

      // Cache USDA results for future searches
      if (foodsToCache.isNotEmpty) {
        await localDatabase.cacheFoodsBatch(foodsToCache);
      }
    } catch (_) {
      // API failure shouldn't crash the app
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH provider failed');
    }

    return results.take(limit).toList();
  }

  /// Get food by ID from any source
  Future<FoodCatalogItem?> getFoodById(
    String id, {
    required List<FoodCatalogItem> firestoreCatalog,
  }) async {
    // Try Firestore first
    final firestoreFood = firestoreCatalog.where((f) => f.id == id).firstOrNull;
    if (firestoreFood != null) return firestoreFood;

    // Try SQLite cache
    final cachedFood = await localDatabase.getFoodById(id);
    if (cachedFood != null) return cachedFood;

    // Try parsing USDA ID format: usda_{fdcId}
    if (id.startsWith('usda_')) {
      final fdcIdStr = id.substring(5);
      final fdcId = int.tryParse(fdcIdStr);
      if (fdcId != null) {
        final usdaFood = await usdaService.getFoodDetail(fdcId);
        if (usdaFood != null) {
          await localDatabase.cacheFood(usdaFood);
          return usdaFood;
        }
      }
    }

    return null;
  }

  /// Mark food as recently used
  Future<void> markFoodUsed(String foodId) async {
    try {
      await localDatabase.markFoodUsed(foodId);
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH recent-write failed');
    }
  }

  /// Get recently used foods for quick access
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20}) async {
    try {
      return await localDatabase.getRecentFoods(limit: limit);
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH recent-read failed');
      return [];
    }
  }

  /// Clean old cache entries
  Future<void> cleanOldCache() async {
    try {
      await localDatabase.cleanOldCache();
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH cache-clean failed');
    }
  }

  /// Get cache statistics for debugging/settings
  Future<Map<String, int>> getCacheStats() async {
    try {
      return await localDatabase.getCacheStats();
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH cache-stats failed');
      return {'total': 0, 'usda': 0, 'local': 0, 'user': 0};
    }
  }
}
