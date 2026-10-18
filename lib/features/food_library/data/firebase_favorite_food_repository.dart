import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_food.dart';
import 'favorite_food_repository.dart';

class FirebaseFavoriteFoodRepository implements FavoriteFoodRepository {
  FirebaseFavoriteFoodRepository(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> _foods(String uid) =>
      firestore.collection('users').doc(uid).collection('favorite_foods');
  @override
  Stream<FavoriteFoodPage> watch(String uid, {int limit = 40}) async* {
    if (limit < 1) throw const FavoriteFoodFailure();
    try {
      await for (final snapshot
          in _foods(uid)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)) {
        if (snapshot.metadata.hasPendingWrites) continue;
        final items = snapshot.docs
            .map((doc) {
              final d = doc.data();
              final kind = FoodSourceKind.values
                  .where((kind) => kind.name == d['sourceKind'])
                  .firstOrNull;
              if (kind == null ||
                  d['schemaVersion'] != 1 ||
                  d['sourceId'] is! String ||
                  d['createdAt'] is! Timestamp ||
                  d['updatedAt'] is! Timestamp ||
                  favoriteFoodId(d['sourceId'] as String, sourceKind: kind) !=
                      doc.id) {
                throw const FormatException();
              }
              return FavoriteFood(
                sourceId: d['sourceId'] as String,
                sourceKind: kind,
              );
            })
            .toList(growable: false);
        yield FavoriteFoodPage(
          items: items,
          fromCache: snapshot.metadata.isFromCache,
        );
      }
    } on FirebaseException {
      throw const FavoriteFoodFailure();
    } on FormatException {
      throw const FavoriteFoodFailure(
        'Dữ liệu yêu thích không hợp lệ; hãy tải lại.',
      );
    }
  }

  @override
  Future<void> setFavorite(
    String uid,
    String sourceId,
    bool selected, {
    FoodSourceKind sourceKind = FoodSourceKind.catalog,
  }) async {
    final reference = _foods(
      uid,
    ).doc(favoriteFoodId(sourceId, sourceKind: sourceKind));
    try {
      if (!selected) {
        await reference.delete();
      } else {
        await firestore.runTransaction((transaction) async {
          final previous = await transaction.get(reference);
          if (previous.exists) return;
          transaction.set(reference, {
            'sourceKind': sourceKind.name,
            'sourceId': sourceId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'schemaVersion': 1,
          });
        });
      }
      final confirmed = await reference.get(
        const GetOptions(source: Source.server),
      );
      if (confirmed.metadata.isFromCache ||
          confirmed.metadata.hasPendingWrites ||
          confirmed.exists != selected ||
          (selected &&
              (confirmed.data()?['sourceId'] != sourceId ||
                  confirmed.data()?['sourceKind'] != sourceKind.name))) {
        throw const FavoriteFoodFailure(
          'Chưa xác nhận được thay đổi trên máy chủ. Thử lại cùng món không tạo trùng.',
        );
      }
    } on FirebaseException {
      throw const FavoriteFoodFailure();
    }
  }
}
