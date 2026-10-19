import '../models/nutrition_target.dart';

abstract interface class NutritionTargetRepository {
  Future<NutritionTarget?> loadForDay(String uid, String dateKey);

  /// Base version at [startKey] and changes before [endKey], at most 90 days.
  Future<List<NutritionTarget>> loadForRange(
    String uid,
    String startKey,
    String endKey,
  );
  Future<void> save(String uid, NutritionTarget target);
}
