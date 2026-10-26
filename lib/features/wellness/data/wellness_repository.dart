import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/subscription_stream.dart';
import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/wellness_models.dart';

class WellnessRepository {
  WellnessRepository(this.db);
  final FirebaseFirestore db;
  void _requireOwner(String uid) {
    final user = FirebaseAuth.instanceFor(app: db.app).currentUser;
    if (user?.uid != uid || user?.emailVerified != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message:
            'Không thể truy cập dữ liệu của tài khoản khác hoặc chưa xác minh.',
      );
    }
  }

  Stream<T> _owned<T>(String uid, Stream<T> Function() create) async* {
    _requireOwner(uid);
    yield* subscriptionStream(
      create().map((value) {
        _requireOwner(uid);
        return value;
      }),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String name,
  ) {
    _requireOwner(uid);
    return db.collection('users').doc(uid).collection(name);
  }

  Stream<DateTime?> watchSleepStart(String uid) => _owned(
    uid,
    () => _collection(uid, 'wellness_state')
        .doc('sleep')
        .snapshots()
        .map((d) => (d.data()?['startedAt'] as Timestamp?)?.toDate()),
  );

  Stream<List<SleepLog>> watchSleepLogs(String uid) => _owned(
    uid,
    () => _collection(uid, 'sleep_logs')
        .orderBy('startedAt', descending: true)
        .limit(60)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              SleepLog(
                id: d.id,
                start: (d['startedAt'] as Timestamp).toDate(),
                end: (d['endedAt'] as Timestamp).toDate(),
                source: d['source'] as String,
              ),
          ],
        ),
  );

  Future<void> startSleep(String uid) async {
    final target = _collection(uid, 'wellness_state').doc('sleep');
    final started = await db.runTransaction<bool>((t) async {
      if ((await t.get(target)).exists) {
        return false;
      }
      t.set(target, {
        'startedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      return true;
    });
    if (!started) {
      throw const FormatException(
        'Đã có lần ngủ đang chạy. Hãy kết thúc trước.',
      );
    }
  }

  Future<void> cancelSleep(String uid) =>
      _collection(uid, 'wellness_state').doc('sleep').delete();

  Future<void> saveSleep(
    String uid,
    DateTime start,
    DateTime end, {
    String? id,
    bool finishTimer = false,
    DateTime? expectedTimerStart,
  }) async {
    final error = SleepLog.validate(start, end, DateTime.now());
    if (error != null) throw FormatException(error);
    final active = _collection(uid, 'wellness_state').doc('sleep');
    // The active timestamp makes finishing the same timer idempotent.
    final target = _collection(uid, 'sleep_logs').doc(
      id ??
          (finishTimer
              ? 'timer-${(expectedTimerStart ?? start).millisecondsSinceEpoch}'
              : 'manual-${start.millisecondsSinceEpoch}-${end.millisecondsSinceEpoch}'),
    );
    final saved = await db.runTransaction<bool>((t) async {
      final previous = await t.get(target);
      final state = finishTimer ? await t.get(active) : null;
      if (finishTimer && !state!.exists) {
        return previous.exists;
      }
      if (finishTimer &&
          (state!.data()?['startedAt'] as Timestamp?)?.toDate() !=
              (expectedTimerStart ?? start)) {
        return false;
      }
      t.set(target, {
        'startedAt': Timestamp.fromDate(start),
        'endedAt': Timestamp.fromDate(end),
        'source': finishTimer ? 'manual_timer' : 'manual_entry',
        'createdAt': previous.exists
            ? previous['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      if (finishTimer) t.delete(active);
      return true;
    });
    if (!saved) {
      throw const FormatException('Lần ngủ đã đổi hoặc đã hủy. Hãy tải lại.');
    }
  }

  Future<void> deleteSleep(String uid, String id) =>
      _collection(uid, 'sleep_logs').doc(id).delete();

  Future<List<SleepLog>> loadSleepRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    if (!end.isAfter(start) || end.difference(start).inDays > 31) {
      throw const FormatException('Chỉ tải tối đa 31 ngày giờ ngủ.');
    }
    final result = await _collection(uid, 'sleep_logs')
        .where('endedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('endedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('endedAt')
        .limit(2001)
        .get(const GetOptions(source: Source.server));
    _requireOwner(uid);
    if (result.docs.length > 2000) {
      throw const FormatException(
        'Quá nhiều lần ghi; hãy chọn khoảng ngắn hơn.',
      );
    }
    return result.docs
        .map(
          (d) => SleepLog(
            id: d.id,
            start: (d['startedAt'] as Timestamp).toDate(),
            end: (d['endedAt'] as Timestamp).toDate(),
            source: d['source'] as String,
          ),
        )
        .toList();
  }

  Stream<List<PlannedMeal>> watchPlans(String uid, DateTime start) {
    final end = DateTime(start.year, start.month, start.day + 7);
    return _owned(
      uid,
      () => _collection(uid, 'meal_plans')
          .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
          .where('dateKey', isLessThan: localDateKey(end))
          .orderBy('dateKey')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                PlannedMeal(
                  id: d.id,
                  date: DateTime.parse(d['dateKey'] as String),
                  type: MealType.values.byName(d['mealType'] as String),
                  items: (d['items'] as List)
                      .map(
                        (v) => MealItemSnapshot.fromCompactData(
                          Map<String, dynamic>.from(v as Map),
                        ),
                      )
                      .toList(),
                  loggedMealId: d.data()['loggedMealId'] as String?,
                ),
            ],
          ),
    );
  }

  Future<void> savePlan(String uid, MealDraft draft) async {
    if (draft.items.isEmpty || draft.items.length > 5) {
      throw const FormatException('Chọn từ 1 đến 5 món cho một bữa dự kiến.');
    }
    final id = '${draft.dateKey}-${draft.type.name}';
    final target = _collection(uid, 'meal_plans').doc(id);
    final saved = await db.runTransaction<bool>((t) async {
      final previous = await t.get(target);
      if (previous.data()?['loggedMealId'] != null) {
        return false;
      }
      t.set(target, {
        'dateKey': draft.dateKey,
        'mealType': draft.type.name,
        'items': draft.items.map((i) => i.toCompactData()).toList(),
        'createdAt': previous.exists
            ? previous['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      });
      return true;
    });
    if (!saved) {
      throw const FormatException(
        'Bữa này đã ghi nhật ký; hãy sửa tại Nhật ký.',
      );
    }
  }

  Future<void> deletePlan(String uid, String id) =>
      _collection(uid, 'meal_plans').doc(id).delete();

  Future<bool> existingPlanMeal(String uid, String id) async =>
      (await _collection(
        uid,
        'meal_logs',
      ).doc('plan-$id').get(const GetOptions(source: Source.server))).exists;

  Future<void> markPlanLogged(String uid, String id) =>
      _collection(uid, 'meal_plans').doc(id).update({
        'loggedMealId': 'plan-$id',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<StepDay>> watchStepDays(String uid) => _owned(
    uid,
    () => _collection(uid, 'step_logs')
        .orderBy('dateKey', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              StepDay(
                d['dateKey'] as String,
                d['steps'] as int,
                (d['trackingStartedAt'] as Timestamp).toDate(),
                (d['measuredAt'] as Timestamp).toDate(),
              ),
          ],
        ),
  );

  Future<void> syncSteps(String uid, Map<String, dynamic> data) async {
    final day = data['day'] as String;
    final steps = data['steps'] as int;
    if (!isValidDateKey(day) || steps < 0 || steps > 150000) {
      throw const FormatException('Dữ liệu bước chân chưa hợp lệ.');
    }
    final start = DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);
    final measured = DateTime.fromMillisecondsSinceEpoch(
      data['measuredAt'] as int,
    );
    final target = _collection(uid, 'step_logs').doc(day);
    await db.runTransaction((transaction) async {
      final previous = await transaction.get(target);
      // Keep the highest device recording for the day; never add overlapping
      // phone measurements or let a stale/offline snapshot reduce the history.
      if (previous.exists && (previous['steps'] as int) >= steps) return;
      transaction.set(target, {
        'dateKey': day,
        'steps': steps,
        'timezoneOffsetMinutes': data['timezoneOffsetMinutes'],
        'trackingStartedAt': Timestamp.fromDate(start),
        'measuredAt': Timestamp.fromDate(measured),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'device_step_counter',
        'schemaVersion': 1,
      });
    });
  }
}
