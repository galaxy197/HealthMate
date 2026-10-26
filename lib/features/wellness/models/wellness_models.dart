import '../../nutrition/models/nutrition_models.dart';

class MealReminder {
  const MealReminder(this.meal, this.minute, {this.enabled = false});
  final MealType meal;
  final int minute;
  final bool enabled;
  Map<String, Object> toData() => {
    'meal': meal.name,
    'minute': minute,
    'enabled': enabled,
  };
  factory MealReminder.fromData(Map data) {
    final meal = MealType.values.byName(data['meal'] as String);
    final minute = data['minute'] as int;
    if (minute < 0 || minute >= 1440 || data['enabled'] is! bool) {
      throw const FormatException('Giờ nhắc chưa hợp lệ.');
    }
    return MealReminder(meal, minute, enabled: data['enabled'] as bool);
  }
}

const defaultMealReminders = [
  MealReminder(MealType.breakfast, 7 * 60),
  MealReminder(MealType.lunch, 12 * 60),
  MealReminder(MealType.dinner, 19 * 60),
  MealReminder(MealType.snack, 15 * 60),
];

class SleepReminder {
  const SleepReminder({this.enabled = false, this.minute = 22 * 60});
  final bool enabled;
  final int minute;
  Map<String, Object> toData() => {'enabled': enabled, 'minute': minute};
  factory SleepReminder.fromData(Map data) {
    if (data.isEmpty) return const SleepReminder();
    if (data['enabled'] is! bool ||
        data['minute'] is! int ||
        (data['minute'] as int) < 0 ||
        (data['minute'] as int) >= 1440) {
      throw const FormatException('Lịch nhắc ngủ chưa hợp lệ.');
    }
    return SleepReminder(
      enabled: data['enabled'] as bool,
      minute: data['minute'] as int,
    );
  }
}

class SleepLog {
  const SleepLog({
    required this.id,
    required this.start,
    required this.end,
    required this.source,
  });
  final String id, source;
  final DateTime start, end;
  Duration get duration => end.difference(start);
  static String? validate(DateTime start, DateTime end, DateTime now) {
    if (!end.isAfter(start) ||
        end.difference(start) > const Duration(hours: 24)) {
      return 'Giờ thức phải sau giờ ngủ, tối đa 24 giờ mỗi lần.';
    }
    if (end.isAfter(now.add(const Duration(minutes: 5)))) {
      return 'Không ghi thời gian ngủ trong tương lai.';
    }
    return null;
  }
}

class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    this.loggedMealId,
  });
  final String id;
  final DateTime date;
  final MealType type;
  final List<MealItemSnapshot> items;
  final String? loggedMealId;
  NutritionTotals get totals =>
      sumNutritionTotals(items.map((i) => i.nutrition));
}

class StepDay {
  const StepDay(this.day, this.steps, this.startedAt, this.updatedAt);
  final String day;
  final int steps;
  final DateTime startedAt, updatedAt;
}
