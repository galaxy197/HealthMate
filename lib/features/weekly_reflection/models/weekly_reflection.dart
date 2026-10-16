import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../water/models/water_log.dart';
import '../../activity/models/activity_log.dart';
import '../../profile/models/body_metric.dart';

DateTime weekStart(DateTime date) {
  final day = localDateOnly(date);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

class WeekLogs {
  const WeekLogs({
    required this.meals,
    required this.water,
    required this.activities,
    required this.loadedAt,
    this.metrics = const [],
  });
  final List<MealLog> meals;
  final List<WaterLog> water;
  final List<ActivityLog> activities;
  final DateTime loadedAt;
  final List<BodyMetric> metrics;
}

class DayReflection {
  const DayReflection({
    required this.date,
    required this.nutrition,
    required this.mealCount,
    required this.waterMl,
    required this.waterCount,
    required this.activityMinutes,
    required this.activityCount,
    required this.isFuture,
  });
  final DateTime date;
  final NutritionTotals nutrition;
  final int mealCount, waterMl, waterCount, activityMinutes, activityCount;
  final bool isFuture;
  bool get hasLogs => mealCount + waterCount + activityCount > 0;
}

class WeeklyReflection {
  const WeeklyReflection({required this.days, required this.metrics});
  final List<DayReflection> days;
  final List<BodyMetric> metrics;
  bool get hasLogs => days.any((day) => day.hasLogs);
  int get eligibleDays => days.where((day) => !day.isFuture).length;
  int get mealDays => days.where((day) => day.mealCount > 0).length;
  int get waterDays => days.where((day) => day.waterCount > 0).length;
  int get activityDays => days.where((day) => day.activityCount > 0).length;
  NutritionTotals get nutrition =>
      days.fold(const NutritionTotals(), (sum, day) => sum + day.nutrition);
  int get waterMl => days.fold(0, (sum, day) => sum + day.waterMl);
  int get activityMinutes =>
      days.fold(0, (sum, day) => sum + day.activityMinutes);
  double? get averageKcalPerRecordedDay =>
      mealDays == 0 ? null : nutrition.kcal / mealDays;
  double? get weightChange => metrics.length < 2
      ? null
      : metrics.last.weightKg - metrics.first.weightKg;
}

WeeklyReflection summarizeWeek(
  DateTime start,
  DateTime today,
  WeekLogs logs, {
  List<BodyMetric>? metrics,
}) {
  final first = localDateOnly(start);
  final end = DateTime(first.year, first.month, first.day + 7);
  final days = <DayReflection>[];
  final seenMeals = <String>{},
      seenWater = <String>{},
      seenActivities = <String>{};
  final meals = logs.meals.where((m) => seenMeals.add(m.id)).toList();
  final water = logs.water.where((w) => seenWater.add(w.id)).toList();
  final activities = logs.activities
      .where((a) => seenActivities.add(a.id))
      .toList();
  for (var i = 0; i < 7; i++) {
    final date = DateTime(first.year, first.month, first.day + i);
    final key = localDateKey(date);
    final future = date.isAfter(localDateOnly(today));
    final dayMeals = future
        ? <MealLog>[]
        : meals
              .where((m) => (m.dateKey ?? localDateKey(m.consumedAt)) == key)
              .toList();
    final dayWater = future
        ? <WaterLog>[]
        : water.where((w) => w.dateKey == key).toList();
    final dayActivities = future
        ? <ActivityLog>[]
        : activities.where((a) => a.dateKey == key).toList();
    days.add(
      DayReflection(
        date: date,
        nutrition: totalMealNutrition(dayMeals),
        mealCount: dayMeals.length,
        waterMl: totalWaterMl(dayWater),
        waterCount: dayWater.length,
        activityMinutes: totalActivityMinutes(dayActivities),
        activityCount: dayActivities.length,
        isFuture: future,
      ),
    );
  }
  final ordered =
      (metrics ?? logs.metrics)
          .where(
            (m) =>
                !m.measuredAt.isBefore(first) &&
                m.measuredAt.isBefore(end) &&
                m.measuredAt.isBefore(localDayRange(today).end),
          )
          .toList()
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  return WeeklyReflection(days: days, metrics: ordered);
}
