import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/features/nutrition/data/food_local_database.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/data/usda_api_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

Map<String, dynamic> nutrient(int id, num amount, String unit) => {
  'id': 987654, // FoodNutrient row id is not the nutrient identity.
  'nutrient': {'id': id, 'unitName': unit}, 'amount': amount,
};
UsdaApiService fixture(List<Object?> nutrients) => UsdaApiService(
  client: MockClient(
    (r) async => http.Response(
      jsonEncode({
        'fdcId': 168878,
        'description': 'Rice, cooked',
        'foodNutrients': nutrients,
      }),
      200,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'USDA extra nutrients preserve normalized mg/g and do not invent missing values',
    () async {
      final food = (await fixture([
        nutrient(1008, 100, 'kcal'),
        nutrient(1003, 10, 'g'),
        nutrient(1005, 10, 'g'),
        nutrient(1004, 2, 'g'),
        nutrient(1093, 120, 'MG'),
        nutrient(1089, 1.25, 'mg'),
        nutrient(2000, 0, 'G'),
        nutrient(1258, 1, 'g'),
        nutrient(1162, 2, 'wrong-unit'),
      ]).getFoodDetail(168878))!;
      expect(food.forGrams(150).extraNutrients['sodium'], 180);
      expect(food.nutritionPer100g.extraNutrients['sugar'], 0);
      expect(
        food.nutritionPer100g.extraNutrients.containsKey('vitaminC'),
        false,
      );
      expect(food.nutritionPer100g.extraNutrients['iron'], 1.25);
    },
  );
  test(
    'full USDA details use nested nutrient identity and preserve measured zero',
    () async {
      final food = (await fixture([
        nutrient(1008, 130, 'kcal'),
        nutrient(1003, 2.69, 'g'),
        nutrient(1005, 28.17, 'g'),
        nutrient(1004, .28, 'g'),
        nutrient(1079, 0, 'g'),
      ]).getFoodDetail(168878))!;
      expect(food.nutritionPer100g.kcal, 130);
      expect(food.nutritionPer100g.proteinG, 2.69);
      expect(food.nutritionPer100g.fiberKnown, true);
      expect(food.nutritionPer100g.fiberG, 0);
      expect(food.forGrams(150).kcal, 195);
    },
  );
  test(
    'missing macros stay unknown rather than claiming zero and are not cached',
    () async {
      final food = (await fixture([
        nutrient(1008, 80, 'kcal'),
      ]).getFoodDetail(168878))!;
      expect(food.nutritionPer100g.proteinKnown, false);
      expect(food.nutritionPer100g.carbsKnown, false);
      expect(food.nutritionPer100g.fatKnown, false);
      expect(food.nutritionPer100g.fiberKnown, false);
      // No platform SQL operation for incomplete data; no silent conversion to 0.
      await FoodLocalDatabase.instance.cacheFood(food);
      await FoodLocalDatabase.instance.cacheFoodsBatch([food]);
    },
  );
  test(
    'missing, wrong-unit and invalid energy cannot become a usable zero-calorie food',
    () async {
      for (final rows in [
        [],
        [nutrient(1003, 2, 'g')],
        [nutrient(1008, 130, 'kJ')],
        [nutrient(1008, -1, 'kcal')],
        [nutrient(1008, 1001, 'kcal')],
      ]) {
        expect(await fixture(rows).getFoodDetail(168878), isNull);
      }
    },
  );
  test(
    'legacy flat identity/value remains supported without confusing row ids',
    () async {
      final food = await fixture([
        {'nutrientId': 1008, 'value': 100, 'unitName': 'KCAL'},
        {'nutrientId': 1003, 'amount': 0, 'unitName': 'G'},
      ]).getFoodDetail(168878);
      expect(food!.nutritionPer100g.kcal, 100);
      expect(food.nutritionPer100g.proteinKnown, true);
      expect(food.nutritionPer100g.proteinG, 0);
    },
  );
  test(
    'unscoped public cache rejects private food writes before any SQL operation',
    () async {
      const private = FoodCatalogItem(
        id: 'private-id',
        name: 'Private food',
        category: 'private',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Private source',
        isEstimated: true,
        dataSource: FoodDataSource.user,
      );
      await expectLater(
        FoodLocalDatabase.instance.cacheFood(private),
        throwsArgumentError,
      );
      await expectLater(
        FoodLocalDatabase.instance.cacheFoodsBatch([private]),
        throwsArgumentError,
      );
    },
  );
  test(
    'external failure logs contain neither the query nor raw provider exception',
    () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        final service = UnifiedFoodSearchService(
          localDatabase: FoodLocalDatabase.instance,
          usdaService: UsdaApiService(
            client: MockClient((r) async {
              throw http.ClientException('PRIVATE_PROVIDER_DETAIL', r.url);
            }),
          ),
        );
        final outcome = await service.search(
          query: 'PRIVATE_FOOD_QUERY',
          firestoreCatalog: [],
        );
        expect(outcome.results, isEmpty);
        expect(outcome.failure?.kind, FoodSearchFailureKind.network);
        expect(outcome.message, isNotNull);
        expect(logs.join(), isNot(contains('PRIVATE_PROVIDER_DETAIL')));
        expect(logs.join(), isNot(contains('PRIVATE_FOOD_QUERY')));
      } finally {
        debugPrint = original;
      }
    },
  );
}
