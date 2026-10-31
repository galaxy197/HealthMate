import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/extra_nutrients.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/meal_templates/models/meal_template.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'support/fake_account_data_repository.dart';

const nutrientFood = FoodCatalogItem(
  id: 'fixture',
  name: 'Món thử',
  category: 'Test',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Synthetic',
  isEstimated: true,
  per100g: NutritionTotals(
    kcal: 100,
    proteinG: 10,
    carbsG: 10,
    fatG: 2,
    fiberG: 0,
    fiberKnown: true,
    extraNutrients: {'sodium': 120, 'sugar': 0, 'iron': 1.25},
  ),
);

class FakeWellnessDevice extends WellnessDevice {
  @override
  bool get supported => true;
  String? active;
  bool granted = false;
  int writes = 0;
  final settings = <String, List<MealReminder>>{};
  @override
  Future<SleepReminder> readSleepReminder(String uid) async =>
      const SleepReminder();
  @override
  Future<void> setAccount(String? uid) async {
    active = uid;
  }

  @override
  Future<List<MealReminder>> readSettings(String uid) async =>
      settings[uid] ?? defaultMealReminders;
  @override
  Future<bool> notificationsAllowed() async => granted;
  @override
  Future<bool> requestNotifications() async => granted;
  @override
  Future<void> saveSettings(String uid, List<MealReminder> values) async {
    expect(uid, active);
    writes++;
    settings[uid] = values;
  }
}

