import '../models/chat_models.dart';

abstract interface class ChatRepository {
  String newId();
  Future<List<ChatSession>> loadSessions(String uid);
  Future<List<ChatMessage>> loadMessages(String uid, String sessionId);

  /// Atomic and idempotent by turn.id, including retries after uncertain writes.
  Future<void> saveTurn(String uid, String sessionId, ChatTurn turn);
}
