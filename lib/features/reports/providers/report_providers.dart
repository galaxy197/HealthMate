import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/period_report.dart';
import '../data/day_review_repository.dart';

final dayReviewRepositoryProvider = Provider<DayReviewRepository>(
  (ref) => FirebaseDayReviewRepository(FirebaseFirestore.instance),
);
String _uid(Ref ref) {
  final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
  if (uid == null) throw StateError('Hãy đăng nhập để xem báo cáo.');
  return uid;
}

final periodMealsProvider = FutureProvider.autoDispose
    .family<List<MealLog>, ReportRange>(
      (ref, r) => ref
          .watch(nutritionRepositoryProvider)
          .loadRange(_uid(ref), r.start, r.end)
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
final periodWaterProvider = FutureProvider.autoDispose
    .family<List<WaterLog>, ReportRange>(
      (ref, r) => ref
          .watch(waterRepositoryProvider)
          .loadRange(_uid(ref), r.start, r.end)
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
final periodActivityProvider = FutureProvider.autoDispose
    .family<List<ActivityLog>, ReportRange>(
      (ref, r) => ref
          .watch(activityRepositoryProvider)
          .loadRange(_uid(ref), r.start, r.end)
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
final periodMetricsProvider = FutureProvider.autoDispose
    .family<List<BodyMetric>, ReportRange>(
      (ref, r) => ref
          .watch(healthProfileRepositoryProvider)
          .loadBodyMetricsRange(_uid(ref), r.start, r.end)
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
final periodTargetsProvider = FutureProvider.autoDispose
    .family<List<NutritionTarget>, ReportRange>(
      (ref, r) => ref
          .watch(nutritionTargetRepositoryProvider)
          .loadForRange(_uid(ref), localDateKey(r.start), localDateKey(r.end))
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
final dayReviewsProvider = FutureProvider.autoDispose
    .family<List<DayReview>, ReportRange>(
      (ref, r) => ref
          .watch(dayReviewRepositoryProvider)
          .load(_uid(ref), r)
          .timeout(const Duration(seconds: 20)),
      retry: (_, _) => null,
    );
