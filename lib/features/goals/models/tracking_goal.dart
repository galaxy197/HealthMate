import '../../../core/utils/local_date_key.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../profile/models/body_metric.dart';
import '../../water/models/water_log.dart';

enum GoalType {
  meals('Bữa ăn đã ghi', 'bữa', 1, 10),
  water('Nước đã ghi', 'ml', 50, 5000),
  activity('Thời gian vận động', 'phút', 1, 180),
  weight('Cân nặng', 'kg', 20, 500);

  const GoalType(this.label, this.unit, this.min, this.max);
  final String label;
  final String unit;
  final double min;
  final double max;
}

enum GoalStatus {
  active('Đang theo dõi'),
  paused('Tạm dừng'),
  completed('Đã kết thúc');

  const GoalStatus(this.label);
  final String label;
}

class GoalDraft {
  const GoalDraft({
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    this.status = GoalStatus.active,
    this.baselineWeightKg,
  });

  final GoalType type;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final GoalStatus status;
  final double? baselineWeightKg;

  String? validate() {
    if (!targetValue.isFinite ||
        targetValue < type.min ||
        targetValue > type.max) {
      return 'Giá trị cần nằm trong khoảng ${type.min.toInt()}–${type.max.toInt()} ${type.unit}.';
    }
    if (type != GoalType.weight && targetValue != targetValue.roundToDouble()) {
      return 'Vui lòng nhập số nguyên.';
    }
    if (localDateOnly(endDate).isBefore(localDateOnly(startDate))) {
      return 'Ngày kết thúc phải từ ngày bắt đầu trở đi.';
    }
    if (type == GoalType.weight &&
        (baselineWeightKg == null ||
            !baselineWeightKg!.isFinite ||
            baselineWeightKg! < 20 ||
            baselineWeightKg! > 500)) {
      return 'Nhập cân nặng ban đầu từ 20–500 kg.';
    }
    if (type != GoalType.weight && baselineWeightKg != null) {
      return 'Mục tiêu này không dùng cân nặng ban đầu.';
    }
    return null;
  }
}

class TrackingGoal {
  const TrackingGoal({required this.id, required this.draft});
  final String id;
  final GoalDraft draft;

  bool appliesOn(DateTime day) =>
      draft.status == GoalStatus.active &&
      !localDateOnly(day).isBefore(localDateOnly(draft.startDate)) &&
      !localDateOnly(day).isAfter(localDateOnly(draft.endDate));
}

class GoalProgress {
  const GoalProgress({
    required this.value,
    required this.fraction,
    required this.label,
  });
  final double? value;
  final double? fraction;
  final String label;
}

// Daily habits reset each local day. Weight measures distance from a fixed
// baseline, in either direction; it never divides weight by the target weight.
GoalProgress goalProgress(
  TrackingGoal goal,
  DateTime day, {
  required List<MealLog> meals,
  required List<WaterLog> water,
  required List<ActivityLog> activities,
  required List<BodyMetric> metrics,
}) {
  final draft = goal.draft;
  final date = localDateOnly(day);
  if (date.isBefore(localDateOnly(draft.startDate))) {
    return const GoalProgress(
      value: null,
      fraction: null,
      label: 'Chưa bắt đầu',
    );
  }
  if (date.isAfter(localDateOnly(draft.endDate))) {
    return const GoalProgress(
      value: null,
      fraction: null,
      label: 'Đã hết thời hạn',
    );
  }
  if (draft.type == GoalType.weight) {
    final eligible =
        metrics
            .where(
              (m) =>
                  !m.measuredAt.isBefore(localDateOnly(draft.startDate)) &&
                  m.measuredAt.isBefore(localDayRange(day).end),
            )
            .toList()
          ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    if (eligible.isEmpty) {
      return const GoalProgress(
        value: null,
        fraction: null,
        label: 'Chưa có lần cân trong thời hạn',
      );
    }
    final current = eligible.first.weightKg;
    final baseline = draft.baselineWeightKg!;
    final distance = draft.targetValue - baseline;
    final fraction = distance == 0
        ? ((current - draft.targetValue).abs() < 0.1 ? 1.0 : 0.0)
        : ((current - baseline) / distance).clamp(0.0, 1.0);
    return GoalProgress(
      value: current,
      fraction: fraction,
      label: 'Theo lần cân gần nhất trong thời hạn',
    );
  }
  final key = localDateKey(day);
  final value = switch (draft.type) {
    GoalType.meals =>
      meals
          .where((m) => (m.dateKey ?? localDateKey(m.consumedAt)) == key)
          .length
          .toDouble(),
    GoalType.water => totalWaterMl(
      water.where((w) => w.dateKey == key),
    ).toDouble(),
    GoalType.activity => totalActivityMinutes(
      activities.where((a) => a.dateKey == key),
    ).toDouble(),
    GoalType.weight => throw StateError('Weight handled above'),
  };
  return GoalProgress(
    value: value,
    fraction: (value / draft.targetValue).clamp(0.0, 1.0),
    label: 'Chỉ tính nhật ký ngày đang xem',
  );
}
