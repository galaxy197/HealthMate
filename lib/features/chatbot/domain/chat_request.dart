import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../models/chat_models.dart';

enum ChatIntent {
  nutrition,
  water,
  activity,
  summary,
  remaining,
  weight,
  knowledge,
  help,
}

/// A bounded local query plan. Free-text and personal data never reach Gemini.
class ChatRequest {
  const ChatRequest({
    required this.intent,
    required this.start,
    required this.end,
    this.topic,
    this.message,
  });
  final ChatIntent intent;
  final DateTime start;
  final DateTime end;
  final KnowledgeTopic? topic;
  final String? message;
  int get days => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  bool get isPersonal =>
      ![ChatIntent.help, ChatIntent.knowledge].contains(intent);
}

bool _has(String s, String pattern) => RegExp(pattern).hasMatch(s);

KnowledgeTopic? knowledgeTopicForQuestion(String question) {
  final s = normalizeFoodSearch(question);
  if (!_has(
    s,
    r'la gi|giai thich|vai tro|nguon|thuc pham nao|cach |khac nhau|phan biet|hieu ve|gom nhung gi',
  )) {
    return null;
  }
  if (_has(s, r'\bdam\b|protein')) return KnowledgeTopic.protein;
  if (s.contains('chat xo')) return KnowledgeTopic.fiber;
  if (_has(s, r'nhan dinh duong')) return KnowledgeTopic.readingLabels;
  if (_has(s, r'carb|tinh bot|duong')) return KnowledgeTopic.carbohydrates;
  if (_has(s, r'chat beo|dau mo')) return KnowledgeTopic.fats;
  if (_has(s, r'khau phan|song chin|song va chin|can thuc pham')) {
    return KnowledgeTopic.portions;
  }
  if (_has(s, r'calo|kcal|nang luong')) return KnowledgeTopic.energyBalance;
  if (_has(s, r'uong nuoc')) return KnowledgeTopic.hydration;
  if (_has(s, r'can bang|bua an')) return KnowledgeTopic.balancedMeals;
  if (_has(s, r'thoi quen|ghi nhat ky')) return KnowledgeTopic.buildingHabits;
  return null;
}

