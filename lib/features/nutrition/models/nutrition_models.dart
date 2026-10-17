import '../../../core/utils/local_date_key.dart';

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
  aiAssisted('Có hỗ trợ nhận diện');

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
    this.hasNutritionData = true,
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
  final bool hasNutritionData;

  MealItemSnapshot withGrams(double newGrams) {
    final values = [
      grams,
      newGrams,
      nutrition.kcal,
      nutrition.proteinG,
      nutrition.carbsG,
      nutrition.fatG,
    ];
    if (!hasNutritionData ||
        values.any((v) => !v.isFinite) ||
        grams <= 0 ||
        newGrams <= 0 ||
        values.skip(2).any((v) => v < 0)) {
      throw const FormatException(
        'Snapshot dinh dưỡng hoặc khối lượng không hợp lệ.',
      );
    }
    final scaled = nutrition.scale(newGrams / grams);
    if ([
      scaled.kcal,
      scaled.proteinG,
      scaled.carbsG,
      scaled.fatG,
    ].any((v) => !v.isFinite)) {
      throw const FormatException('Không thể tính khẩu phần từ snapshot này.');
    }
    return MealItemSnapshot(
      foodId: foodId,
      name: name,
      grams: newGrams,
      nutrition: scaled,
      sourceLabel: sourceLabel,
      isEstimated: isEstimated,
    );
  }
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

  int get timezoneOffsetMinutes => consumedAt.timeZoneOffset.inMinutes;
  String get dateKey =>
      dateKeyFromTimestampAndOffset(consumedAt, timezoneOffsetMinutes);

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
    this.dateKey,
    this.timezoneOffsetMinutes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final MealType type;
  final DateTime consumedAt;
  final List<MealItemSnapshot> items;
  final NutritionTotals totals;
  final MealSource source;
  final String? dateKey;
  final int? timezoneOffsetMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MealDraft toDraft() => MealDraft(
    type: type,
    consumedAt: consumedAt,
    items: items,
    source: source,
  );
}

List<MealItemSnapshot> recentMealItems(
  Iterable<MealLog> meals, {
  int limit = 8,
}) {
  final seen = <String>{};
  final result = <MealItemSnapshot>[];
  for (final meal in meals) {
    for (final item in meal.items) {
      final key = item.foodId.isNotEmpty
          ? item.foodId
          : item.name.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      result.add(item);
      if (result.length == limit) return List.unmodifiable(result);
    }
  }
  return List.unmodifiable(result);
}

NutritionTotals totalMealNutrition(Iterable<MealLog> meals) =>
    meals.fold(const NutritionTotals(), (sum, meal) => sum + meal.totals);
