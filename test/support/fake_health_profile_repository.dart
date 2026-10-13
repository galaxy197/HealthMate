import 'dart:async';

import 'package:healthmate/features/profile/data/health_profile_repository.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
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
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    schemaVersion: 1,
  );

  UserProfile? _profile;
  final List<BodyMetric> _metrics;
  final _profileChanges = StreamController<UserProfile?>.broadcast();
  final _metricChanges = StreamController<List<BodyMetric>>.broadcast();
  ProfileFailure? failure;
  Completer<void>? pending;
  int ensureCalls = 0;
  int updateProfileCalls = 0;
  int addMetricCalls = 0;
  int updateMetricCalls = 0;
  int deleteMetricCalls = 0;

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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      schemaVersion: 1,
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
    required double? heightCm,
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
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      schemaVersion: 1,
    );
    _profileChanges.add(_profile);
  }

  @override
  Stream<List<BodyMetric>> watchBodyMetrics(String uid) =>
      Stream.multi((controller) {
        controller.add(List.unmodifiable(_metrics));
        final subscription = _metricChanges.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

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
