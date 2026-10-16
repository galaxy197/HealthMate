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
  return catalog
      .where(
        (food) => [
          food.name,
          ...food.alternateNames,
        ].any((name) => normalizeFoodSearch(name).contains(normalized)),
      )
      .toList(growable: false);
}
