import '../../../core/utils/local_date_key.dart';
import 'chat_models.dart';

/// A bounded read request, never a UID, Firestore path or arbitrary query.
class ChatDataRequest {
  const ChatDataRequest({
    required this.kind,
    this.start,
    this.end,
    this.query,
    this.grams,
  });
  final String kind;
  final DateTime? start, end; // Inclusive local dates.
  final String? query;
  final double? grams;
  static const kinds = [
    'nutrition',
    'remaining',
    'water',
    'activity',
    'weight',
    'foods',
  ];

  factory ChatDataRequest.parse(Object? raw, DateTime today) {
    if (raw is! Map<String, dynamic> ||
        raw.keys.any(
          (k) =>
              !['kind', 'startDate', 'endDate', 'query', 'grams'].contains(k),
        ) ||
        !kinds.contains(raw['kind'])) {
      throw const ChatFailure('AI yêu cầu dữ liệu ngoài phạm vi cho phép.');
    }
    final kind = raw['kind'] as String;
    if (kind == 'foods') {
      final query = raw['query'];
      final grams = raw['grams'];
      if (raw.containsKey('startDate') ||
          raw.containsKey('endDate') ||
          query is! String ||
          query.length > 80 ||
          grams is! num ||
          !grams.isFinite ||
          grams < 10 ||
          grams > 1000) {
        throw const ChatFailure('Yêu cầu tìm món chưa hợp lệ.');
      }
      return ChatDataRequest(kind: kind, query: query, grams: grams.toDouble());
    }
    DateTime date(Object? value) {
      if (value is! String || !isValidDateKey(value)) {
        throw const ChatFailure('Ngày AI yêu cầu chưa hợp lệ.');
      }
      return DateTime.parse(value);
    }

    final start = date(raw['startDate']), end = date(raw['endDate']);
    final days =
        DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
    if (raw.containsKey('query') ||
        raw.containsKey('grams') ||
        days < 1 ||
        days > 7 ||
        end.isAfter(localDateOnly(today))) {
      throw const ChatFailure(
        'Mỗi lượt tra cứu hỗ trợ tối đa 7 ngày đã qua. Hãy hỏi một khoảng ngắn hơn.',
      );
    }
    return ChatDataRequest(kind: kind, start: start, end: end);
  }

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (kind == 'foods') ...{
      'query': query,
      'grams': grams,
    } else ...{
      'startDate': localDateKey(start!),
      'endDate': localDateKey(end!),
    },
  };
}

class ChatDataResult {
  const ChatDataResult(this.request, this.text);
  final ChatDataRequest request;
  final String text;
  Map<String, Object?> toJson() => {'request': request.toJson(), 'text': text};
}

class AssistantConversation {
  const AssistantConversation({
    required this.question,
    required this.history,
    required this.today,
    required this.selectedDate,
  });
  final String question;
  final List<ChatMessage> history;
  final DateTime today, selectedDate;
  Map<String, Object?> body(String phase) {
    if (question.trim().isEmpty ||
        question.length > ChatLimits.inputCharacters) {
      throw const ChatFailure('Câu hỏi quá dài hoặc trống.');
    }
    final recent = history
        .skip((history.length - 6).clamp(0, history.length))
        .toList();
    if (recent.length.isOdd ||
        recent.indexed.any((e) => e.$2.isUser != e.$1.isEven)) {
      throw const ChatFailure(
        'Lịch sử chưa đầy đủ. Hãy mở lại cuộc trò chuyện.',
      );
    }
    return {
      'version': 1,
      'phase': phase,
      'question': question,
      'today': localDateKey(today),
      'selectedDate': localDateKey(selectedDate),
      'timezoneOffsetMinutes': selectedDate.timeZoneOffset.inMinutes,
      'history': [
        for (final m in recent)
          {
            'role': m.isUser ? 'user' : 'assistant',
            'content': _conversationText(m),
          },
      ],
    };
  }

  String _conversationText(ChatMessage message) {
    // Reference tables are fetched again when relevant; keep conversational text.
    final text = message.isUser
        ? message.text
        : message.text.split('\n\nSố liệu tra cứu từ HealthMate:\n').first;
    return text.length > 1200 ? text.substring(0, 1200) : text;
  }
}
