import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
import '../../nutrition/models/extra_nutrients.dart';

enum BarcodeNutritionBasis { per100g, per100ml, unconfirmed }

class BarcodeProduct {
  const BarcodeProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutrition,
    this.servingSizeG,
    this.servingSizeMl,
    this.basis = BarcodeNutritionBasis.per100g,
    required this.source,
  });
  final String barcode, name, source;
  final String? brand, imageUrl;

  /// Normalized per 100 g or 100 ml, never the selected portion.
  /// Legacy OFF `_100g` does not distinguish mass from volume.
  final NutritionTotals? nutrition;
  final double? servingSizeG;
  final double? servingSizeMl;
  final BarcodeNutritionBasis basis;
}

/// Product nutrients remain per 100 units until the user confirms the label.
class BarcodeMealSelection {
  const BarcodeMealSelection({
    required this.product,
    required this.quantity,
    this.confirmedBasis,
  });
  final BarcodeProduct product;
  final double quantity;
  final BarcodeNutritionBasis? confirmedBasis;
  BarcodeNutritionBasis get basis => confirmedBasis ?? product.basis;

  MealItemSnapshot toSnapshot() {
    if (!quantity.isFinite ||
        quantity <= 0 ||
        quantity > NutritionValidation.maxGramsPerItem ||
        product.nutrition == null ||
        basis == BarcodeNutritionBasis.unconfirmed ||
        (product.basis != BarcodeNutritionBasis.unconfirmed &&
            basis != product.basis)) {
      throw const FormatException('Kiểm tra khẩu phần và dữ liệu dinh dưỡng.');
    }
    final original = product.nutrition!;
    if (basis == BarcodeNutritionBasis.per100g &&
        !NutritionValidation.validPer100g(
          kcal: original.kcal,
          protein: original.proteinG,
          carbs: original.carbsG,
          fat: original.fatG,
          fiber: original.fiberG,
        )) {
      throw const FormatException(
        'Dữ liệu trên 100 g không hợp lệ. Hãy kiểm tra nhãn sản phẩm.',
      );
    }
    for (final entry in original.extraNutrients.entries) {
      final definition = ExtraNutrient.values
          .where((n) => n.name == entry.key)
          .firstOrNull;
      final maximum = definition?.unit == 'g' ? 100.0 : 100000.0;
      if (definition == null ||
          !entry.value.isFinite ||
          entry.value < 0 ||
          (basis == BarcodeNutritionBasis.per100g && entry.value > maximum)) {
        throw const FormatException('Dưỡng chất trên nhãn không hợp lệ.');
      }
    }
    final nutrition = original.scale(quantity / 100);
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
    for (final entry in nutrition.extraNutrients.entries) {
      if (!entry.value.isFinite ||
          entry.value < 0 ||
          entry.value > ExtraNutrient.values.byName(entry.key).maximum) {
        throw const FormatException(
          'Dưỡng chất theo khẩu phần vượt giới hạn lưu.',
        );
      }
    }
    return MealItemSnapshot(
      foodId: 'barcode_${product.barcode}',
      name: product.name,
      grams: basis == BarcodeNutritionBasis.per100g ? quantity : 0,
      quantityUnit: basis == BarcodeNutritionBasis.per100g ? 'g' : 'ml',
      quantityValue: basis == BarcodeNutritionBasis.per100g ? null : quantity,
      nutrition: nutrition,
      sourceLabel: product.source,
      isEstimated: true,
    );
  }
}
