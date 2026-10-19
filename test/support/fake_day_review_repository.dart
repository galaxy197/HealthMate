import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/core/utils/local_date_key.dart';

class FakeDayReviewRepository implements DayReviewRepository {
  final byUid = <String, Map<String, DayReview>>{};
  int loadCalls = 0, saveCalls = 0;
  bool failRead = false, failSave = false;
  @override
  Future<List<DayReview>> load(String uid, ReportRange range) async {
    loadCalls++;
    if (failRead) throw StateError('QA review read failure');
    return (byUid[uid]?.values ?? <DayReview>[])
        .where(
          (r) =>
              r.dateKey.compareTo(localDateKey(range.start)) >= 0 &&
              r.dateKey.compareTo(localDateKey(range.end)) < 0,
        )
        .toList();
  }

  @override
  Future<void> save(
    String uid,
    DateTime day,
    List<MealLog> meals, {
    required bool complete,
  }) async {
    saveCalls++;
    if (failSave) throw StateError('QA review save failure');
    final key = localDateKey(day);
    byUid.putIfAbsent(uid, () => {})[key] = DayReview(
      dateKey: key,
      complete: complete,
      mealCount: meals.length,
      latestMealUpdate: latestMealRevision(meals),
    );
  }
}
