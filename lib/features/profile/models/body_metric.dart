class BodyMetricQueryRead {
  const BodyMetricQueryRead({
    required this.branch,
    required this.documentCount,
    required this.fromCache,
  });
  final String branch;
  final int documentCount;
  final bool fromCache;
}

/// Value cursor remains valid if its anchor document is deleted.
class BodyMetricCursor {
  const BodyMetricCursor({required this.measuredAt, required this.id});
  final DateTime measuredAt;
  final String id;
  @override
  bool operator ==(Object other) =>
      other is BodyMetricCursor &&
      other.id == id &&
      other.measuredAt == measuredAt;
  @override
  int get hashCode => Object.hash(measuredAt, id);
}

class BodyMetricPage {
  const BodyMetricPage({required this.metrics, required this.hasMore});
  final List<BodyMetric> metrics;
  final bool hasMore;
  BodyMetricCursor? get nextCursor => metrics.isEmpty
      ? null
      : BodyMetricCursor(
          measuredAt: metrics.last.measuredAt,
          id: metrics.last.id,
        );
}

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
