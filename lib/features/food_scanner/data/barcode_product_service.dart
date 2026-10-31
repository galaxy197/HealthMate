import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../nutrition/models/nutrition_models.dart';
import '../models/barcode_product_models.dart';
export '../models/barcode_product_models.dart' show BarcodeProduct;

class BarcodeLookupFailure implements Exception {
  const BarcodeLookupFailure(this.message);
  final String message;
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
    } on BarcodeLookupFailure {
      rethrow;
    } on FormatException {
      throw const BarcodeLookupFailure(
        'Dữ liệu dinh dưỡng không hợp lệ. Hãy kiểm tra và nhập theo nhãn sản phẩm.',
      );
    } catch (_) {
      throw const BarcodeLookupFailure(
        'Chưa tra cứu được sản phẩm. Kiểm tra mạng rồi thử lại hoặc nhập thủ công.',
      );
    }

    // 2. Có thể thêm nguồn khác (USDA branded foods, etc.)
    // TODO: Thêm USDA branded foods lookup nếu cần

    return null;
  }

  Future<BarcodeProduct?> _queryOpenFoodFacts(String barcode) async {
    final url = Uri.parse('$_openFoodFactsBaseUrl/product/$barcode');

    final response = await _client
        .get(
          url,
          headers: {
            'User-Agent': 'HealthMate/1.0 (Android; nutrition tracker)',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) {
      throw const BarcodeLookupFailure(
        'Đã chạm giới hạn tra cứu. Hãy thử lại sau.',
      );
    }
    if (response.statusCode != 200) {
      throw const BarcodeLookupFailure(
        'Dịch vụ tra cứu đang lỗi. Hãy thử lại sau.',
      );
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    // status = 1 có nghĩa là tìm thấy sản phẩm
    if (data['status'] != 1) return null;

    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    // Parse thông tin cơ bản
    final name = product['product_name'] as String?;
    if (name == null || name.isEmpty) return null;

    final brand = product['brands'] as String?;
    final imageUrl = product['image_url'] as String?;

    // OFF v2 uses `_100g` for both 100 g and 100 ml. The user confirms
    // the label basis; package/serving units do not prove the nutrition basis.
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    NutritionTotals? nutrition;

    if (nutriments != null) {
      // Try energy-kcal first, then convert from kJ if needed
      double? kcal = _nutrient(nutriments['energy-kcal_100g'], 10000);
      if (kcal == null) {
        final kj = _nutrient(nutriments['energy_100g'], 41840);
        if (kj != null) {
          kcal = kj / 4.184; // Convert kJ to kcal
        }
      }

      final protein = _nutrient(nutriments['proteins_100g'], 1000);
      final carbs = _nutrient(nutriments['carbohydrates_100g'], 1000);
      final fat = _nutrient(nutriments['fat_100g'], 1000);
      final fiber = _nutrient(nutriments['fiber_100g'], 1000);

      if (kcal != null) {
        const fields = {
          'sugar': 'sugars',
          'saturatedFat': 'saturated-fat',
          'sodium': 'sodium',
          'potassium': 'potassium',
          'calcium': 'calcium',
          'iron': 'iron',
          'vitaminC': 'vitamin-c',
          'cholesterol': 'cholesterol',
        };
        final extras = <String, double>{};
        for (final field in fields.entries) {
          final value = _nutrient(nutriments['${field.value}_100g'], 1000);
          // OFF normalizes these nutrient masses to grams, including minerals.
          if (value != null) {
            final normalized =
                value *
                (['sugar', 'saturatedFat'].contains(field.key) ? 1 : 1000);
            extras[field.key] = normalized;
          }
        }
        nutrition = NutritionTotals(
          extraNutrients: extras,
          kcal: kcal,
          proteinG: protein ?? 0,
          carbsG: carbs ?? 0,
          fatG: fat ?? 0,
          proteinKnown: protein != null,
          carbsKnown: carbs != null,
          fatKnown: fat != null,
          fiberG: fiber ?? 0,
          fiberKnown: fiber != null,
        );
      }
    }

    // Parse serving size
    final serving = _parseDouble(product['serving_quantity']);
    final unit = product['serving_quantity_unit'];
    final servingSizeG =
        unit == 'g' && serving != null && serving > 0 && serving <= 2000
        ? serving
        : null;

    return BarcodeProduct(
      barcode: barcode,
      name: name,
      brand: brand?.isNotEmpty == true ? brand : null,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      nutrition: nutrition,
      servingSizeG: servingSizeG,
      servingSizeMl:
          unit == 'ml' && serving != null && serving > 0 && serving <= 2000
          ? serving
          : null,
      basis: BarcodeNutritionBasis.unconfirmed,
      source: 'Open Food Facts',
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    if (number == null || !number.isFinite) {
      throw const FormatException('Invalid product nutrition.');
    }
    return number;
  }

  double? _nutrient(dynamic value, double maximum) {
    final number = _parseDouble(value);
    if (number != null && (number < 0 || number > maximum)) {
      throw const FormatException('Invalid product nutrition.');
    }
    return number;
  }

  void dispose() {
    _client.close();
  }
}
