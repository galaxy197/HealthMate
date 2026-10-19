import 'nutrition_models.dart';

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
    for (final raw in [food.name, ...food.alternateNames]) {
      final name = normalizeFoodSearch(raw);
      final tokens = name.split(' ');
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
