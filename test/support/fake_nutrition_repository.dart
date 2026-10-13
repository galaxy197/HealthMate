import 'dart:async';

import 'package:healthmate/features/nutrition/data/nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

class FakeNutritionRepository implements NutritionRepository {
  FakeNutritionRepository({List<MealLog>? meals}) : _meals = [...?meals];

  static const rice = FoodCatalogItem(
    id: 'rice-cooked',
    name: 'Cơm trắng chín',
    alternateNames: ['cơm', 'white rice'],
    category: 'Ngũ cốc',
    servingBasis: 'per_100g',
    unit: 'g',
    per100g: NutritionTotals(
      kcal: 130,
      proteinG: 2.69,
      carbsG: 28.17,
      fatG: 0.28,
    ),
    sourceLabel: 'USDA FoodData Central — tham khảo/100 g',
    isEstimated: true,
  );

  static const egg = FoodCatalogItem(
    id: 'egg-boiled',
    name: 'Trứng gà luộc',
    alternateNames: ['trứng luộc', 'boiled egg'],
    category: 'Trứng',
    servingBasis: 'per_100g',
    unit: 'g',
    per100g: NutritionTotals(
      kcal: 155,
      proteinG: 12.58,
      carbsG: 1.12,
      fatG: 10.61,
    ),
    sourceLabel: 'USDA FoodData Central — tham khảo/100 g',
    isEstimated: true,
  );

  final List<MealLog> _meals;
  final _changes = StreamController<List<MealLog>>.broadcast();
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() =>
      Stream.value(const [rice, egg]);

  @override
  Stream<List<MealLog>> watchMealLogs(String uid) => Stream.multi((controller) {
    controller.add(List.unmodifiable(_meals));
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
  }) async {
    addCalls++;
    final id = 'meal-$addCalls';
    _meals.add(_toLog(id, draft));
    _emit();
    return id;
  }

  @override
  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  }) async {
    updateCalls++;
    final index = _meals.indexWhere((meal) => meal.id == mealId);
    if (index >= 0) _meals[index] = _toLog(mealId, draft);
    _emit();
  }

  @override
  Future<void> deleteMeal({required String uid, required String mealId}) async {
    deleteCalls++;
    _meals.removeWhere((meal) => meal.id == mealId);
    _emit();
  }

  MealLog _toLog(String id, MealDraft draft) => MealLog(
    id: id,
    type: draft.type,
    consumedAt: draft.consumedAt,
    items: draft.items,
    totals: draft.totals,
    source: draft.source,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  void _emit() {
    _meals.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    _changes.add(List.unmodifiable(_meals));
  }

  Future<void> dispose() => _changes.close();
}
