import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';

class ReportRange {
  const ReportRange(this.end, this.days);
  final DateTime end;
  final int days;
  DateTime get start => DateTime(end.year, end.month, end.day - days);
  @override
  bool operator ==(Object other) =>
      other is ReportRange && other.end == end && other.days == days;
  @override
  int get hashCode => Object.hash(end, days);
}

List<MealLog> mealsForDay(Iterable<MealLog> meals, String key) => meals
    .where((m) => (m.dateKey ?? localDateKey(m.consumedAt.toLocal())) == key)
    .toList();

DateTime? latestMealRevision(Iterable<MealLog> meals) {
  DateTime? latest;
  for (final m in meals) {
    final time = (m.updatedAt ?? m.createdAt ?? m.consumedAt).toUtc();
    if (latest == null || time.isAfter(latest)) latest = time;
  }
  return latest;
}

class DayReview {
  const DayReview({
    required this.dateKey,
    required this.complete,
    required this.mealCount,
    required this.latestMealUpdate,
  });
  final String dateKey;
  final bool complete;
  final int mealCount;
  final DateTime? latestMealUpdate;
  bool matches(List<MealLog> meals) =>
      complete &&
      meals.length == mealCount &&
      latestMealRevision(meals) == latestMealUpdate;
}

class RecordingCoverage {
  RecordingCoverage({
    required this.range,
    required this.today,
    required List<MealLog> meals,
    required this.reviews,
  }) : meals = {for (final m in meals) m.id: m}.values.toList();
  final ReportRange range;
  final DateTime today;
  final List<MealLog> meals;
  final List<DayReview> reviews;
  List<DateTime> get dates => [
    for (var i = 0; i < range.days; i++)
      DateTime(range.start.year, range.start.month, range.start.day + i),
  ].where((d) => !d.isAfter(localDateOnly(today))).toList();
  List<MealLog> logs(DateTime day) => mealsForDay(meals, localDateKey(day));
  bool confirmed(DateTime day) => reviews.any(
    (r) => r.dateKey == localDateKey(day) && r.matches(logs(day)),
  );
  int get recordedDays => dates.where((d) => logs(d).isNotEmpty).length;
  int get confirmedRecordedDays =>
      dates.where((d) => logs(d).isNotEmpty && confirmed(d)).length;
  int get partialDays => recordedDays - confirmedRecordedDays;
  int get unrecordedDays => dates.length - recordedDays;
  double? get confirmedAverageKcal {
    final days = dates
        .where((d) => logs(d).isNotEmpty && confirmed(d))
        .toList();
    return days.isEmpty
        ? null
        : days.fold(0.0, (sum, d) => sum + totalMealNutrition(logs(d)).kcal) /
              days.length;
  }
}
