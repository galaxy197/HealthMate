import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../nutrition/models/nutrition_models.dart';

/// Thông tin sản phẩm từ barcode
class BarcodeProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionTotals? nutrition;
  final double? servingSizeG;
  final String source;

  const BarcodeProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutrition,
    this.servingSizeG,
    required this.source,
  });
}

/// Service tra cứu thông tin sản phẩm từ barcode
class BarcodeProductService {
  static const _openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  final http.Client _client;

  BarcodeProductService({http.Client? client})
      : _client = client ?? http.Client();

  /// Tra cứu sản phẩm từ barcode
  /// Returns null nếu không tìm thấy
  Future<BarcodeProduct?> lookupBarcode(String barcode) async {
    // 1. Thử Open Food Facts trước
    try {
      final product = await _queryOpenFoodFacts(barcode);
      if (product != null) return product;
    } catch (e) {
      // Ignore và thử nguồn khác
    }

    // 2. Có thể thêm nguồn khác (USDA branded foods, etc.)
    // TODO: Thêm USDA branded foods lookup nếu cần

    return null;
  }

  Future<BarcodeProduct?> _queryOpenFoodFacts(String barcode) async {
    final url = Uri.parse('$_openFoodFactsBaseUrl/product/$barcode');

    final response = await _client.get(url).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // status = 1 có nghĩa là tìm thấy sản phẩm
    if (data['status'] != 1) return null;

    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    // Parse thông tin cơ bản
    final name = product['product_name'] as String?;
    if (name == null || name.isEmpty) return null;

    final brand = product['brands'] as String?;
    final imageUrl = product['image_url'] as String?;

    // Parse nutrition (per 100g)
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    NutritionTotals? nutrition;

    if (nutriments != null) {
      final kcal = _parseDouble(nutriments['energy-kcal_100g']) ??
                   _parseDouble(nutriments['energy_100g'])?.let((kj) => kj / 4.184);
      final protein = _parseDouble(nutriments['proteins_100g']);
      final carbs = _parseDouble(nutriments['carbohydrates_100g']);
      final fat = _parseDouble(nutriments['fat_100g']);

      if (kcal != null) {
        nutrition = NutritionTotals(
          kcal: kcal,
          proteinG: protein ?? 0,
          carbsG: carbs ?? 0,
          fatG: fat ?? 0,
        );
      }
    }

    // Parse serving size
    final servingSizeG = _parseDouble(product['serving_quantity']);

    return BarcodeProduct(
      barcode: barcode,
      name: name,
      brand: brand?.isNotEmpty == true ? brand : null,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      nutrition: nutrition,
      servingSizeG: servingSizeG,
      source: 'Open Food Facts',
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void dispose() {
    _client.close();
  }
}

extension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
