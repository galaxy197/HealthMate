import 'food_library_models.dart';
export 'food_library_models.dart' show FoodSourceKind;

class FavoriteFood {
  const FavoriteFood({
    required this.sourceId,
    this.sourceKind = FoodSourceKind.catalog,
  });
  final String sourceId;
  final FoodSourceKind sourceKind;
  String get id => favoriteFoodId(sourceId, sourceKind: sourceKind);
}

String favoriteFoodId(
  String sourceId, {
  FoodSourceKind sourceKind = FoodSourceKind.catalog,
}) {
  if (sourceId.isEmpty || sourceId.length > 100 || sourceId.contains('/')) {
    throw const FormatException('Mã món không hợp lệ.');
  }
  return '${sourceKind.name}_$sourceId';
}

class FavoriteFoodPage {
  const FavoriteFoodPage({required this.items, this.fromCache = false});
  final List<FavoriteFood> items;
  final bool fromCache;
}

class FavoriteFoodFailure implements Exception {
  const FavoriteFoodFailure([
    this.message =
        'Chưa thể tải hoặc lưu yêu thích. Hãy kiểm tra kết nối/quyền truy cập và thử lại.',
  ]);
  final String message;
}
