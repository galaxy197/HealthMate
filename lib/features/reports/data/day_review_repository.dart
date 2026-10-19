import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/period_report.dart';

abstract interface class DayReviewRepository {
  Future<List<DayReview>> load(String uid, ReportRange range);
  Future<void> save(
    String uid,
    DateTime day,
    List<MealLog> meals, {
    required bool complete,
  });
}

class FirebaseDayReviewRepository implements DayReviewRepository {
  FirebaseDayReviewRepository(this.db);
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      db.collection('users').doc(uid).collection('day_reviews');
  @override
  Future<List<DayReview>> load(String uid, ReportRange range) async {
    calendarRangeDays(range.start, range.end);
    final data = await _collection(uid)
        .where('dateKey', isGreaterThanOrEqualTo: localDateKey(range.start))
        .where('dateKey', isLessThan: localDateKey(range.end))
        .orderBy('dateKey')
        .limit(91)
        .get(const GetOptions(source: Source.server));
    if (data.docs.length > 90) {
      throw const FormatException('Quá nhiều xác nhận ngày.');
    }
    return data.docs.map((doc) {
      final d = doc.data();
      if (d['dateKey'] != doc.id ||
          !isValidDateKey(doc.id) ||
          d['schemaVersion'] != 1 ||
          d['mealsComplete'] is! bool ||
          d['mealCount'] is! int ||
          d['mealCount'] < 0 ||
          d['mealCount'] > 2000 ||
          (d['latestMealUpdate'] != null &&
              d['latestMealUpdate'] is! Timestamp) ||
          d['createdAt'] is! Timestamp ||
          d['updatedAt'] is! Timestamp) {
        throw const FormatException('Dữ liệu xác nhận không hợp lệ.');
      }
      return DayReview(
        dateKey: doc.id,
        complete: d['mealsComplete'],
        mealCount: d['mealCount'],
        latestMealUpdate: (d['latestMealUpdate'] as Timestamp?)
            ?.toDate()
            .toUtc(),
      );
    }).toList();
  }

  @override
  Future<void> save(
    String uid,
    DateTime day,
    List<MealLog> meals, {
    required bool complete,
  }) async {
    final key = localDateKey(day);
    if (day.isAfter(localDateOnly(DateTime.now())) ||
        meals.length > 2000 ||
        meals.any(
          (m) => (m.dateKey ?? localDateKey(m.consumedAt.toLocal())) != key,
        )) {
      throw const FormatException('Ngày hoặc nhật ký không hợp lệ.');
    }
    final ref = _collection(uid).doc(key);
    final revision = latestMealRevision(meals);
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final data = <String, Object?>{
        'dateKey': key,
        'mealsComplete': complete,
        'mealCount': meals.length,
        'latestMealUpdate': revision == null
            ? null
            : Timestamp.fromDate(revision),
        'timezoneOffsetMinutes': day.timeZoneOffset.inMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      };
      if (existing.exists) {
        tx.update(ref, data);
      } else {
        tx.set(ref, {...data, 'createdAt': FieldValue.serverTimestamp()});
      }
    });
    final confirmed = (await ref.get(
      const GetOptions(source: Source.server),
    )).data();
    if (confirmed == null ||
        confirmed['mealsComplete'] != complete ||
        confirmed['mealCount'] != meals.length ||
        (confirmed['latestMealUpdate'] as Timestamp?)?.toDate().toUtc() !=
            revision) {
      throw StateError('Chưa xác nhận được trạng thái trên máy chủ.');
    }
  }
}
