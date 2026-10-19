import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_data_repository.dart';

class FirebaseAccountDataRepository implements AccountDataRepository {
  FirebaseAccountDataRepository(this._firestore);

  static const _batchSize = 400;
  static const _flatCollections = [
    'body_metrics',
    'meal_logs',
    'water_logs',
    'activity_logs',
    'goals',
    'daily_quests',
    'nutrition_targets',
    'favorite_foods',
    'custom_foods',
    'recipes',
    'meal_templates',
    'day_reviews',
  ];

  final FirebaseFirestore _firestore;

  @override
  Future<void> deleteAllUserData(String uid) async {
    final user = _firestore.collection('users').doc(uid);
    try {
      for (final collectionName in _flatCollections) {
        await _deleteCollection(user.collection(collectionName));
      }
      await _deleteChatSessions(user.collection('chat_sessions'));
      await user.delete();
    } on FirebaseException {
      throw const AccountDataFailure();
    } catch (error) {
      if (error is AccountDataFailure) rethrow;
      throw const AccountDataFailure();
    }
  }

  Future<void> _deleteChatSessions(
    CollectionReference<Map<String, dynamic>> sessions,
  ) async {
    while (true) {
      final snapshot = await sessions
          .limit(_batchSize)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      for (final session in snapshot.docs) {
        await _deleteCollection(session.reference.collection('messages'));
      }
      final batch = _firestore.batch();
      for (final session in snapshot.docs) {
        batch.delete(session.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection
          .limit(_batchSize)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
