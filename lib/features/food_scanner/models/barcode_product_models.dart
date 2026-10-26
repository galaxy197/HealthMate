import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';

class BarcodeProduct {
  const BarcodeProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutrition,
    this.servingSizeG,
    required this.source,
  });
  final String barcode, name, source;
  final String? brand, imageUrl;

  /// Always values per 100 g, not the selected portion.
  final NutritionTotals? nutrition;
  final double? servingSizeG;
}

/// Product nutrients remain per 100 g until the user confirms a quantity.
class BarcodeMealSelection {
  const BarcodeMealSelection({required this.product, required this.grams});
  final BarcodeProduct product;
  final double grams;

  MealItemSnapshot toSnapshot() {
    if (NutritionValidation.grams(grams.toString()) != null ||
        product.nutrition == null) {
      throw const FormatException('Kiểm tra khẩu phần và dữ liệu dinh dưỡng.');
    }
    final nutrition = product.nutrition!.scale(grams / 100);
    if (!nutrition.kcal.isFinite ||
        nutrition.kcal < 0 ||
        nutrition.kcal > 10000 ||
        [
          nutrition.proteinG,
          nutrition.carbsG,
          nutrition.fatG,
          nutrition.fiberG,
        ].any((n) => !n.isFinite || n < 0 || n > 1000)) {
      throw const FormatException('Dinh dưỡng theo khẩu phần vượt giới hạn.');
    }
    return MealItemSnapshot(
      foodId: 'barcode_${product.barcode}',
      name: product.name,
      grams: grams,
      nutrition: nutrition,
      sourceLabel: product.source,
      isEstimated: true,
    );
  }
}
