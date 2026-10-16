import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import 'chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      firestore.collection('users').doc(uid).collection('chat_sessions');

  @override
  String newId() => firestore.collection('chat_id_allocator').doc().id;

  @override
  Future<List<ChatSession>> loadSessions(String uid) => _guard(() async {
    final data = await _sessions(uid)
        .orderBy('updatedAt', descending: true)
        .limit(ChatLimits.recentSessions)
        .get(const GetOptions(source: Source.server));
    return data.docs.map((doc) {
      final d = doc.data();
      return ChatSession(
        id: doc.id,
        title: d['title'] as String,
        updatedAt: (d['updatedAt'] as Timestamp).toDate(),
        messageCount: d['messageCount'] as int,
      );
    }).toList();
  });

  @override
  Future<List<ChatMessage>> loadMessages(String uid, String sessionId) =>
      _guard(() async {
        final data = await _sessions(uid)
            .doc(sessionId)
            .collection('messages')
            .orderBy('sequence')
            .limit(ChatLimits.messagesPerSession)
            .get(const GetOptions(source: Source.server));
        return data.docs.map((doc) {
          final d = doc.data();
          return ChatMessage(
            id: doc.id,
            isUser: d['role'] == 'user',
            text: d['text'] as String,
            sequence: d['sequence'] as int,
            source: ChatSource.values.byName(d['source'] as String),
          );
        }).toList();
      });

  @override
  Future<void> saveTurn(String uid, String sessionId, ChatTurn turn) =>
      _guard(() async {
        turn.validate();
        final session = _sessions(uid).doc(sessionId);
        final userMessage = session.collection('messages').doc('${turn.id}_u');
        final assistantMessage = session
            .collection('messages')
            .doc('${turn.id}_a');
        await firestore.runTransaction((transaction) async {
          final previous = await transaction.get(userMessage);
          if (previous.exists) return;
          final current = await transaction.get(session);
          final count = current.data()?['messageCount'] as int? ?? 0;
          if (count >= ChatLimits.messagesPerSession) {
            throw const ChatFailure(
              'Cuộc trò chuyện đã đủ 20 lượt. Hãy tạo cuộc trò chuyện mới.',
            );
          }
          final timestamp = FieldValue.serverTimestamp();
          if (current.exists) {
            transaction.update(session, {
              'messageCount': count + 2,
              'updatedAt': timestamp,
              'lastTurnId': turn.id,
            });
          } else {
            transaction.set(session, {
              'title': 'Trò chuyện HealthMate',
              'messageCount': 2,
              'createdAt': timestamp,
              'updatedAt': timestamp,
              'schemaVersion': 1,
              'lastTurnId': turn.id,
            });
          }
          Map<String, dynamic> message(bool user) => {
            'role': user ? 'user' : 'assistant',
            'text': user ? turn.question : turn.answer,
            'source': turn.source.name,
            'sequence': count + (user ? 0 : 1),
            'createdAt': timestamp,
            'schemaVersion': 1,
            'turnId': turn.id,
          };
          transaction.set(userMessage, message(true));
          transaction.set(assistantMessage, message(false));
        });
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 20));
    } on ChatFailure {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ChatFailure(
          'Chưa có quyền truy cập hội thoại. Kiểm tra tài khoản và Firestore Rules.',
        );
      }
      throw const ChatFailure(
        'Chưa thể tải hoặc lưu hội thoại. Kiểm tra mạng rồi thử lại.',
      );
    } catch (_) {
      throw const ChatFailure(
        'Chưa thể tải hoặc lưu hội thoại. Kiểm tra mạng rồi thử lại.',
      );
    }
  }
}
