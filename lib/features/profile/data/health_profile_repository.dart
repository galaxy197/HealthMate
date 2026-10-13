import '../models/body_metric.dart';
import '../models/user_profile.dart';

abstract interface class HealthProfileRepository {
  Future<void> ensureProfile({required String uid, required String email});

  Stream<UserProfile?> watchProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required double? heightCm,
  });

  Stream<List<BodyMetric>> watchBodyMetrics(String uid);

  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  });

  Future<void> updateBodyMetric({
    required String uid,
    required String metricId,
    required BodyMetricDraft draft,
  });

  Future<void> deleteBodyMetric({
    required String uid,
    required String metricId,
  });
}
