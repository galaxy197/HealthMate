import '../models/assistant_request.dart';

abstract interface class ChatAssistant {
  Stream<String> reply(
    AssistantConversation conversation, {
    required String uid,
    required bool Function() isCurrent,
    required Future<List<ChatDataResult>> Function(List<ChatDataRequest>)
    readData,
  });
}
