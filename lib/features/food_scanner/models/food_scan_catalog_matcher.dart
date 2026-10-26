import '../../nutrition/models/food_catalog_search.dart';
import '../../nutrition/models/nutrition_models.dart';

/// A component or AI search keyword cannot stand in for the entire plate.
/// Broad food search remains available in the manual meal flow.
abstract final class FoodScanCatalogMatcher {
  static List<FoodCatalogItem> matches(
    String dishName,
    Iterable<FoodCatalogItem> catalog,
  ) {
    final query = normalizeFoodSearch(dishName);
    if (query.isEmpty) return const [];
    final byId = <String, FoodCatalogItem>{};
    for (final food in catalog) {
      if ([
        food.name,
        ...food.alternateNames,
      ].any((name) => normalizeFoodSearch(name) == query)) {
        byId[food.id] = food;
      }
    }
    return byId.values.toList(growable: false);
  }
}
