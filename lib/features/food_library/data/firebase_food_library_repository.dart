import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_library_models.dart';
import 'food_library_repository.dart';

class FirebaseFoodLibraryRepository implements FoodLibraryRepository {
  FirebaseFoodLibraryRepository(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    FoodSourceKind kind,
  ) {
    if (kind == FoodSourceKind.catalog) throw const FoodLibraryFailure();
    return firestore
        .collection('users')
        .doc(uid)
        .collection(kind == FoodSourceKind.custom ? 'custom_foods' : 'recipes');
  }

  LibraryEntry _read(
    FoodSourceKind kind,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    if (data['createdAt'] is! Timestamp || data['updatedAt'] is! Timestamp) {
      throw const FormatException();
    }
    return kind == FoodSourceKind.custom
        ? PersonalFood.fromData(doc.id, data)
        : FoodRecipe.fromData(doc.id, data);
  }

  @override
  String newId() => firestore.collection('users').doc().id;
  @override
  Stream<LibraryPage> watch(
    String uid,
    FoodSourceKind kind, {
    int limit = 40,
  }) async* {
    try {
      if (limit < 1) throw const FormatException();
      await for (final snap
          in _collection(uid, kind)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)) {
        if (snap.metadata.hasPendingWrites) continue;
        yield LibraryPage(
          items: snap.docs
              .map((doc) => _read(kind, doc))
              .toList(growable: false),
          fromCache: snap.metadata.isFromCache,
        );
      }
    } catch (_) {
      throw const FoodLibraryFailure(
        'Chưa tải được thư viện hoặc dữ liệu không hợp lệ. Hãy thử tải lại.',
      );
    }
  }

  @override
  Future<LibraryEntry?> load(String uid, FoodSourceKind kind, String id) async {
    try {
      final doc = await _collection(
        uid,
        kind,
      ).doc(id).get(const GetOptions(source: Source.server));
      return doc.exists ? _read(kind, doc) : null;
    } catch (_) {
      throw const FoodLibraryFailure(
        'Chưa xác nhận được nguồn món từ máy chủ. Hãy thử lại.',
      );
    }
  }

  @override
  Future<void> save(
    String uid,
    LibraryEntry entry, {
    required bool create,
  }) async {
    try {
      final data = entry.toData();
      final reference = _collection(uid, entry.kind).doc(entry.id);
      await firestore.runTransaction((tx) async {
        final before = await tx.get(reference);
        if (!create &&
            (before.data()?['schemaVersion'] as num? ?? 1) >
                (data['schemaVersion'] as num)) {
          data['schemaVersion'] = before.data()!['schemaVersion'];
        }
        if (create && before.exists) {
          if (!_same(data, {
            for (final key in data.keys) key: before.data()?[key],
          })) {
            throw const FoodLibraryFailure(
              'Thao tác trước đã lưu nội dung khác. Đóng form, tải lại và chọn Sửa.',
            );
          }
          return;
        }
        if (!create && !before.exists) {
          throw const FoodLibraryFailure(
            'Món đã bị xóa. Bản nháp vẫn được giữ để bạn kiểm tra.',
          );
        }
        tx.set(reference, {
          ...data,
          'createdAt':
              before.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final ack = await reference.get(const GetOptions(source: Source.server));
      if (!ack.exists ||
          ack.metadata.hasPendingWrites ||
          ack.metadata.isFromCache ||
          !_same(data, {for (final key in data.keys) key: ack.data()?[key]})) {
        throw const FoodLibraryFailure(
          'Chưa xác nhận được đúng nội dung đã lưu. Bản nháp vẫn được giữ.',
        );
      }
    } on FoodLibraryFailure {
      rethrow;
    } on FormatException catch (e) {
      throw FoodLibraryFailure(e.message);
    } catch (_) {
      throw const FoodLibraryFailure();
    }
  }

  @override
  Future<void> delete(String uid, FoodSourceKind kind, String id) async {
    try {
      final reference = _collection(uid, kind).doc(id);
      await reference.delete();
      final ack = await reference.get(const GetOptions(source: Source.server));
      if (ack.exists ||
          ack.metadata.isFromCache ||
          ack.metadata.hasPendingWrites) {
        throw const FoodLibraryFailure();
      }
    } catch (_) {
      throw const FoodLibraryFailure(
        'Chưa xác nhận được việc xóa món. Hãy kiểm tra kết nối và thử lại.',
      );
    }
  }
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _same(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        a.indexed.every((entry) => _same(entry.$2, b[entry.$1]));
  }
  return a == b;
}
