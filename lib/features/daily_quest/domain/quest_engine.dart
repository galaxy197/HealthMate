import '../../../core/utils/local_date_key.dart';
import '../../goals/models/tracking_goal.dart';
import '../models/daily_quest.dart';

// One stable daily suggestion, ordered by type then ID, not by query order.
// Missing logs mean missing records only; no medical judgment is inferred.
DailyQuest suggestQuest({
  required DateTime day,
  required List<TrackingGoal> goals,
  required int mealCount,
  required int waterMl,
  required int activityMinutes,
}) {
  final active = goals.where((g) => g.appliesOn(day)).toList()
    ..sort((a, b) {
      final byType = a.draft.type.index.compareTo(b.draft.type.index);
      return byType == 0 ? a.id.compareTo(b.id) : byType;
    });
  final key = localDateKey(day);
  for (final goal in active) {
    final remaining =
        goal.draft.targetValue -
        switch (goal.draft.type) {
          GoalType.meals => mealCount,
          GoalType.water => waterMl,
          GoalType.activity => activityMinutes,
          GoalType.weight => goal.draft.targetValue,
        };
    if (remaining <= 0) continue;
    switch (goal.draft.type) {
      case GoalType.meals:
        return DailyQuest(
          dateKey: key,
          type: QuestType.meal,
          title: 'Ghi nhận một bữa ăn',
          targetValue: 1,
          unit: 'bữa',
          description:
              'Ghi lại một bữa đã ăn và kiểm tra khẩu phần trước khi lưu.',
          reason:
              'Bạn chọn mục tiêu ghi bữa ăn; hôm nay chưa đủ số bữa bạn đặt.',
        );
      case GoalType.water:
        return DailyQuest(
          dateKey: key,
          type: QuestType.water,
          title: 'Ghi lại nước bạn đã uống',
          targetValue: remaining.clamp(1, 250).toDouble(),
          unit: 'ml',
          description:
              'Ghi lượng nước thực tế đã uống. Đây không phải khuyến nghị nhu cầu nước cá nhân.',
          reason:
              'Bạn chủ động chọn theo dõi nước; tổng đã ghi còn dưới mức bạn đặt.',
        );
      case GoalType.activity:
        return DailyQuest(
          dateKey: key,
          type: QuestType.activity,
          title: 'Dành thời gian cho vận động phù hợp',
          targetValue: remaining.clamp(1, 10).toDouble(),
          unit: 'phút',
          description:
              'Chọn hoạt động bạn thấy phù hợp và chỉ ghi thời lượng đã thực hiện. Có thể bỏ qua khi không tiện.',
          reason:
              'Bạn đã chọn mục tiêu phút vận động; thời lượng gợi ý không vượt phần còn lại.',
        );
      case GoalType.weight:
        break;
    }
  }
  if (mealCount == 0) {
    return DailyQuest(
      dateKey: key,
      type: QuestType.meal,
      title: 'Bắt đầu với một bữa ăn',
      targetValue: 1,
      unit: 'bữa',
      description: 'Nếu bạn muốn theo dõi hôm nay, hãy ghi lại một bữa đã ăn.',
      reason:
          'Hôm nay chưa có bữa được ghi. Điều này không có nghĩa bạn chưa ăn hay không khỏe.',
    );
  }
  return DailyQuest(
    dateKey: key,
    type: QuestType.reflection,
    title: 'Xem lại nhật ký hôm nay',
    targetValue: 1,
    unit: 'lần',
    description:
        'Kiểm tra những ghi nhận đã lưu và điều chỉnh nếu cần. Không có điểm số hay hình phạt.',
    reason:
        'Bạn đã có nhật ký; không còn mục tiêu thói quen đang thiếu để gợi ý.',
  );
}
