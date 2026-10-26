import '../models/nutrition_models.dart';
import 'bundled_vietnamese_foods.dart';

/// Compatibility entry point backed by the versioned, sourced app asset.
Future<List<FoodCatalogItem>> getVietnamesePopularFoods() =>
    loadBundledVietnameseFoods();
