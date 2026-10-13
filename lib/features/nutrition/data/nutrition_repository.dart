import '../models/nutrition_models.dart';

abstract interface class NutritionRepository {
  Stream<List<FoodCatalogItem>> watchFoodCatalog();

  Stream<List<MealLog>> watchMealLogs(String uid);

  Future<String> addMeal({required String uid, required MealDraft draft});

  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  });

  Future<void> deleteMeal({required String uid, required String mealId});
}
