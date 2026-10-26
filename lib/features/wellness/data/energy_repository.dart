import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/utils/subscription_stream.dart';
import '../models/energy_budget.dart';

abstract interface class EnergyRepository {
  Stream<WellnessPreferences> watchPreferences(String uid);
  Future<void> savePreferences(String uid, WellnessPreferences preferences);
  Stream<EnergyAdjustment?> watchAdjustment(String uid, String day);
  Future<List<EnergyAdjustment>> loadAdjustments(
    String uid,
    DateTime start,
    DateTime end,
  );
  Future<void> saveAdjustment(String uid, EnergyAdjustment adjustment);
  Future<void> clearAdjustment(String uid, String day);
}

class FirebaseEnergyRepository implements EnergyRepository {
  FirebaseEnergyRepository(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FirebaseFirestore db;
  final DateTime Function() now;
  void owner(String uid) {
    final user = FirebaseAuth.instanceFor(app: db.app).currentUser;
    if (user?.uid != uid || user?.emailVerified != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> collection(
    String uid,
    String name,
  ) {
    owner(uid);
    return db.collection('users').doc(uid).collection(name);
  }

  Stream<T> owned<T>(String uid, Stream<T> Function() create) async* {
    owner(uid);
    yield* subscriptionStream(
      create().map((v) {
        owner(uid);
        return v;
      }),
    );
  }

  @override
  Stream<WellnessPreferences> watchPreferences(String uid) => owned(
    uid,
    () => collection(uid, 'wellness_preferences')
        .doc('main')
        .snapshots()
        .map(
          (d) => d.exists
              ? WellnessPreferences.fromData(d.data()!)
              : const WellnessPreferences(),
        ),
  );
  @override
  Future<void> savePreferences(String uid, WellnessPreferences p) async {
    final error = p.validate();
    if (error != null) throw FormatException(error);
    await collection(uid, 'wellness_preferences').doc('main').set({
      ...p.toData(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  EnergyAdjustment parse(Map<String, dynamic> d) {
    if (d['schemaVersion'] != 1 ||
        d['source'] != 'walking_net_v1' ||
        d['confirmedAt'] is! Timestamp) {
      throw const FormatException('Phiên bản điều chỉnh chưa hỗ trợ.');
    }
    final a = EnergyAdjustment(
      dateKey: d['dateKey'] as String,
      timezoneOffsetMinutes: d['timezoneOffsetMinutes'] as int,
      steps: d['steps'] as int,
      baselineSteps: d['baselineSteps'] as int,
      stepLengthCm: (d['stepLengthCm'] as num).toDouble(),
      weightKg: (d['weightKg'] as num).toDouble(),
      weightMeasuredAt: (d['weightMeasuredAt'] as Timestamp).toDate(),
      targetFromDateKey: d['targetFromDateKey'] as String,
      baseKcalTarget: (d['baseKcalTarget'] as num).toDouble(),
      kcal: (d['kcal'] as num).toDouble(),
    );
    if (a.validate() != null) {
      throw const FormatException('Điều chỉnh không hợp lệ.');
    }
    return a;
  }

  @override
  Stream<EnergyAdjustment?> watchAdjustment(String uid, String day) {
    if (!isValidDateKey(day)) throw const FormatException('Ngày chưa hợp lệ.');
    return owned(
      uid,
      () => collection(
        uid,
        'energy_adjustments',
      ).doc(day).snapshots().map((d) => d.exists ? parse(d.data()!) : null),
    );
  }

  @override
  Future<List<EnergyAdjustment>> loadAdjustments(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    if (!end.isAfter(start) || end.difference(start).inDays > 90) {
      throw const FormatException('Chỉ tải tối đa 90 ngày.');
    }
    final s = await collection(uid, 'energy_adjustments')
        .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
        .where('dateKey', isLessThan: localDateKey(end))
        .orderBy('dateKey')
        .limit(90)
        .get(const GetOptions(source: Source.server));
    owner(uid);
    return s.docs.map((d) => parse(d.data())).toList();
  }

  @override
  Future<void> saveAdjustment(String uid, EnergyAdjustment a) async {
    final error = a.validate();
    if (error != null) throw FormatException(error);
    if (a.dateKey != localDateKey(now()) ||
        a.weightMeasuredAt.isAfter(now()) ||
        now().difference(a.weightMeasuredAt) > const Duration(days: 90)) {
      throw const FormatException(
        'Chỉ xác nhận hôm nay với cân nặng trong 90 ngày gần nhất.',
      );
    }
    await collection(uid, 'energy_adjustments').doc(a.dateKey).set({
      'dateKey': a.dateKey,
      'timezoneOffsetMinutes': a.timezoneOffsetMinutes,
      'steps': a.steps,
      'baselineSteps': a.baselineSteps,
      'stepLengthCm': a.stepLengthCm,
      'weightKg': a.weightKg,
      'weightMeasuredAt': Timestamp.fromDate(a.weightMeasuredAt),
      'targetFromDateKey': a.targetFromDateKey,
      'baseKcalTarget': a.baseKcalTarget,
      'kcal': a.kcal,
      'source': 'walking_net_v1',
      'schemaVersion': 1,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> clearAdjustment(String uid, String day) =>
      collection(uid, 'energy_adjustments').doc(day).delete();
}
