import 'dart:async';

import 'package:healthmate/features/chatbot/data/chat_repository.dart';
import 'package:healthmate/features/chatbot/data/knowledge_service.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';

class FakeChatRepository implements ChatRepository {
  final sessions = <String, Map<String, List<ChatMessage>>>{};
  final savedTurnIds = <String>{};
  final savedUids = <String>[];
  int _counter = 0;
  int saveCalls = 0;
  int loadCalls = 0;
  bool failLoad = false;
  bool failSave = false;
  bool failAfterSave = false;
  Completer<void>? pendingLoad;
  Completer<void>? pendingSave;

  @override
  String newId() => (++_counter).toString().padLeft(20, '0');

  @override
  Future<List<ChatSession>> loadSessions(String uid) async {
    loadCalls++;
    await pendingLoad?.future;
    if (failLoad) throw const ChatFailure('Không tải được lịch sử.');
    return (sessions[uid] ?? {}).entries
        .map(
          (entry) => ChatSession(
            id: entry.key,
            title: 'Trò chuyện HealthMate',
            updatedAt: DateTime(2026, 10, 16),
            messageCount: entry.value.length,
          ),
        )
        .take(ChatLimits.recentSessions)
        .toList();
  }

  @override
  Future<List<ChatMessage>> loadMessages(String uid, String sessionId) async {
    await pendingLoad?.future;
    if (failLoad) throw const ChatFailure('Không tải được hội thoại.');
    return [...?sessions[uid]?[sessionId]];
  }

  @override
  Future<void> saveTurn(String uid, String sessionId, ChatTurn turn) async {
    saveCalls++;
    await pendingSave?.future;
    if (failSave) throw const ChatFailure('Không lưu được hội thoại.');
    turn.validate();
    final key = '$uid/$sessionId/${turn.id}';
    if (savedTurnIds.contains(key)) return;
    final messages = sessions
        .putIfAbsent(uid, () => {})
        .putIfAbsent(sessionId, () => []);
    if (messages.length >= ChatLimits.messagesPerSession) {
      throw const ChatFailure('Hội thoại đã đầy.');
    }
    final count = messages.length;
    messages.addAll([
      ChatMessage(
        id: '${turn.id}_u',
        isUser: true,
        text: turn.question,
        sequence: count,
        source: turn.source,
      ),
      ChatMessage(
        id: '${turn.id}_a',
        isUser: false,
        text: turn.answer,
        sequence: count + 1,
        source: turn.source,
      ),
    ]);
    savedTurnIds.add(key);
    savedUids.add(uid);
    if (failAfterSave) throw const ChatFailure('Chưa nhận được xác nhận lưu.');
  }
}

class FakeKnowledgeService implements KnowledgeService {
  final topics = <KnowledgeTopic>[];
  StreamController<String>? pending;
  Object? error;
  bool cancelled = false;

  @override
  Stream<String> explain(KnowledgeTopic topic) {
    topics.add(topic);
    if (pending != null) {
      return Stream.multi((controller) {
        final subscription = pending!.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = () {
          cancelled = true;
          subscription.cancel().ignore();
        };
      });
    }
    if (error != null) return Stream.error(error!);
    return Stream.fromIterable(['Kiến thức chung. ', 'Chỉ tham khảo.']);
  }
}
