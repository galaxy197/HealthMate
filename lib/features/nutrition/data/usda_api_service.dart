import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nutrition_models.dart';
import '../models/extra_nutrients.dart';

/// USDA FoodData Central API Service
/// Public DEMO_KEY only; USDA applies hourly/daily limits.
/// API Docs: https://fdc.nal.usda.gov/api-guide.html
class UsdaApiService {
  UsdaApiService({http.Client? client}) : _get = client?.get ?? http.get;
  final Future<http.Response> Function(Uri) _get;
  static const String baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Get free API key at: https://fdc.nal.usda.gov/api-key-signup.html
  // For demo, using DEMO_KEY (rate limited to 30 requests/hour)
  static const String apiKey = 'DEMO_KEY';

  /// Search foods by query
  /// Returns list of basic food info for search results
  Future<List<UsdaSearchResult>> searchFoods(
    String query, {
    int pageSize = 25,
    int pageNumber = 1,
    List<String>? dataTypes,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/foods/search').replace(
        queryParameters: {
          'api_key': apiKey,
          'query': query.trim(),
          'pageSize': pageSize.toString(),
          'pageNumber': pageNumber.toString(),
          if (dataTypes != null) 'dataType': dataTypes.join(','),
        },
      );

      final response = await _get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final foods = data['foods'] as List<dynamic>? ?? [];

        return foods
            .map((f) => UsdaSearchResult.fromJson(f as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please wait and try again.');
      } else {
        throw Exception('USDA API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('rate limit')) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// Get detailed food information by FDC ID
  Future<FoodCatalogItem?> getFoodDetail(int fdcId) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/food/$fdcId',
      ).replace(queryParameters: {'api_key': apiKey});

      final response = await _get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _convertToFoodCatalogItem(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert USDA food data to our FoodCatalogItem model
  FoodCatalogItem? _convertToFoodCatalogItem(Map<String, dynamic> data) {
    final fdcId = data['fdcId'] as int;
    final description = data['description'] as String? ?? 'Unknown';

    // Extract nutrients
    final nutrients = data['foodNutrients'] as List<dynamic>? ?? [];
    double? kcal, protein, carbs, fat, fiber;
    final extras = <String, double>{};
    const extraIds = {
      2000: 'sugar',
      1258: 'saturatedFat',
      1093: 'sodium',
      1092: 'potassium',
      1087: 'calcium',
      1089: 'iron',
      1162: 'vitaminC',
      1253: 'cholesterol',
    };

    for (final n in nutrients) {
      if (n is! Map<String, dynamic>) continue;
      final detail = n['nutrient'];
      final nutrientId = detail is Map ? detail['id'] : n['nutrientId'];
      final rawAmount = n['amount'] ?? n['value'];
      if (rawAmount is! num || !rawAmount.isFinite || rawAmount < 0) continue;
      final amount = rawAmount.toDouble();
      final unit = (detail is Map ? detail['unitName'] : n['unitName'])
          ?.toString()
          .toLowerCase();
      final extraKey = extraIds[nutrientId];
      if (extraKey != null) {
        final definition = ExtraNutrient.values.byName(extraKey);
        if (unit == definition.unit && amount <= definition.maximum) {
          extras[extraKey] = amount;
        }
        continue;
      }
      if (nutrientId == 1008
          ? (unit != null && unit != 'kcal')
          : (unit != null && unit != 'g')) {
        continue;
      }

      switch (nutrientId) {
        case 1008: // Energy (kcal)
          kcal = amount;
        case 1003: // Protein
          protein = amount;
        case 1005: // Carbs
          carbs = amount;
        case 1004: // Fat
          fat = amount;
        case 1079: // Fiber
          fiber = amount;
      }
    }

    // A missing energy row is not evidence of a zero-calorie food.
    if (kcal == null ||
        kcal > 1000 ||
        [protein, carbs, fat, fiber].any((v) => v != null && v > 100)) {
      return null;
    }

    return FoodCatalogItem(
      id: 'usda_$fdcId',
      name: description,
      category: _inferCategory(description),
      servingBasis: ServingBasis.per100g,
      kcalPer100g: kcal,
      proteinGPer100g: protein,
      carbsGPer100g: carbs,
      fatGPer100g: fat,
      fiberGPer100g: fiber,
      extraNutrientsPer100g: extras,
      sourceLabel: 'USDA FoodData Central',
      isEstimated: false,
      dataSource: FoodDataSource.usda,
      fdcId: fdcId,
      updatedAt: DateTime.now(),
    );
  }

  /// Infer category from food description
  String _inferCategory(String description) {
    final lower = description.toLowerCase();

    if (lower.contains('rice') ||
        lower.contains('noodle') ||
        lower.contains('bread') ||
        lower.contains('pasta')) {
      return 'grains';
    } else if (lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('pork') ||
        lower.contains('fish')) {
      return 'protein';
    } else if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('yogurt')) {
      return 'dairy';
    } else if (lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('orange') ||
        lower.contains('fruit')) {
      return 'fruits';
    } else if (lower.contains('vegetable') ||
        lower.contains('carrot') ||
        lower.contains('broccoli') ||
        lower.contains('lettuce')) {
      return 'vegetables';
    }

    return 'other';
  }
}

/// USDA search result (minimal data for list display)
class UsdaSearchResult {
  final int fdcId;
  final String description;
  final String dataType;
  final String? brandOwner;

  UsdaSearchResult({
    required this.fdcId,
    required this.description,
    required this.dataType,
    this.brandOwner,
  });

  factory UsdaSearchResult.fromJson(Map<String, dynamic> json) {
    return UsdaSearchResult(
      fdcId: json['fdcId'] as int,
      description: json['description'] as String? ?? 'Unknown',
      dataType: json['dataType'] as String? ?? 'Unknown',
      brandOwner: json['brandOwner'] as String?,
    );
  }
}
