import '../models/nutrition_models.dart';

abstract interface class NutritionRepository {
  Stream<List<FoodCatalogItem>> watchFoodCatalog();

  Stream<List<MealLog>> watchMealLogs(String uid, DateTime localDate);

  Stream<List<MealLog>> watchRecentMeals(String uid, {int limit = 20});

  /// One-shot local-date range [start, end), including legacy meals.
  Future<List<MealLog>> loadRange(String uid, DateTime start, DateTime end);

  Future<String> addMeal({required String uid, required MealDraft draft});

  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  });

  Future<void> deleteMeal({required String uid, required String mealId});
}
