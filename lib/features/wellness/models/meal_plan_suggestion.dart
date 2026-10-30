import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/food_avoidance.dart';
import '../../nutrition/models/food_diet.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import 'wellness_models.dart';

class MealPlanSuggestion {
  const MealPlanSuggestion(this.drafts, this.summaries);
  final List<MealDraft> drafts;
  final List<MealPlanDaySummary> summaries;
}

class MealPlanDaySummary {
  const MealPlanDaySummary(this.date, this.targetKcal, this.plannedKcal);
  final DateTime date;
  final double? targetKcal;
  final double plannedKcal;
  bool get outsideTarget =>
      targetKcal != null &&
      (plannedKcal - targetKcal!).abs() > targetKcal! * .05;
}

/// Bounded portion fitting against confirmed targets; no medical optimization.
MealPlanSuggestion suggestMealPlan({
  required DateTime start,
  required List<FoodCatalogItem> catalog,
  required List<PlannedMeal> existing,
  required List<NutritionTarget> targets,
  FoodDietPreference diet = FoodDietPreference.general,
  FoodAvoidance avoidance = const FoodAvoidance.none(),
}) {
  final mains = catalog
      .where(
        (f) =>
            f.id.startsWith('vn-') &&
            f.hasNutritionData &&
            f.hasValidServing &&
            diet.allows(f) &&
            avoidance.allows(f) &&
            f.forGrams(f.servingGrams!).kcal >= 60,
      )
      .toList();
  if (mains.isEmpty) {
    throw const FormatException(
      'Chưa đủ món có thành phần/khẩu phần phù hợp để gợi ý.',
    );
  }
  // Ready-to-eat reference sides only; never suggest raw meat as a snack.
  final sides = catalog
      .where(
        (f) =>
            (f.category == 'Trái cây' ||
                f.category == 'Hạt và đậu' ||
                f.name.toLowerCase().startsWith('sữa chua')) &&
            (!f.id.startsWith('usda-') ||
                (f.category == 'Trái cây' &&
                    RegExp(
                      r'^(Apples|Bananas|Pears|Grapes|Oranges|Mangos|Papayas|Strawberries|Melons|Peaches|Plums|Pineapple|Tangerines|Kiwifruit),.*\braw\b',
                      caseSensitive: false,
                    ).hasMatch(f.originalName ?? ''))) &&
            !f.id.startsWith('vn-') &&
            f.hasNutritionData &&
            f.hasValidServing &&
            diet.allows(f) &&
            avoidance.allows(f) &&
            !RegExp('khô|bột').hasMatch(f.name.toLowerCase()) &&
            f.forGrams(f.servingGrams!).kcal >= 40,
      )
      .take(30)
      .toList();
  final drafts = <MealDraft>[];
  final summaries = <MealPlanDaySummary>[];
  const shares = {
    MealType.breakfast: .25,
    MealType.lunch: .35,
    MealType.dinner: .30,
    MealType.snack: .10,
  };
  for (var day = 0; day < 7; day++) {
    final date = DateTime(start.year, start.month, start.day + day);
    final key = localDateKey(date);
    final fixed = existing.where((p) => localDateKey(p.date) == key).toList();
    final fixedKcal = fixed.fold(0.0, (sum, p) => sum + p.totals.kcal);
    final target = targetForDate(targets, key)?.kcalTarget;
    if (target != null && (!target.isFinite || target <= 0)) {
      throw const FormatException(
        'Mục tiêu kcal chưa hợp lệ. Hãy kiểm tra lại mục tiêu.',
      );
    }
    final missing = shares.keys
        .where((type) => !fixed.any((p) => p.type == type))
        .toList();
    final shareTotal = missing.fold(0.0, (sum, t) => sum + shares[t]!);
    final dayDrafts = <MealDraft>[];
    for (final type in missing) {
      if (target != null && fixedKcal >= target) continue;
      final preferred = mains
          .where(
            (f) => type == MealType.breakfast
                ? RegExp('phở|bún|cháo|bánh mì').hasMatch(f.name.toLowerCase())
                : RegExp('^cơm|^bún|^phở|^mì').hasMatch(f.name.toLowerCase()),
          )
          .toList();
      final pool = type == MealType.snack && sides.isNotEmpty
          ? sides
          : (preferred.isEmpty ? mains : preferred);
      final ordered = [
        ...pool.skip(day % pool.length),
        ...pool.take(day % pool.length),
      ];
      final desired = target == null
          ? null
          : (target - fixedKcal) * shares[type]! / shareTotal;
      final items = desired == null
          ? [
              MealItemSnapshot.fromCatalog(
                ordered.first,
                ordered.first.servingGrams!,
              ),
            ]
          : _fitMeal(ordered, sides, desired);
      dayDrafts.add(
        MealDraft(
          type: type,
          consumedAt: DateTime(date.year, date.month, date.day, switch (type) {
            MealType.breakfast => 7,
            MealType.lunch => 12,
            MealType.dinner => 18,
            MealType.snack => 15,
          }),
          items: items,
          source: MealSource.manual,
        ),
      );
    }
    drafts.addAll(dayDrafts);
    summaries.add(
      MealPlanDaySummary(
        date,
        target,
        fixedKcal + dayDrafts.fold(0.0, (sum, d) => sum + d.totals.kcal),
      ),
    );
  }
  return MealPlanSuggestion(drafts, summaries);
}

List<MealItemSnapshot> _fitMeal(
  List<FoodCatalogItem> mains,
  List<FoodCatalogItem> sides,
  double desired,
) {
  List<MealItemSnapshot>? best;
  var bestScore = double.infinity;
  double gramsFor(FoodCatalogItem food, double kcal) =>
      (kcal / food.nutritionPer100g.kcal * 100)
          .clamp(
            food.servingGrams! * .5,
            (food.servingGrams! * 2).clamp(1, 1000),
          )
          .toDouble();
  for (final food in mains) {
    final main = MealItemSnapshot.fromCatalog(
      food,
      double.parse(gramsFor(food, desired).toStringAsFixed(1)),
    );
    final alternatives = <List<MealItemSnapshot>>[
      [main],
    ];
    for (final side in sides) {
      if (side.id == food.id || desired - main.nutrition.kcal < 30) continue;
      alternatives.add([
        main,
        MealItemSnapshot.fromCatalog(
          side,
          double.parse(
            gramsFor(side, desired - main.nutrition.kcal).toStringAsFixed(1),
          ),
        ),
      ]);
    }
    for (final items in alternatives) {
      final kcal = items.fold(0.0, (sum, i) => sum + i.nutrition.kcal);
      final score = (kcal - desired).abs() + items.length * .05;
      // Keep the rotated choice when fits differ by less than 0.5% (at least
      // 1 kcal), rather than repeating one dish for a rounding difference.
      if (best == null || score < bestScore - (desired * .005).clamp(1, 10)) {
        bestScore = score;
        best = items;
      }
    }
  }
  return best!;
}
