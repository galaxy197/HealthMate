import 'nutrition_models.dart';

/// Preferences restrict discovery, never rewrite or delete an existing meal.
enum FoodDietPreference {
  general('Tất cả chế độ'),
  vegetarian('Chay có trứng/sữa'),
  vegan('Thuần chay');

  const FoodDietPreference(this.label);
  final String label;

  static FoodDietPreference fromAnswer(Object? value) => switch (value) {
    'vegetarian' => vegetarian,
    'vegan' => vegan,
    _ => general,
  };

  bool allows(FoodCatalogItem food) => switch (this) {
    general => true,
    vegetarian =>
      food.dietaryClass == FoodDietClass.vegan ||
          food.dietaryClass == FoodDietClass.vegetarian,
    vegan => food.dietaryClass == FoodDietClass.vegan,
  };
}
