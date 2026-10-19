import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_template.dart';

abstract interface class MealTemplateRepository {
  String newId();
  Stream<List<MealTemplate>> watch(String uid, {int limit = 40});
  Future<void> save(String uid, MealTemplate template, {required bool create});
  Future<void> delete(String uid, String id);
}

class FirebaseMealTemplateRepository implements MealTemplateRepository {
  FirebaseMealTemplateRepository(this.db);
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> _templates(String uid) =>
      db.collection('users').doc(uid).collection('meal_templates');
  @override
  String newId() => db.collection('users').doc().id;
  @override
  Stream<List<MealTemplate>> watch(String uid, {int limit = 40}) async* {
    if (limit < 1 || limit > 200) throw const MealTemplateFailure();
    try {
      await for (final page
          in _templates(uid)
              .orderBy('updatedAt', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)) {
        if (page.metadata.hasPendingWrites || page.metadata.isFromCache) {
          continue;
        }
        if (page.docs.any(
          (doc) =>
              doc.data()['createdAt'] is! Timestamp ||
              doc.data()['updatedAt'] is! Timestamp,
        )) {
          throw const MealTemplateFailure(
            'Bữa mẫu có metadata không hợp lệ. Hãy tải lại.',
          );
        }
        yield [
          for (final doc in page.docs)
            MealTemplate.fromData(doc.id, doc.data()),
        ];
      }
    } catch (_) {
      throw const MealTemplateFailure();
    }
  }

  @override
  Future<void> save(
    String uid,
    MealTemplate template, {
    required bool create,
  }) async {
    try {
      final data = template.toData(), ref = _templates(uid).doc(template.id);
      await db.runTransaction((tx) async {
        final before = await tx.get(ref);
        if (!create &&
            (before.data()?['schemaVersion'] as num? ?? 1) >
                (data['schemaVersion'] as num)) {
          data.addAll(
            template.toData(
              minimumSchemaVersion: (before.data()!['schemaVersion'] as num)
                  .toInt(),
            ),
          );
        }
        if (create && before.exists) {
          if (!_same(data, {
            for (final key in data.keys) key: before.data()?[key],
          })) {
            throw const MealTemplateFailure(
              'Mã thao tác trước đã lưu nội dung khác. Tải lại bữa mẫu rồi chọn Sửa.',
            );
          }
          return;
        }
        if (!create && !before.exists) {
          throw const MealTemplateFailure(
            'Bữa mẫu đã bị xóa. Bản nháp vẫn được giữ.',
          );
        }
        tx.set(ref, {
          ...data,
          'createdAt':
              before.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final ack = await ref.get(const GetOptions(source: Source.server));
      if (!ack.exists ||
          ack.metadata.hasPendingWrites ||
          ack.metadata.isFromCache ||
          !_same(data, {for (final key in data.keys) key: ack.data()?[key]})) {
        throw const MealTemplateFailure();
      }
    } on MealTemplateFailure {
      rethrow;
    } catch (_) {
      throw const MealTemplateFailure();
    }
  }

  @override
  Future<void> delete(String uid, String id) async {
    try {
      final ref = _templates(uid).doc(id);
      await ref.delete();
      if ((await ref.get(const GetOptions(source: Source.server))).exists) {
        throw const MealTemplateFailure();
      }
    } catch (_) {
      throw const MealTemplateFailure();
    }
  }
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length && a.indexed.every((e) => _same(e.$2, b[e.$1]));
  }
  return a == b;
}
