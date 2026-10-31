abstract final class NutritionValidation {
  static const int maxItemsPerMeal = 5;
  static const double maxGramsPerItem = 2000;
  static const double maxMealKcal = 20000;

  // Conservative data-quality ceiling: above pure fat (~900 kcal/100 g)
  // to tolerate label rounding. This is not a calorie recommendation.
  static const double maxKcalPer100g = 1000;

  static bool validPer100g({
    required double kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
  }) =>
      kcal.isFinite &&
      kcal >= 0 &&
      kcal <= maxKcalPer100g &&
      [
        protein,
        carbs,
        fat,
        fiber,
      ].every((v) => v == null || (v.isFinite && v >= 0 && v <= 100));

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
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
