import 'dart:math' as math;
import '../../../core/utils/local_date_key.dart';
import 'wellness_models.dart';

class SleepDaySummary {
  const SleepDaySummary(
    this.day,
    this.minutes,
    this.bedtimeMinute, {
    this.inconsistent = false,
  });
  final DateTime day;
  final double? minutes, bedtimeMinute;
  final bool inconsistent;
}

class SleepSummary {
  const SleepSummary(this.days, this.goalMinutes);
  final List<SleepDaySummary> days;
  final int? goalMinutes;
  int get inconsistentDays => days.where((d) => d.inconsistent).length;
  List<SleepDaySummary> get recorded =>
      days.where((d) => d.minutes != null).toList();
  double? get averageMinutes => recorded.isEmpty
      ? null
      : recorded.fold(0.0, (s, d) => s + d.minutes!) / recorded.length;
  int? get daysAtGoal => goalMinutes == null
      ? null
      : recorded.where((d) => d.minutes! >= goalMinutes!).length;

  /// Circular mean handles 23:50 and 00:10 as twenty minutes apart.
  double? get bedtimeVariationMinutes {
    final values = recorded.map((d) => d.bedtimeMinute!).toList();
    if (values.length < 2) return null;
    final x = values.fold(0.0, (s, m) => s + math.cos(m * 2 * math.pi / 1440));
    final y = values.fold(0.0, (s, m) => s + math.sin(m * 2 * math.pi / 1440));
    if (x.abs() + y.abs() < .000001) return null;
    final mean = (math.atan2(y, x) * 1440 / (2 * math.pi) + 1440) % 1440;
    return values.fold(0.0, (s, m) {
          final d = (m - mean).abs();
          return s + math.min(d, 1440 - d);
        }) /
        values.length;
  }
}

/// Merge overlapping records globally before grouping by local wake-up date.
/// Missing days remain null, never zero. No sleep-stage/quality inference.
SleepSummary summarizeSleep(
  List<SleepLog> logs,
  DateTime start,
  int length, {
  int? goalMinutes,
}) {
  final sorted =
      logs
          .where(
            (l) => SleepLog.validate(l.start, l.end, DateTime(9999)) == null,
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  final intervals = <(DateTime, DateTime)>[];
  for (final log in sorted) {
    if (intervals.isNotEmpty && !log.start.isAfter(intervals.last.$2)) {
      final previous = intervals.removeLast();
      intervals.add((
        previous.$1,
        log.end.isAfter(previous.$2) ? log.end : previous.$2,
      ));
    } else {
      intervals.add((log.start, log.end));
    }
  }
  final grouped = <String, List<(DateTime, DateTime)>>{};
  for (final interval in intervals) {
    grouped
        .putIfAbsent(localDateKey(interval.$2.toLocal()), () => [])
        .add(interval);
  }
  return SleepSummary([
    for (var i = 0; i < length; i++)
      (() {
        final day = DateTime(start.year, start.month, start.day + i),
            values =
                grouped[localDateKey(
                  DateTime(start.year, start.month, start.day + i),
                )];
        if (values == null) return SleepDaySummary(day, null, null);
        // Main interval's bedtime for regularity; naps contribute duration only.
        final main = values.reduce(
          (a, b) => a.$2.difference(a.$1) >= b.$2.difference(b.$1) ? a : b,
        );
        final minutes = values.fold<double>(
          0.0,
          (s, v) => s + v.$2.difference(v.$1).inSeconds / 60,
        );
        if (minutes > 1440) {
          return SleepDaySummary(day, null, null, inconsistent: true);
        }
        return SleepDaySummary(
          day,
          minutes,
          main.$1.toLocal().hour * 60.0 + main.$1.toLocal().minute,
        );
      })(),
  ], goalMinutes);
}
