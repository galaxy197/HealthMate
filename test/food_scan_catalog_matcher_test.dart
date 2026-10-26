import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/food_scanner/models/food_scan_catalog_matcher.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'support/fake_nutrition_repository.dart';

void main() {
  const rice = FakeNutritionRepository.rice;
  test('whole dish cannot match a component or its broad alias', () {
    for (final dish in [
      'Cơm tấm sườn bì chả',
      'Cơm trắng chín với trứng',
      'Trứng gà luộc và cơm',
      'Bít tết kèm khoai tây chiên',
    ]) {
      expect(
        FoodScanCatalogMatcher.matches(dish, [
          rice,
          FakeNutritionRepository.egg,
        ]),
        isEmpty,
      );
    }
  });
  test(
    'whole name and whole alias match across Vietnamese accents and spacing',
    () {
      for (final dish in [
        '  COM   TRANG CHIN  ',
        'Cơm trắng chín',
        'white rice',
        'co\u031bm tra\u0306\u0301ng chi\u0301n',
      ]) {
        expect(FoodScanCatalogMatcher.matches(dish, [rice]).single.id, rice.id);
      }
      expect(FoodScanCatalogMatcher.matches('  ', [rice]), isEmpty);
    },
  );
  test(
    'multiple whole-dish matches remain ambiguous regardless of catalog order',
    () {
      const other = FoodCatalogItem(
        id: 'other',
        name: 'Cơm khác',
        alternateNames: ['Cơm trắng chín'],
        category: 'Ngũ cốc',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Thử',
        isEstimated: true,
      );
      for (final catalog in [
        [rice, other],
        [other, rice],
      ]) {
        expect(
          FoodScanCatalogMatcher.matches('Cơm trắng chín', catalog),
          hasLength(2),
        );
      }
    },
  );
  test('duplicate references do not create false ambiguity', () {
    expect(
      FoodScanCatalogMatcher.matches(rice.name, [rice, rice]),
      hasLength(1),
    );
  });
}
