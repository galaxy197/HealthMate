import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nutrition_models.dart';

/// USDA FoodData Central API Service
/// Free tier: unlimited requests, no API key required for public data
/// API Docs: https://fdc.nal.usda.gov/api-guide.html
class UsdaApiService {
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

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

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
      final uri = Uri.parse('$baseUrl/food/$fdcId').replace(
        queryParameters: {'api_key': apiKey},
      );

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

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
  FoodCatalogItem _convertToFoodCatalogItem(Map<String, dynamic> data) {
    final fdcId = data['fdcId'] as int;
    final description = data['description'] as String? ?? 'Unknown';

    // Extract nutrients
    final nutrients = data['foodNutrients'] as List<dynamic>? ?? [];
    double kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;

    for (final n in nutrients) {
      final nutrient = n as Map<String, dynamic>;
      final nutrientId = nutrient['nutrientId'] as int?;
      final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0;

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

    return FoodCatalogItem(
      id: 'usda_$fdcId',
      name: description,
      category: _inferCategory(description),
      servingBasis: ServingBasis.per100g,
      kcalPer100g: kcal,
      proteinGPer100g: protein,
      carbsGPer100g: carbs,
      fatGPer100g: fat,
      fiberGPer100g: fiber > 0 ? fiber : null,
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

    if (lower.contains('rice') || lower.contains('noodle') ||
        lower.contains('bread') || lower.contains('pasta')) {
      return 'grains';
    } else if (lower.contains('chicken') || lower.contains('beef') ||
        lower.contains('pork') || lower.contains('fish')) {
      return 'protein';
    } else if (lower.contains('milk') || lower.contains('cheese') ||
        lower.contains('yogurt')) {
      return 'dairy';
    } else if (lower.contains('apple') || lower.contains('banana') ||
        lower.contains('orange') || lower.contains('fruit')) {
      return 'fruits';
    } else if (lower.contains('vegetable') || lower.contains('carrot') ||
        lower.contains('broccoli') || lower.contains('lettuce')) {
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
