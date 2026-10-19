import 'nutrition_models.dart';

/// Catalog metadata is optional. A damaged portion never corrupts the per-100g
/// values or makes unrelated catalog documents unreadable.
FoodCatalogItem readCatalogFood(
  String id,
  Map<String, dynamic> data, {
  DateTime? updatedAt,
}) {
  String? text(String key, [int max = 100]) {
    final value = data[key];
    return value is String && value.trim().isNotEmpty && value.length <= max
        ? value.trim()
        : null;
  }

  double? number(String key, double max, {bool positive = false}) {
    final value = data[key];
    return value is num &&
            value.isFinite &&
            (positive ? value > 0 : value >= 0) &&
            value <= max
        ? value.toDouble()
        : null;
  }

  final kcal = number('kcalPer100g', 10000);
  final protein = number('proteinGPer100g', 1000);
  final carbs = number('carbsGPer100g', 1000);
  final fat = number('fatGPer100g', 1000);
  final fiber = number('fiberGPer100g', 100);
  final basisStr =
      text('servingBasis') ??
      (data['servingBasis'] == null ? 'per_100g' : 'unsupported');
  final basis = basisStr == 'per_100g'
      ? ServingBasis.per100g
      : basisStr == 'explicit_serving'
      ? ServingBasis.explicitServing
      : ServingBasis.per100g; // fallback
  final unit = text('unit') ?? (data['unit'] == null ? 'g' : 'unsupported');
  final label = text('servingLabel', 60);
  final grams = number('servingGrams', 2000, positive: true);
  final hasRawServing =
      data['servingLabel'] != null || data['servingGrams'] != null;
  final validServing =
      label != null && grams != null && basisStr == 'per_100g' && unit == 'g';
  return FoodCatalogItem(
    id: id,
    name: text('name') ?? 'Món chưa có tên',
    alternateNames: data['alternateNames'] is List
        ? (data['alternateNames'] as List)
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : const [],
    category: text('category') ?? '',
    servingBasis: basis,
    unit: unit,
    hasNutritionData:
        [kcal, protein, carbs, fat].every((v) => v != null) &&
        basisStr == 'per_100g' &&
        unit == 'g',
    per100g: NutritionTotals(
      kcal: kcal ?? 0,
      proteinG: protein ?? 0,
      carbsG: carbs ?? 0,
      fatG: fat ?? 0,
      fiberG: fiber ?? 0,
      fiberKnown: fiber != null,
    ),
    sourceLabel: text('sourceLabel', 160) ?? 'Không rõ nguồn',
    isEstimated: data['isEstimated'] is bool
        ? data['isEstimated'] as bool
        : true,
    updatedAt: updatedAt,
    defaultServingGrams:
        number('defaultServingGrams', 2000, positive: true) ?? 100,
    servingLabel: validServing ? label : null,
    servingGrams: validServing ? grams : null,
    servingMetadataInvalid: hasRawServing && !validServing,
    brand: text('brand', 60),
    packageLabel: text('packageLabel', 60),
  );
}
