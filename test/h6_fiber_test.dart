import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/presentation/food_nutrition_text.dart';
import 'package:healthmate/features/meal_templates/models/meal_template.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

void main() {
  MealItemSnapshot item(NutritionTotals n) => MealItemSnapshot(
    foodId: 'qa-fiber',
    name: 'QA ingredient',
    grams: 100,
    nutrition: n,
    sourceLabel: 'Synthetic QA',
    isEstimated: true,
  );
  const known = NutritionTotals(kcal: 100, fiberG: 2.4, fiberKnown: true);
  const unknown = NutritionTotals(kcal: 100);
  test('zero, absent, malformed and sourced fiber stay distinct', () {
    final raw = item(unknown).toData();
    expect(raw.containsKey('fiberG'), false);
    expect(
      MealItemSnapshot.fromData(Map.from(raw)).nutrition.fiberKnown,
      false,
    );
    final zero = item(const NutritionTotals(fiberKnown: true));
    expect(zero.toData()['fiberG'], 0);
    expect(
      MealItemSnapshot.fromData(Map.from(zero.toData())).nutrition.fiberKnown,
      true,
    );
    for (final invalid in [-1, double.nan, double.infinity, '2']) {
      expect(
        MealItemSnapshot.fromData({
          ...raw,
          'fiberG': invalid,
        }).nutrition.fiberKnown,
        false,
      );
    }
    expect(nutritionLabel(unknown), contains('Chất xơ Chưa đủ dữ liệu'));
    expect(nutritionLabel(zero.nutrition), contains('Chất xơ 0 g'));
  });
  test(
    'fractional amount and recipe yield retain partial coverage through snapshots',
    () {
      final recipe = FoodRecipe(
        id: 'r',
        name: 'QA recipe',
        ingredients: [item(known), item(unknown)],
        yieldGrams: 400,
        servingsCount: 2,
      );
      expect(recipe.totals.fiberG, 2.4);
      expect(recipe.totals.fiberKnown, false);
      expect(recipe.toData()['schemaVersion'], 2);
      final snapshot = MealItemSnapshot.fromCatalog(recipe.asFood(), 150);
      expect(snapshot.nutrition.fiberG, closeTo(.9, 1e-9));
      expect(snapshot.nutrition.fiberKnown, false);
      expect(snapshot.toData()['fiberG'], closeTo(.9, 1e-9));
      expect(snapshot.toData()['fiberIncomplete'], true);
      final restored = MealItemSnapshot.fromData(
        Map.from(snapshot.toData()),
        allowPartial: true,
      );
      expect(restored.withQuantity(300).nutrition.fiberG, closeTo(1.8, 1e-9));
      expect(restored.nutrition.fiberKnown, false);
      expect(nutritionLabel(restored.nutrition), contains('≥0,9 g (chưa đủ)'));
      final readRecipe = FoodRecipe.fromData('r', Map.from(recipe.toData()));
      expect(readRecipe.per100g.fiberG, .6);
      expect(readRecipe.per100g.fiberKnown, false);
      final template = MealTemplate(
        id: 'partial',
        name: 'QA partial',
        items: [snapshot],
      );
      final wire = template.toData();
      expect(wire['fiberPartialMask'], 1);
      expect((wire['items'] as List).single['quantityUnit'], 'g');
      final roundTrip = MealTemplate.fromData('partial', Map.from(wire));
      expect(roundTrip.items.single.nutrition.fiberG, closeTo(.9, 1e-9));
      expect(roundTrip.items.single.nutrition.fiberKnown, false);
      expect(roundTrip.items.single.grams, 150);
      expect(
        () => MealTemplate.fromData('bad', {...wire, 'fiberPartialMask': 2}),
        throwsFormatException,
      );
      expect(
        () => MealTemplate.fromData('bad', {
          ...wire,
          'fiberValues': [-1],
        }),
        throwsFormatException,
      );
    },
  );
  test('aggregation identity does not mark real known data as missing', () {
    expect(sumNutritionTotals([known, known]).fiberKnown, true);
    expect(sumNutritionTotals([known, unknown]).fiberKnown, false);
    expect(sumNutritionTotals([known, unknown]).fiberG, 2.4);
    expect(sumNutritionTotals([]).fiberKnown, false);
    expect((NutritionTotals.zero + known).fiberKnown, true);
  });
  test(
    'library, template and copied meal keep coverage and minimum schema',
    () {
      final food = PersonalFood(id: 'p', name: 'QA food', per100g: known);
      expect(food.toData()['schemaVersion'], 2);
      expect(
        PersonalFood.fromData('p', Map.from(food.toData())).per100g.fiberG,
        2.4,
      );
      expect(
        PersonalFood(
          id: 'u',
          name: 'Unknown',
          per100g: unknown,
        ).toData().containsKey('fiberGPer100g'),
        false,
      );
      expect(
        () => PersonalFood(
          id: 'x',
          name: 'Invalid',
          per100g: const NutritionTotals(fiberG: 101, fiberKnown: true),
        ).validate(),
        throwsFormatException,
      );
      final template = MealTemplate(
        id: 't',
        name: 'QA template',
        items: [item(known), item(unknown)],
      );
      expect(template.toData()['schemaVersion'], 3);
      final read = MealTemplate.fromData('t', Map.from(template.toData()));
      expect(read.items.first.nutrition.fiberKnown, true);
      expect(read.items.last.nutrition.fiberKnown, false);
      final meal = MealLog(
        id: 'm',
        type: MealType.lunch,
        consumedAt: DateTime(2026, 1, 1),
        items: read.items,
        totals: sumNutritionTotals(read.items.map((i) => i.nutrition)),
        source: MealSource.manual,
        schemaVersion: 4,
      );
      expect(meal.toDraft().minimumSchemaVersion, 4);
      expect(
        meal
            .copyDraft(day: DateTime(2026, 1, 2), now: DateTime(2026, 1, 3))
            .minimumSchemaVersion,
        4,
      );
    },
  );
  test(
    'four reviewed USDA rows have exact nutrient identities and real zero',
    () {
      final rows =
          (jsonDecode(
                    File(
                      'data/food_catalog/legacy_usda.json',
                    ).readAsStringSync(),
                  )['foods']
                  as List)
              .cast<Map<String, dynamic>>();
      const expected = {
        'rice-cooked': .4,
        'banana-raw': 2.6,
        'apple-raw-skin': 2.4,
        'egg-boiled': 0.0,
      };
      expect(rows.length, 4);
      for (final row in rows) {
        final food = readCatalogFood(row['id'] as String, row);
        expect(food.per100g.fiberG, expected[food.id]);
        expect(food.per100g.fiberKnown, true);
        expect(
          row['fiberSourceUrl'],
          startsWith('https://fdc.nal.usda.gov/food-details/'),
        );
        expect(row['sourceDetails']['nutrientId'], 1079);
        expect(
          food.forGrams(250).fiberG,
          closeTo(expected[food.id]! * 2.5, 1e-9),
        );
        expect(
          readCatalogFood(
            food.id,
            {...row}..remove('fiberGPer100g'),
          ).per100g.fiberKnown,
          false,
        );
      }
    },
  );
}
