import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../../core/data/bounded_range.dart';

const maxReportDays = 366;

class ReportRange {
  const ReportRange(this.end, this.days);
  factory ReportRange.inclusive(DateTime first, DateTime last) {
    final start = localDateOnly(first);
    final end = DateTime(last.year, last.month, last.day + 1);
    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    final range = ReportRange(end, days);
    range.validate();
    return range;
  }

  factory ReportRange.year(int year, DateTime today) {
    if (year < 1900 || year > today.year) {
      throw const RangeReadFailure('Chọn năm từ 1900 đến năm hiện tại.');
    }
    return ReportRange.inclusive(
      DateTime(year),
      year == today.year ? localDateOnly(today) : DateTime(year, 12, 31),
    );
  }
  final DateTime end;
  final int days;
  DateTime get start => DateTime(end.year, end.month, end.day - days);
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);
  void validate() {
    if (days < 1 ||
        days > maxReportDays ||
        end != localDateOnly(end) ||
        start.year < 1900) {
      throw const RangeReadFailure(
        'Chọn khoảng từ 1 đến 366 ngày, bắt đầu từ năm 1900.',
      );
    }
  }

  /// Repositories retain their 90-day/2,000-record safety bounds.
  List<ReportRange> get chunks {
    validate();
    final result = <ReportRange>[];
    var cursor = start;
    var remaining = days;
    while (remaining > 0) {
      final count = remaining > 90 ? 90 : remaining;
      final next = DateTime(cursor.year, cursor.month, cursor.day + count);
      result.add(ReportRange(next, count));
      cursor = next;
      remaining -= count;
    }
    return result;
  }

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
  late final List<DateTime> dates = [
    for (var i = 0; i < range.days; i++)
      DateTime(range.start.year, range.start.month, range.start.day + i),
  ].where((d) => !d.isAfter(localDateOnly(today))).toList();
  late final Map<String, List<MealLog>> _byDay = () {
    final result = <String, List<MealLog>>{};
    for (final meal in meals) {
      final key = meal.dateKey ?? localDateKey(meal.consumedAt.toLocal());
      result.putIfAbsent(key, () => []).add(meal);
    }
    return result;
  }();
  List<MealLog> logs(DateTime day) => _byDay[localDateKey(day)] ?? const [];
  late final Map<String, DayReview> _reviewByDay = {
    for (final r in reviews) r.dateKey: r,
  };
  bool confirmed(DateTime day) =>
      _reviewByDay[localDateKey(day)]?.matches(logs(day)) == true;
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
