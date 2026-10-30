import 'nutrition_models.dart';

/// Preserve curated Vietnamese discovery; prefer current USDA references over
/// historical USDA rows for equally relevant matches. Never remap old IDs.
int compareCatalogFoods(FoodCatalogItem a, FoodCatalogItem b) {
  int group(String id) {
    if (id.startsWith('usda-foundation-')) return 1;
    if (id.startsWith('usda-fndds-')) return 2;
    if (id.startsWith('usda-sr-')) return 3;
    return 0;
  }

  final priority = group(a.id).compareTo(group(b.id));
  if (priority != 0) return priority;
  final name = a.name.compareTo(b.name);
  return name != 0 ? name : a.id.compareTo(b.id);
}

// Catalog objects are immutable for the lifetime of a snapshot. A weak index
// avoids normalizing thousands of names again on each keystroke and releases
// old entries when a Firestore snapshot is replaced.
final _foodSearchIndex = Expando<List<(String, Set<String>)>>();

List<(String, Set<String>)> _searchTerms(FoodCatalogItem food) =>
    _foodSearchIndex[food] ??= [
      for (final raw in [food.name, ?food.originalName, ...food.alternateNames])
        _normalizedTerm(raw),
    ];

(String, Set<String>) _normalizedTerm(String raw) {
  final text = normalizeFoodSearch(raw);
  return (text, text.split(' ').toSet());
}

/// Search Vietnamese names with or without tone marks, including keyboard NFD.
String normalizeFoodSearch(String text) {
  var value = text.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    value = value.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  return value
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<FoodCatalogItem> searchFoodCatalog(
  List<FoodCatalogItem> catalog,
  String query,
) {
  final normalized = normalizeFoodSearch(query);
  if (normalized.isEmpty) return catalog;
  final words = normalized.split(' ');
  int score(FoodCatalogItem food) {
    var best = 99;
    for (final (name, tokens) in _searchTerms(food)) {
      final rank = name == normalized
          ? 0
          : name.startsWith('$normalized ')
          ? 1
          : words.every(tokens.contains)
          ? 2
          : name.contains(normalized)
          ? 3
          : 99;
      if (rank < best) best = rank;
    }
    return best;
  }

  final ranked =
      [for (final pair in catalog.indexed) (pair.$1, pair.$2, score(pair.$2))]
        ..removeWhere((r) => r.$3 == 99)
        ..sort((a, b) {
          final rank = a.$3.compareTo(b.$3);
          return rank != 0 ? rank : a.$1.compareTo(b.$1);
        });
  return [for (final result in ranked) result.$2];
}
