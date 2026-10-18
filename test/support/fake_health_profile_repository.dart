import 'dart:async';
import 'package:healthmate/core/utils/local_date_key.dart';

import 'package:healthmate/features/profile/data/health_profile_repository.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';

class FakeHealthProfileRepository implements HealthProfileRepository {
  factory FakeHealthProfileRepository({
    UserProfile? profile,
    List<BodyMetric>? metrics,
  }) => FakeHealthProfileRepository._(profile, [...?metrics]);

  FakeHealthProfileRepository._(this._profile, this._metrics);

  static final testProfile = UserProfile(
    uid: 'test-uid',
    displayName: 'HealthMate Tester',
    email: 'member@example.com',
    heightCm: 170,
    birthDate: DateTime(2000, 1, 15),
    healthGoal: HealthGoal.maintainWeight,
    targetWeightKg: null,
    onboardingCompletedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    schemaVersion: 2,
  );

  static final incompleteProfile = UserProfile(
    uid: 'test-uid',
    displayName: '',
    email: 'member@example.com',
    heightCm: null,
    birthDate: null,
    healthGoal: null,
    targetWeightKg: null,
    onboardingCompletedAt: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    schemaVersion: 2,
  );

  UserProfile? _profile;
  final List<BodyMetric> _metrics;
  final _profileChanges = StreamController<UserProfile?>.broadcast();
  final _metricChanges = StreamController<List<BodyMetric>>.broadcast();
  ProfileFailure? failure;
  Completer<void>? pending;
  int ensureCalls = 0;
  int updateProfileCalls = 0;
  int completeOnboardingCalls = 0;
  int addMetricCalls = 0;
  int updateMetricCalls = 0;
  int deleteMetricCalls = 0;
  int metricRangeCalls = 0;
  int latestMetricListeners = 0;
  int fullMetricWatchCalls = 0;
  OnboardingDraft? lastOnboardingDraft;

  UserProfile? get currentProfile => _profile;
  void emitProfile(UserProfile? profile) {
    _profile = profile;
    _profileChanges.add(profile);
  }

  List<BodyMetric> get metrics => List.unmodifiable(_metrics);

  @override
  Future<void> ensureProfile({
    required String uid,
    required String email,
  }) async {
    ensureCalls++;
    await _operation();
    _profile ??= UserProfile(
      uid: uid,
      displayName: '',
      email: email,
      heightCm: null,
      birthDate: null,
      healthGoal: null,
      targetWeightKg: null,
      onboardingCompletedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      schemaVersion: 2,
    );
    _profileChanges.add(_profile);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) => Stream.multi((controller) {
    controller.add(_profile);
    final subscription = _profileChanges.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required double heightCm,
    required DateTime birthDate,
    required String healthGoal,
    required double? targetWeightKg,
  }) async {
    updateProfileCalls++;
    await _operation();
    final current = _profile;
    if (current == null) throw const ProfileFailure('Missing profile');
    _profile = UserProfile(
      uid: uid,
      displayName: displayName,
      email: current.email,
      heightCm: heightCm,
      birthDate: birthDate,
      healthGoal: HealthGoal.fromValue(healthGoal),
      targetWeightKg: targetWeightKg,
      onboardingCompletedAt: current.onboardingCompletedAt,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      schemaVersion: 2,
    );
    _profileChanges.add(_profile);
  }

  @override
  Future<void> completeOnboarding({
    required String uid,
    required OnboardingDraft draft,
  }) async {
    completeOnboardingCalls++;
    lastOnboardingDraft = draft;
    await _operation();
    final current = _profile;
    if (current == null) throw const ProfileFailure('Missing profile');
    final now = DateTime.now();
    _profile = UserProfile(
      uid: uid,
      displayName: draft.displayName.trim(),
      email: current.email,
      heightCm: draft.heightCm,
      birthDate: draft.birthDate,
      healthGoal: draft.healthGoal,
      targetWeightKg: draft.healthGoal.needsTargetWeight
          ? draft.targetWeightKg
          : null,
      onboardingCompletedAt: current.onboardingCompletedAt ?? now,
      createdAt: current.createdAt,
      updatedAt: now,
      schemaVersion: 2,
    );
    final metricIndex = _metrics.indexWhere(
      (metric) => metric.id == 'onboarding-current',
    );
    final metric = BodyMetric(
      id: 'onboarding-current',
      weightKg: draft.currentWeightKg,
      measuredAt: now,
      note: 'Cân nặng khi hoàn tất thiết lập ban đầu',
      createdAt: metricIndex < 0 ? now : _metrics[metricIndex].createdAt,
      updatedAt: now,
    );
    if (metricIndex < 0) {
      _metrics.add(metric);
    } else {
      _metrics[metricIndex] = metric;
    }
    _profileChanges.add(_profile);
    _sortAndEmit();
  }

  @override
  Stream<List<BodyMetric>> watchBodyMetrics(String uid) =>
      Stream.multi((controller) {
        fullMetricWatchCalls++;
        controller.add(List.unmodifiable(_metrics));
        final subscription = _metricChanges.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Stream<List<BodyMetric>> watchLatestBodyMetric(String uid, DateTime day) =>
      Stream.multi((c) {
        latestMetricListeners++;
        void emit() {
          final list =
              _metrics
                  .where((m) => m.measuredAt.isBefore(localDayRange(day).end))
                  .toList()
                ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          c.add(list.take(1).toList());
        }

        emit();
        final sub = _metricChanges.stream.listen(
          (_) => emit(),
          onError: c.addError,
        );
        c.onCancel = () async {
          latestMetricListeners--;
          await sub.cancel();
        };
      });

  @override
  Future<List<BodyMetric>> loadBodyMetricsRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    metricRangeCalls++;
    await _operation();
    return _metrics
        .where(
          (m) => !m.measuredAt.isBefore(start) && m.measuredAt.isBefore(end),
        )
        .toList();
  }

  @override
  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  }) async {
    addMetricCalls++;
    await _operation();
    final id = 'metric-$addMetricCalls';
    _metrics.add(
      BodyMetric(
        id: id,
        weightKg: draft.weightKg,
        measuredAt: draft.measuredAt,
        note: draft.note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    _sortAndEmit();
    return id;
  }

  @override
  Future<void> updateBodyMetric({
    required String uid,
    required String metricId,
    required BodyMetricDraft draft,
  }) async {
    updateMetricCalls++;
    await _operation();
    final index = _metrics.indexWhere((metric) => metric.id == metricId);
    if (index < 0) throw const ProfileFailure('Missing metric');
    final current = _metrics[index];
    _metrics[index] = BodyMetric(
      id: metricId,
      weightKg: draft.weightKg,
      measuredAt: draft.measuredAt,
      note: draft.note,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _sortAndEmit();
  }

  @override
  Future<void> deleteBodyMetric({
    required String uid,
    required String metricId,
  }) async {
    deleteMetricCalls++;
    await _operation();
    _metrics.removeWhere((metric) => metric.id == metricId);
    _sortAndEmit();
  }

  Future<void> _operation() async {
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  void _sortAndEmit() {
    _metrics.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    _metricChanges.add(List.unmodifiable(_metrics));
  }

  Future<void> dispose() async {
    await _profileChanges.close();
    await _metricChanges.close();
  }
}
