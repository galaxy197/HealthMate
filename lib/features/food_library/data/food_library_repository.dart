import '../models/food_library_models.dart';

abstract interface class FoodLibraryRepository {
  String newId();
  Stream<LibraryPage> watch(String uid, FoodSourceKind kind, {int limit = 40});
  Future<LibraryEntry?> load(String uid, FoodSourceKind kind, String id);
  Future<void> save(String uid, LibraryEntry entry, {required bool create});
  Future<void> delete(String uid, FoodSourceKind kind, String id);
}
