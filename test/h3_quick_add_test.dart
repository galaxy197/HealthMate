import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/quick_add_dialog.dart';
import 'package:healthmate/features/food_library/presentation/food_nutrition_text.dart';
import 'package:healthmate/features/meal_templates/models/meal_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/features/journal/presentation/journal_nutrition_overview.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';

void main() {
  const quick = MealItemSnapshot(
    foodId: 'qa-quick',
    name: 'QA only kcal',
    grams: 0,
    quantityUnit: 'entry',
    quantityValue: 1,
    nutrition: NutritionTotals(
      kcal: 250,
      proteinKnown: false,
      carbsKnown: false,
      fatKnown: false,
    ),
    sourceLabel: 'QA synthetic',
    isEstimated: true,
  );
  testWidgets(
    'daily overview keeps kcal and marks unknown macros instead of zero',
    (tester) async {
      final day = DateTime(2026, 10, 19);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionTargetProvider(
              '2026-10-19',
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: JournalNutritionOverview(
                  day: day,
                  meals: AsyncData([
                    MealLog(
                      id: 'q',
                      type: MealType.lunch,
                      consumedAt: day,
                      items: const [quick],
                      totals: quick.nutrition,
                      source: MealSource.manual,
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('250 kcal / — kcal'), findsOneWidget);
      expect(find.text('— / — g'), findsNWidgets(3));
      expect(find.textContaining('Dấu — không có nghĩa là 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'unknown nutrients serialize null, preserve zero, and aggregate known subtotals with coverage',
    () {
      expect(quick.toData()['grams'], isNull);
      expect(quick.toData()['proteinG'], isNull);
      final loaded = MealItemSnapshot.fromData(
        Map<String, dynamic>.from(quick.toData()),
        allowPartial: true,
      );
      expect(loaded.hasNutritionData, isTrue);
      expect(loaded.quantity, 1);
      expect(loaded.nutrition.proteinKnown, isFalse);
      final total =
          loaded.nutrition + const NutritionTotals(kcal: 100, proteinG: 10);
      expect(total.kcal, 350);
      expect(total.proteinG, 10);
      expect(total.proteinKnown, isFalse);
      expect(nutritionLabel(total), contains('≥10 g (chưa đủ)'));
      expect(nutritionLabel(loaded.nutrition), isNot(contains('Đạm 0')));
      final zero = MealItemSnapshot.fromData({
        ...quick.toData(),
        'proteinG': 0,
      }, allowPartial: true);
      expect(zero.nutrition.proteinKnown, isTrue);
      expect(zero.nutrition.carbsKnown, isFalse);
      expect(loaded.withQuantity(2).nutrition.kcal, 500);
      expect(() => loaded.withGrams(100), throwsFormatException);
      expect(() => loaded.withQuantity(double.nan), throwsFormatException);
    },
  );
  test('legacy snapshots, copies and named templates remain compatible', () {
    final old = MealItemSnapshot.fromData({
      'foodId': 'old',
      'name': 'Old',
      'grams': 100,
      'kcal': 130,
      'proteinG': 3,
      'carbsG': 28,
      'fatG': .3,
      'sourceLabel': 'Old',
      'isEstimated': true,
    });
    expect(old.hasNutritionData, isTrue);
    expect(old.nutrition.hasCompleteMacros, isTrue);
    expect(old.toData().containsKey('quantityUnit'), isFalse);
    expect(
      MealItemSnapshot.fromData(
        {...old.toData()}..remove('fatG'),
      ).hasNutritionData,
      isFalse,
    );
    final template = MealTemplate(
      id: 't',
      name: 'Quick template',
      items: [quick, old],
    );
    expect(template.toData()['schemaVersion'], 2);
    final read = MealTemplate.fromData(
      't',
      Map<String, dynamic>.from(template.toData()),
    );
    expect(read.items.first.quantityUnit, 'entry');
    expect(read.items.first.nutrition.proteinKnown, isFalse);
    final meal = MealLog(
      id: 'm',
      type: MealType.lunch,
      consumedAt: DateTime(2026, 1, 1, 12),
      items: read.items,
      totals: quick.nutrition + old.nutrition,
      source: MealSource.manual,
    );
    final copy = meal.copyDraft(
      day: DateTime(2025, 12, 31),
      now: DateTime(2026, 1, 2),
    );
    expect(copy.items.first.toData(), quick.toData());
  });
  for (final basis in LabelBasis.values) {
    testWidgets(
      'label basis ${basis.name} has real quantity, optional macros and validation',
      (tester) async {
        MealItemSnapshot? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<MealItemSnapshot>(
                      context: context,
                      builder: (_) => const QuickAddDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (basis != LabelBasis.total) {
          await tester.tap(find.byKey(const ValueKey('quick-basis')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(basis.label).last);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('quick-amount')),
            basis == LabelBasis.serving ? '0,5' : '250',
          );
        }
        await tester.ensureVisible(find.byKey(const ValueKey('quick-kcal')));
        await tester.enterText(find.byKey(const ValueKey('quick-kcal')), '-1');
        await tester.tap(find.byKey(const ValueKey('confirm-quick-add')));
        await tester.pumpAndSettle();
        expect(find.byType(QuickAddDialog), findsOneWidget);
        await tester.enterText(find.byKey(const ValueKey('quick-kcal')), '100');
        final fiber = find.byKey(const ValueKey('quick-fiber'));
        await tester.ensureVisible(fiber);
        await tester.enterText(fiber, '2');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-quick-add')));
        await tester.pumpAndSettle();
        expect(
          result!.nutrition.kcal,
          basis == LabelBasis.total
              ? 100
              : basis == LabelBasis.serving
              ? 50
              : 250,
        );
        expect(result!.nutrition.hasCompleteMacros, isFalse);
        expect(result!.nutrition.fiberKnown, true);
        expect(
          result!.nutrition.fiberG,
          basis == LabelBasis.total
              ? 2
              : basis == LabelBasis.serving
              ? 1
              : 5,
        );
        expect(result!.quantityUnit, basis.unit);
        expect(
          result!.toData()['grams'],
          basis == LabelBasis.per100g ? 250 : null,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final (width, scale) in [(360.0, 1.0), (390.0, 1.5), (412.0, 2.0)]) {
    for (final brightness in Brightness.values) {
      testWidgets('quick add completes $width / $scale / $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        MealItemSnapshot? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<MealItemSnapshot>(
                      context: context,
                      builder: (_) => const QuickAddDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final kcal = find.byKey(const ValueKey('quick-kcal'));
        await tester.scrollUntilVisible(
          kcal,
          160,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.enterText(kcal, '123');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-quick-add')));
        await tester.pumpAndSettle();
        expect(result?.nutrition.kcal, 123);
        expect(result?.nutrition.proteinKnown, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
