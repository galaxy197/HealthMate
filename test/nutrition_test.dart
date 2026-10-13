import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/nutrition/models/nutrition_validation.dart';

import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

void main() {
  group('nutrition calculations and scanner parsing', () {
    test('scales catalog nutrients from 100 g to the confirmed portion', () {
      final result = FakeNutritionRepository.rice.forGrams(150);
      expect(result.kcal, closeTo(195, 0.001));
      expect(result.proteinG, closeTo(4.035, 0.001));
      expect(result.carbsG, closeTo(42.255, 0.001));
      expect(result.fatG, closeTo(0.42, 0.001));
    });

    test('validates portions and strict Gemini JSON', () {
      expect(NutritionValidation.grams('0'), isNotNull);
      expect(NutritionValidation.grams('150,5'), isNull);
      final suggestion = AiFoodSuggestion.fromJsonText(
        '{"dishName":"Cơm gà","description":"Cơm và thịt gà",'
        '"ingredients":["cơm","gà"],"searchTerms":["cơm","gà"]}',
      );
      expect(suggestion.dishName, 'Cơm gà');
      expect(
        () => AiFoodSuggestion.fromJsonText(
          '{"dishName":"Cơm","description":"Món ăn",'
          '"ingredients":[],"searchTerms":[]}',
        ),
        throwsFormatException,
      );
    });
  });

  testWidgets('adds a meal manually with catalog nutrition', (tester) async {
    final repository = FakeNutritionRepository();
    final container = await pumpApp(tester, nutritionRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'journal');

    expect(find.textContaining('Danh mục có 2 món'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-meal')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'meal form');
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'cơm');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'search');
    await tester.tap(find.byTooltip('Thêm Cơm trắng chín'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'grams dialog');
    await tester.enterText(find.byKey(const ValueKey('meal-grams')), '150');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'portion added');
    expect(find.textContaining('195 kcal'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(find.textContaining('Cơm trắng chín 150 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
