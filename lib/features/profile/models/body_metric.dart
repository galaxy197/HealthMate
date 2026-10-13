class BodyMetric {
  const BodyMetric({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final double weightKg;
  final DateTime measuredAt;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class BodyMetricDraft {
  const BodyMetricDraft({
    required this.weightKg,
    required this.measuredAt,
    required this.note,
  });

  final double weightKg;
  final DateTime measuredAt;
  final String note;
}