ChatRequest planChatRequest(
  String question,
  DateTime selected,
  DateTime now, {
  ChatRequest? previous,
}) {
  final s = normalizeFoodSearch(question);
  final today = localDateOnly(now);
  var start = localDateOnly(selected);
  var end = DateTime(start.year, start.month, start.day + 1);
  ChatRequest help(String message) => ChatRequest(
    intent: ChatIntent.help,
    start: start,
    end: end,
    message: message,
  );
  if (_has(
    s,
    r'\b(benh|thuoc|chan doan|dieu tri|trieu chung|tieu duong|ung thu|mang thai|cho con bu)\b',
  )) {
    return help(
      'Tôi hỗ trợ theo dõi thói quen và giải thích dinh dưỡng chung. Với bệnh lý, thuốc hoặc chế độ ăn điều trị, hãy trao đổi với chuyên gia y tế. Bạn vẫn có thể tra cứu nhật ký đã ghi trong HealthMate.',
    );
  }
  if (_has(
        s,
        r'\b(xoa|luu|ghi them|them bua|dat muc tieu|doi muc tieu|chinh sua|cap nhat|sua (bua|nhat ky|ban ghi|muc tieu))\b',
      ) &&
      !_has(s, r'\bcach\b')) {
    return help(
      'Tôi chưa tự ghi, sửa hoặc xóa dữ liệu. Hãy dùng Nhật ký hoặc Mục tiêu để kiểm tra và xác nhận thay đổi; tôi có thể giúp bạn xem số liệu đã lưu.',
    );
  }
  final topic = knowledgeTopicForQuestion(question);
  if (topic != null) {
    return ChatRequest(
      intent: ChatIntent.knowledge,
      start: start,
      end: end,
      topic: topic,
    );
  }
  final week = DateTime(today.year, today.month, today.day - today.weekday + 1);
  final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(s);
  final date = RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{4}))?\b').firstMatch(s);
  final dateCount = RegExp(
    r'\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}/\d{1,2}(?:/\d{4})?\b',
  ).allMatches(s).length;
  if (dateCount > 1) {
    return help(
      'Hãy hỏi một ngày cụ thể, tuần này, tuần trước hoặc 7 ngày gần nhất. Tôi chưa tra cứu khoảng giữa hai ngày tự nhập.',
    );
  }
  final bool explicitPeriod;
  if (iso != null || date != null) {
    final y = iso != null
        ? int.parse(iso[1]!)
        : int.parse(date![3] ?? '${today.year}');
    final m = int.parse(iso != null ? iso[2]! : date![2]!);
    final d = int.parse(iso != null ? iso[3]! : date![1]!);
    final parsed = DateTime(y, m, d);
    if (y < 1900 || parsed.year != y || parsed.month != m || parsed.day != d) {
      return help(
        'Ngày chưa hợp lệ. Hãy nhập dd/MM/yyyy hoặc chọn ngày bằng nút lịch.',
      );
    }
    start = parsed;
    end = DateTime(y, m, d + 1);
    explicitPeriod = true;
  } else if (s.contains('tuan truoc')) {
    start = DateTime(week.year, week.month, week.day - 7);
    end = week;
    explicitPeriod = true;
  } else if (s.contains('tuan nay')) {
    start = week;
    end = DateTime(today.year, today.month, today.day + 1);
    explicitPeriod = true;
  } else if (_has(s, r'7 ngay|bay ngay')) {
    start = DateTime(today.year, today.month, today.day - 6);
    end = DateTime(today.year, today.month, today.day + 1);
    explicitPeriod = true;
  } else if (_has(
    s,
    r'\btuan\b|\bthang\b|\bnam nay\b|\d+ ngay|\bngay mai\b|\bngay \d+\b',
  )) {
    return help(
      'Tôi hỗ trợ một ngày, tuần này, tuần trước hoặc 7 ngày gần nhất. Với ngày cụ thể, nhập dd/MM/yyyy hoặc chọn trên lịch.',
    );
  } else if (_has(s, r'hom nay|hom qua|hom kia')) {
    final offset = s.contains('hom kia')
        ? 2
        : s.contains('hom qua')
        ? 1
        : 0;
    start = DateTime(today.year, today.month, today.day - offset);
    end = DateTime(start.year, start.month, start.day + 1);
    explicitPeriod = true;
  } else {
    explicitPeriod = false;
  }
  if (start.isAfter(today)) {
    return help('Ngày này chưa tới. Hãy chọn hôm nay hoặc một ngày đã qua.');
  }
  ChatIntent? intent;
  if (_has(
    s,
    r'con bao nhieu|con lai|con thieu|muc tieu|vuot|ngan sach|du chi tieu|dat chi tieu',
  )) {
    intent = ChatIntent.remaining;
    if (_has(s, r'nuoc|van dong|can nang|\bkg\b')) {
      return help(
        'Để xem các mục tiêu nước, vận động hoặc cân nặng, hãy mở Mục tiêu. Bạn vẫn có thể hỏi lượng nước, phút vận động hoặc cân nặng đã ghi; phần “còn lại” hiện hỗ trợ kcal và ba chất dinh dưỡng.',
      );
    }
  } else if (_has(s, r'can nang|\bcan\b|\bkg\b')) {
    intent = ChatIntent.weight;
  } else if (_has(s, r'tong ket|tom tat|nhat ky|tien do')) {
    intent = ChatIntent.summary;
  } else {
    final nutrition = _has(
      s,
      r'kcal|calo|calorie|\bdam\b|protein|carb|beo|chat xo|bua|\ban\b|dinh duong',
    );
    final water = _has(s, r'nuoc|\buong\b');
    final activity = _has(s, r'van dong|\btap\b|phut');
    if ([nutrition, water, activity].where((v) => v).length > 1) {
      intent = ChatIntent.summary;
    } else if (nutrition) {
      intent = ChatIntent.nutrition;
    } else if (water) {
      intent = ChatIntent.water;
    } else if (activity) {
      intent = ChatIntent.activity;
    }
  }
  final followup = _has(s, r'thi sao|con lai|con bao nhieu|^con |^the |^vay ');
  if (intent == ChatIntent.nutrition &&
      followup &&
      previous?.intent == ChatIntent.remaining) {
    intent = ChatIntent.remaining;
  }
  if (intent == null &&
      explicitPeriod &&
      previous?.isPersonal == true &&
      followup) {
    intent = previous!.intent;
  }
  if (intent == null) {
    return help(
      'Chào bạn! Tôi có thể xem kcal, đạm, nước, vận động, cân nặng và lượng còn lại so với mục tiêu. Thử “Tuần này tôi ăn bao nhiêu kcal?”, “Hôm nay còn bao nhiêu?” hoặc “Protein là gì?”.',
    );
  }
  if (!explicitPeriod && previous?.isPersonal == true && followup) {
    start = previous!.start;
    end = previous.end;
  }
  return ChatRequest(intent: intent, start: start, end: end);
}
