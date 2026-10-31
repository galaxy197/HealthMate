import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nutrition_models.dart';
import '../models/extra_nutrients.dart';
import '../models/nutrition_validation.dart';
import 'food_search_request.dart';

/// USDA FoodData Central API Service
/// Public DEMO_KEY only; USDA applies hourly/daily limits.
/// API Docs: https://fdc.nal.usda.gov/api-guide/
class UsdaApiService {
  UsdaApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;
  static const String baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Public demo credential; quota is shared and may be exhausted. No secret
  // replacement is embedded in the app. See the current USDA API guide.
  static const String apiKey = 'DEMO_KEY';

  /// Search foods by query
  /// Returns list of basic food info for search results
  Future<List<UsdaSearchResult>> searchFoods(
    String query, {
    int pageSize = 25,
    int pageNumber = 1,
    List<String>? dataTypes,
    FoodSearchRequest? request,
  }) async {
    if (query.trim().isEmpty) return [];
    final work = request ?? FoodSearchRequest();
    try {
      final uri = Uri.parse('$baseUrl/foods/search').replace(
        queryParameters: {
          'api_key': apiKey,
          'query': query.trim(),
          'pageSize': pageSize.clamp(1, 50).toString(),
          'pageNumber': (pageNumber < 1 ? 1 : pageNumber).toString(),
          if (dataTypes != null) 'dataType': dataTypes.join(','),
        },
      );

      final response = await _load(uri, work);
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> || data['foods'] is! List) {
        throw const FormatException('Invalid search response');
      }
      final results = <UsdaSearchResult>[];
      for (final row in (data['foods'] as List).take(pageSize.clamp(1, 50))) {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Invalid row');
        }
        final parsed = UsdaSearchResult.fromJson(row);
        if (parsed.fdcId <= 0 || parsed.description.trim().isEmpty) {
          throw const FormatException('Invalid search identity');
        }
        results.add(parsed);
      }
      work.check();
      return results;
    } on FoodSearchFailure {
      rethrow;
    } on FormatException {
      throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
    } on TypeError {
      throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
    } finally {
      if (request == null) work.finish();
    }
  }

  /// Get detailed food information by FDC ID
  Future<FoodCatalogItem?> getFoodDetail(
    int fdcId, {
    FoodSearchRequest? request,
  }) async {
    final work = request ?? FoodSearchRequest();
    try {
      final uri = Uri.parse(
        '$baseUrl/food/$fdcId',
      ).replace(queryParameters: {'api_key': apiKey});

      final response = await _load(uri, work, allowNotFound: true);
      if (response.statusCode == 404) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> ||
          data['fdcId'] != fdcId ||
          data['description'] is! String ||
          (data['description'] as String).trim().isEmpty ||
          data['foodNutrients'] is! List) {
        throw const FormatException('Invalid detail identity');
      }
      final food = _convertToFoodCatalogItem(data);
      work.check();
      return food;
    } on FoodSearchFailure {
      rethrow;
    } on FormatException {
      throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
    } on TypeError {
      throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
    } finally {
      if (request == null) work.finish();
    }
  }

  Future<http.Response> _load(
    Uri uri,
    FoodSearchRequest work, {
    bool allowNotFound = false,
  }) async {
    try {
      final response = await work.run(() async {
        final outgoing = http.AbortableRequest(
          'GET',
          uri,
          abortTrigger: work.abortTrigger,
        );
        final stream = await _client.send(outgoing);
        work.check();
        return http.Response.fromStream(stream);
      });
      if (response.statusCode == 429) {
        throw const FoodSearchFailure(FoodSearchFailureKind.quota);
      }
      if (response.statusCode != 200 &&
          !(allowNotFound && response.statusCode == 404)) {
        throw const FoodSearchFailure(FoodSearchFailureKind.provider);
      }
      return response;
    } on FoodSearchFailure {
      rethrow;
    } catch (_) {
      work.check();
      throw const FoodSearchFailure(FoodSearchFailureKind.network);
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
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
        !NutritionValidation.validPer100g(
          kcal: kcal,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
        )) {
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
    if (json['fdcId'] is! int ||
        (json['fdcId'] as int) <= 0 ||
        json['description'] is! String ||
        (json['description'] as String).trim().isEmpty) {
      throw const FormatException('Invalid search identity');
    }
    return UsdaSearchResult(
      fdcId: json['fdcId'] as int,
      description: (json['description'] as String).trim(),
      dataType: json['dataType'] as String? ?? 'Unknown',
      brandOwner: json['brandOwner'] as String?,
    );
  }
}
