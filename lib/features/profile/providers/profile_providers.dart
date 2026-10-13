import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_health_profile_repository.dart';
import '../data/health_profile_repository.dart';
import '../models/body_metric.dart';
import '../models/onboarding_draft.dart';
import '../models/profile_failure.dart';
import '../models/user_profile.dart';

const profileBootstrapTimeout = Duration(seconds: 12);

final healthProfileRepositoryProvider = Provider<HealthProfileRepository>(
  (ref) => FirebaseHealthProfileRepository(FirebaseFirestore.instance),
);

final profileBootstrapProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) return;
  await ref
      .watch(healthProfileRepositoryProvider)
      .ensureProfile(uid: user.uid, email: user.email ?? '')
      .timeout(
        profileBootstrapTimeout,
        onTimeout: () => throw const ProfileFailure(
          'Không thể tải hồ sơ trong thời gian chờ. Hãy kiểm tra kết nối rồi thử lại.',
        ),
      );
}, retry: (retryCount, error) => null);

final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) {
    yield null;
    return;
  }
  await ref.watch(profileBootstrapProvider.future);
  yield* ref.watch(healthProfileRepositoryProvider).watchProfile(user.uid);
}, retry: (retryCount, error) => null);

final bodyMetricsProvider = StreamProvider<List<BodyMetric>>((ref) async* {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) {
    yield const [];
    return;
  }
  await ref.watch(profileBootstrapProvider.future);
  yield* ref.watch(healthProfileRepositoryProvider).watchBodyMetrics(user.uid);
}, retry: (retryCount, error) => null);

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<void>>(
      ProfileController.new,
    );

class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> updateProfile(UserProfileDraft draft) => _perform((user) {
    return ref
        .read(healthProfileRepositoryProvider)
        .updateProfile(
          uid: user.uid,
          displayName: draft.displayName,
          heightCm: draft.heightCm,
          birthDate: draft.birthDate,
          healthGoal: draft.healthGoal.value,
          targetWeightKg: draft.healthGoal.needsTargetWeight
              ? draft.targetWeightKg
              : null,
        );
  });

  Future<bool> completeOnboarding(OnboardingDraft draft) => _perform((user) {
    return ref
        .read(healthProfileRepositoryProvider)
        .completeOnboarding(uid: user.uid, draft: draft);
  });

  Future<bool> addBodyMetric(BodyMetricDraft draft) => _perform((user) async {
    await ref
        .read(healthProfileRepositoryProvider)
        .addBodyMetric(uid: user.uid, draft: draft);
  });

  Future<bool> updateBodyMetric({
    required String metricId,
    required BodyMetricDraft draft,
  }) => _perform((user) {
    return ref
        .read(healthProfileRepositoryProvider)
        .updateBodyMetric(uid: user.uid, metricId: metricId, draft: draft);
  });

  Future<bool> deleteBodyMetric(String metricId) => _perform((user) {
    return ref
        .read(healthProfileRepositoryProvider)
        .deleteBodyMetric(uid: user.uid, metricId: metricId);
  });

  Future<bool> _perform(Future<void> Function(AuthUser user) operation) async {
    if (state.isLoading) return false;
    final user = ref.read(authSessionProvider).value;
    if (user == null) {
      state = AsyncError(
        const ProfileFailure('Phiên đăng nhập đã hết hạn.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await operation(user);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(
          error is ProfileFailure ? error : ProfileFailure.fromCode('unknown'),
          stack,
        );
      }
      return false;
    }
  }
}