Widget shell(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('vi')],
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('nutrient vector normalizes negative zero for Firestore rules', () {
    expect(
      encodeExtraNutrients({'sugar': -0.0}),
      '[0.000000,null,null,null,null,null,null,null]',
    );
    expect(readExtraNutrients(encodeExtraNutrients({'sugar': -0.0})), {
      'sugar': 0.0,
    });
  });
  test(
    'six-ingredient recipe preserves per-ingredient nutrients through reload and yield changes',
    () {
      final recipe = FoodRecipe(
        id: 'r',
        name: 'Công thức thử',
        ingredients: List.filled(
          6,
          MealItemSnapshot.fromCatalog(nutrientFood, 100),
        ),
        yieldGrams: 500,
      );
      final data = recipe.toData();
      expect(data['schemaVersion'], 3);
      final restored = FoodRecipe.fromData(
        'r',
        Map<String, dynamic>.from(data),
      );
      expect(restored.ingredients.last.nutrition.extraNutrients['sodium'], 120);
      expect(restored.asFood().forGrams(250).extraNutrients['sodium'], 360);
      final changed = FoodRecipe(
        id: 'r',
        name: 'Changed',
        ingredients: restored.ingredients,
        yieldGrams: 1000,
        minimumSchemaVersion: restored.minimumSchemaVersion,
      );
      expect(changed.asFood().forGrams(250).extraNutrients['sodium'], 180);
    },
  );
  test('micronutrient wire retains zero, missing values and portion units', () {
    final item = MealItemSnapshot.fromCatalog(nutrientFood, 150);
    final restored = MealItemSnapshot.fromCompactData(
      Map<String, dynamic>.from(item.toCompactData()),
    );
    expect(restored.grams, 150);
    expect(restored.nutrition.extraNutrients['sodium'], 180);
    expect(restored.nutrition.extraNutrients['sugar'], 0);
    expect(restored.nutrition.extraNutrients.containsKey('vitaminC'), false);
    expect(restored.nutrition.extraNutrients['iron'], closeTo(1.875, 1e-6));
    expect(restored.withQuantity(75).nutrition.extraNutrients['sodium'], 90);
  });
  test(
    'extended totals remain unknown when one contributing food lacks a nutrient',
    () {
      final known = nutrientFood.nutritionPer100g;
      final mixed =
          known + const NutritionTotals(kcal: 50, extraNutrients: {'sugar': 2});
      expect(mixed.extraNutrients['sugar'], 2);
      expect(mixed.extraNutrients.containsKey('sodium'), false);
      expect(
        readExtraNutrients({'sodium': -1, 'iron': double.nan, 'vitaminC': 0}),
        {'vitaminC': 0},
      );
      expect(readExtraNutrients('[0,1]'), isEmpty);
      expect(encodeExtraNutrients({'sugar': 0}), startsWith('[0.000000,null,'));
    },
  );
  test(
    'five enriched templates roundtrip volume, null macros and zero fiber',
    () {
      final item = MealItemSnapshot(
        foodId: 'volume',
        name: 'Nhãn',
        grams: 0,
        quantityUnit: 'ml',
        quantityValue: 250,
        sourceLabel: 'Synthetic',
        isEstimated: true,
        nutrition: const NutritionTotals(
          kcal: 100,
          proteinKnown: false,
          fiberKnown: true,
          extraNutrients: {'sodium': 80},
        ),
      );
      final t = MealTemplate(
        id: 't',
        name: 'Bữa mẫu',
        items: List.filled(5, item),
      );
      final data = t.toData();
      expect(data['schemaVersion'], 4);
      final restored = MealTemplate.fromData(
        't',
        Map<String, dynamic>.from(data),
      );
      expect(restored.items.length, 5);
      expect(restored.items.first.quantityUnit, 'ml');
      expect(restored.items.first.nutrition.proteinKnown, false);
      expect(restored.items.first.nutrition.fiberKnown, true);
      expect(restored.items.first.nutrition.extraNutrients['sodium'], 80);
    },
  );
  test(
    'Vietnamese asset has sources, reference portions and unaccented search',
    () async {
      final foods = await loadBundledVietnameseFoods();
      expect(foods.length, greaterThan(7000));
      expect(foods.map((f) => f.id).toSet().length, foods.length);
      final meal = foods.singleWhere((f) => f.id == 'vn-com-suon-trung');
      expect(meal.hasValidServing, true);
      expect(meal.servingGrams, 450);
      expect(meal.isEstimated, true);
      expect(meal.sourceLabel, contains('VDD'));
      expect(
        searchFoodCatalog(foods, 'com tam suon trung').map((f) => f.id),
        contains('vn-com-suon-trung'),
      );
      final pho = foods.singleWhere((f) => f.id == 'vn-pho-bo');
      expect(pho.servingGrams, 600);
      expect(
        pho.forGrams(150).kcal,
        closeTo(pho.nutritionPer100g.kcal * 1.5, 1e-9),
      );
      expect(pho.nutritionPer100g.extraNutrients, isEmpty);
    },
  );
  test(
    'manual sleep supports midnight and rejects impossible or future durations',
    () {
      final now = DateTime(2026, 10, 26, 8);
      final start = DateTime(2026, 10, 25, 23);
      expect(SleepLog.validate(start, now, now), isNull);
      expect(
        SleepLog(
          id: 's',
          start: start,
          end: now,
          source: 'manual_timer',
        ).duration.inHours,
        9,
      );
      expect(SleepLog.validate(now, start, now), isNotNull);
      expect(
        SleepLog.validate(now.subtract(const Duration(hours: 25)), now, now),
        isNotNull,
      );
      expect(
        SleepLog.validate(start, now.add(const Duration(hours: 1)), now),
        isNotNull,
      );
    },
  );
  test('reminders validate time, meal and opt-in defaults', () {
    expect(defaultMealReminders.every((r) => !r.enabled), true);
    expect(defaultMealReminders.map((r) => r.meal).toSet().length, 4);
    expect(
      MealReminder.fromData({
        'meal': 'lunch',
        'minute': 720,
        'enabled': true,
      }).minute,
      720,
    );
    expect(
      () => MealReminder.fromData({
        'meal': 'lunch',
        'minute': 1440,
        'enabled': true,
      }),
      throwsFormatException,
    );
    expect(
      () => MealReminder.fromData({
        'meal': 'lunch',
        'minute': -1,
        'enabled': true,
      }),
      throwsFormatException,
    );
  });
  test(
    'permission denial keeps reminders off, account change loads only own settings',
    () async {
      final sessions = StreamController<AuthUser?>();
      final device = FakeWellnessDevice();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => sessions.stream),
          // Native activation now requires the deletion repository's confirmed
          // state. Keep that real provider dependency with a fake data source;
          // this unit test never initializes a live Firebase backend.
          accountDataRepositoryProvider.overrideWithValue(
            FakeAccountDataRepository(),
          ),
          wellnessDeviceProvider.overrideWithValue(device),
        ],
      );
      final listen = container.listen(localWellnessProvider, (_, _) {});
      addTearDown(() async {
        listen.close();
        container.dispose();
        await sessions.close();
      });
      sessions.add(
        const AuthUser(
          uid: 'alice',
          email: 'a@test.example',
          emailVerified: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await container.read(localWellnessProvider.future);
      final values = [
        for (final r in defaultMealReminders)
          MealReminder(r.meal, r.minute, enabled: true),
      ];
      await expectLater(
        container.read(localWellnessProvider.notifier).saveReminders(values),
        throwsFormatException,
      );
      expect(device.writes, 0);
      expect(
        container
            .read(localWellnessProvider)
            .value!
            .reminders
            .every((r) => !r.enabled),
        true,
      );
      device.granted = true;
      await container
          .read(localWellnessProvider.notifier)
          .saveReminders(values);
      expect(device.writes, 1);
      sessions.add(
        const AuthUser(
          uid: 'bob',
          email: 'b@test.example',
          emailVerified: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final state = await container.read(localWellnessProvider.future);
      expect(state.uid, 'bob');
      expect(state.reminders.every((r) => !r.enabled), true);
      expect(device.active, 'bob');
    },
  );
  testWidgets(
    'sleep confirmation retains entered times after failed save and retries same values',
    (tester) async {
      final now = DateTime.now();
      var calls = 0;
      final attempts = <(DateTime, DateTime)>[];
      await tester.pumpWidget(
        shell(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => SleepTimeDialog(
                    start: now.subtract(const Duration(hours: 8)),
                    end: now,
                    onSave: (times) async {
                      attempts.add(times);
                      calls++;
                      return calls > 1;
                    },
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-sleep')));
      await tester.pumpAndSettle();
      expect(find.byType(SleepTimeDialog), findsOneWidget);
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-sleep')));
      await tester.pumpAndSettle();
      expect(find.byType(SleepTimeDialog), findsNothing);
      expect(attempts, hasLength(2));
      expect(attempts[0], attempts[1]);
    },
  );
  testWidgets(
    'future meal plan keeps its draft on failed save and never auto-logs',
    (tester) async {
      var calls = 0;
      MealDraft? saved;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(
        shell(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PlanMealDialog(
                    date: tomorrow,
                    type: MealType.lunch,
                    catalog: const [nutrientFood],
                    items: [MealItemSnapshot.fromCatalog(nutrientFood, 150)],
                    onSave: (draft) async {
                      calls++;
                      if (calls == 1) return false;
                      saved = draft;
                      return true;
                    },
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal-plan')));
      await tester.pumpAndSettle();
      expect(find.byType(PlanMealDialog), findsOneWidget);
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-meal-plan')));
      await tester.pumpAndSettle();
      expect(find.byType(PlanMealDialog), findsNothing);
      expect(saved!.items.single.grams, 150);
      expect(saved!.consumedAt.day, tomorrow.day);
      expect(saved!.totals.extraNutrients['sodium'], 180);
    },
  );
}
