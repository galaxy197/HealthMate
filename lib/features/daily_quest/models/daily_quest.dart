enum QuestType { meal, water, activity, reflection }

enum QuestStatus {
  available('Có thể thực hiện'),
  completed('Đã hoàn thành'),
  skipped('Đã bỏ qua');

  const QuestStatus(this.label);
  final String label;
}

class DailyQuest {
  const DailyQuest({
    required this.dateKey,
    required this.type,
    required this.title,
    required this.description,
    required this.reason,
    required this.targetValue,
    required this.unit,
    this.status = QuestStatus.available,
    this.ruleVersion = 1,
  });

  final String dateKey;
  final QuestType type;
  final String title;
  final String description;
  final String reason;
  final double targetValue;
  final String unit;
  final QuestStatus status;
  final int ruleVersion;

  DailyQuest withStatus(QuestStatus status) => DailyQuest(
    dateKey: dateKey,
    type: type,
    title: title,
    description: description,
    reason: reason,
    targetValue: targetValue,
    unit: unit,
    status: status,
    ruleVersion: ruleVersion,
  );
}
