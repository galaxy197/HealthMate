import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/body_metric.dart';
import '../models/profile_failure.dart';
import '../models/user_profile.dart';
import 'health_profile_repository.dart';

class FirebaseHealthProfileRepository implements HealthProfileRepository {
  FirebaseHealthProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _metrics(String uid) =>
      _profile(uid).collection('body_metrics');

  @override
  Future<void> ensureProfile({required String uid, required String email}) =>
      _guard(() async {
        final reference = _profile(uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(reference);
          if (!snapshot.exists) {
            transaction.set(reference, {
              'displayName': '',
              'email': email,
              'heightCm': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 1,
            });
            return;
          }
          final data = snapshot.data();
          if (data?['email'] != email || data?['schemaVersion'] != 1) {
            transaction.update(reference, {
              'email': email,
              'updatedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 1,
            });
          }
        });
      });

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _profile(uid).snapshots()) {
        final data = snapshot.data();
        yield data == null ? null : _profileFromData(uid, data);
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required double? heightCm,
  }) => _guard(
    () => _profile(uid).update({
      'displayName': displayName.trim(),
      'heightCm': heightCm,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    }),
  );

  @override
  Stream<List<BodyMetric>> watchBodyMetrics(String uid) async* {
    try {
      await for (final snapshot in _metrics(
        uid,
      ).orderBy('measuredAt', descending: true).snapshots()) {
        yield [
          for (final document in snapshot.docs)
            _metricFromData(document.id, document.data()),
        ];
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }

  @override
  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  }) => _guard(() async {
    final reference = _metrics(uid).doc();
    await reference.set({
      'weightKg': draft.weightKg,
      'measuredAt': Timestamp.fromDate(draft.measuredAt),
      'note': draft.note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  });

  @override
  Future<void> updateBodyMetric({
    required String uid,
    required String metricId,
    required BodyMetricDraft draft,
  }) => _guard(
    () => _metrics(uid).doc(metricId).update({
      'weightKg': draft.weightKg,
      'measuredAt': Timestamp.fromDate(draft.measuredAt),
      'note': draft.note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteBodyMetric({
    required String uid,
    required String metricId,
  }) => _guard(() => _metrics(uid).doc(metricId).delete());

  UserProfile _profileFromData(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      heightCm: _double(data['heightCm']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      schemaVersion: data['schemaVersion'] as int? ?? 1,
    );
  }

  BodyMetric _metricFromData(String id, Map<String, dynamic> data) {
    final measuredAt = _date(data['measuredAt']);
    final weight = _double(data['weightKg']);
    if (measuredAt == null || weight == null) {
      throw StateError('Invalid body metric schema.');
    }
    return BodyMetric(
      id: id,
      weightKg: weight,
      measuredAt: measuredAt,
      note: data['note'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  double? _double(Object? value) => value is num ? value.toDouble() : null;

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }
}
