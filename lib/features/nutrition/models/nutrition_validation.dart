abstract final class NutritionValidation {
  static const int maxItemsPerMeal = 5;
  static const double maxGramsPerItem = 2000;
  static const double maxMealKcal = 20000;

  static String? grams(String? value) {
    final parsed = parseDecimal(value);
    if (parsed == null) return 'Nhập khối lượng hợp lệ.';
    if (parsed <= 0 || parsed > maxGramsPerItem) {
      return 'Khối lượng phải từ trên 0 đến 2.000 g.';
    }
    return null;
  }

  static double? parseDecimal(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}
