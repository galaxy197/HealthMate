class NutritionTotals {
  const NutritionTotals({
    this.kcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
  );

  NutritionTotals scale(double factor) => NutritionTotals(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
  );
}

class FoodCatalogItem {
  const FoodCatalogItem({
    required this.id,
    required this.name,
    required this.alternateNames,
    required this.category,
    required this.servingBasis,
    required this.unit,
    required this.per100g,
    required this.sourceLabel,
    required this.isEstimated,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> alternateNames;
  final String category;
  final String servingBasis;
  final String unit;
  final NutritionTotals per100g;
  final String sourceLabel;
  final bool isEstimated;
  final DateTime? updatedAt;

  NutritionTotals forGrams(double grams) => per100g.scale(grams / 100);
}

enum MealType {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  dinner('Bữa tối'),
  snack('Bữa phụ');

  const MealType(this.label);
  final String label;
}

enum MealSource {
  manual('Nhập thủ công'),
  aiAssisted('Có Gemini hỗ trợ nhận diện');

  const MealSource(this.label);
  final String label;

  String get wireValue => switch (this) {
    MealSource.manual => 'manual',
    MealSource.aiAssisted => 'ai_assisted',
  };
}

class MealItemSnapshot {
  const MealItemSnapshot({
    required this.foodId,
    required this.name,
    required this.grams,
    required this.nutrition,
    required this.sourceLabel,
    required this.isEstimated,
  });

  factory MealItemSnapshot.fromCatalog(FoodCatalogItem food, double grams) =>
      MealItemSnapshot(
        foodId: food.id,
        name: food.name,
        grams: grams,
        nutrition: food.forGrams(grams),
        sourceLabel: food.sourceLabel,
        isEstimated: food.isEstimated,
      );

  final String foodId;
  final String name;
  final double grams;
  final NutritionTotals nutrition;
  final String sourceLabel;
  final bool isEstimated;
}

class MealDraft {
  const MealDraft({
    required this.type,
    required this.consumedAt,
    required this.items,
    required this.source,
  });

  final MealType type;
  final DateTime consumedAt;
  final List<MealItemSnapshot> items;
  final MealSource source;

  NutritionTotals get totals =>
      items.fold(const NutritionTotals(), (sum, item) => sum + item.nutrition);
}

class MealLog {
  const MealLog({
    required this.id,
    required this.type,
    required this.consumedAt,
    required this.items,
    required this.totals,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final MealType type;
  final DateTime consumedAt;
  final List<MealItemSnapshot> items;
  final NutritionTotals totals;
  final MealSource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MealDraft toDraft() => MealDraft(
    type: type,
    consumedAt: consumedAt,
    items: items,
    source: source,
  );
}
