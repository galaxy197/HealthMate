enum ChatSource { journal, ai, help }

enum KnowledgeTopic {
  balancedMeals('Một bữa ăn cân bằng gồm những gì?'),
  readingLabels('Cách đọc nhãn dinh dưỡng'),
  buildingHabits('Cách bắt đầu ghi nhật ký đều đặn');

  const KnowledgeTopic(this.label);
  final String label;
}

class ChatFailure implements Exception {
  const ChatFailure(this.message);
  final String message;
}

abstract final class ChatLimits {
  static const inputCharacters = 1000;
  static const outputCharacters = 6000;
  static const messagesPerSession = 40;
  static const recentSessions = 20;
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
  });
  final String id;
  final String title;
  final DateTime updatedAt;
  final int messageCount;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.sequence,
    required this.source,
  });
  final String id;
  final bool isUser;
  final String text;
  final int sequence;
  final ChatSource source;
}

class ChatTurn {
  const ChatTurn({
    required this.id,
    required this.question,
    required this.answer,
    required this.source,
  });
  final String id;
  final String question;
  final String answer;
  final ChatSource source;

  void validate() {
    if (!RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(id) ||
        question.trim().isEmpty ||
        question.length > ChatLimits.inputCharacters ||
        answer.trim().isEmpty ||
        answer.length > ChatLimits.outputCharacters) {
      throw const ChatFailure('Nội dung hội thoại không hợp lệ hoặc quá dài.');
    }
  }
}
