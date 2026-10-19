import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../water/data/water_repository.dart';
import '../../water/models/water_log.dart';
import '../models/chat_models.dart';

enum JournalQuestion { nutrition, water, activity, summary }

/// Conservative routing: arbitrary user text never becomes an AI prompt.
JournalQuestion? journalQuestion(String question) {
  final text = question.toLowerCase();
  if (RegExp(
    r'\d|tuần|tháng|năm|hôm kia|ngày mai|chẩn đoán|thuốc|bệnh',
  ).hasMatch(text)) {
    return null;
  }
  if (RegExp(
    'tổng kết|tóm tắt|nhật ký|tong ket|tom tat|nhat ky',
  ).hasMatch(text)) {
    return JournalQuestion.summary;
  }
  final nutrition = RegExp(
    'kcal|calo|calorie|đạm|protein|carb|béo|dinh dưỡng|bữa|ăn|calo|bua|dinh duong',
  ).hasMatch(text);
  final water = RegExp('nước|uống|nuoc|uong').hasMatch(text);
  final activity = RegExp('vận động|tập|phút|van dong|tap|phut').hasMatch(text);
  if ([nutrition, water, activity].where((value) => value).length > 1) {
    return JournalQuestion.summary;
  }
  if (nutrition) return JournalQuestion.nutrition;
  if (water) return JournalQuestion.water;
  if (activity) return JournalQuestion.activity;
  return null;
}

DateTime journalQuestionDate(String question, DateTime selected, DateTime now) {
  final text = question.toLowerCase();
  if (text.contains('hôm qua') || text.contains('hom qua')) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  if (text.contains('hôm nay') || text.contains('hom nay')) {
    return localDateOnly(now);
  }
  return localDateOnly(selected);
}

/// Reads only the requested sources. Nothing returned here is sent to free AI.
class JournalChatContext {
  const JournalChatContext({
    required this.nutrition,
    required this.water,
    required this.activity,
  });
  final NutritionRepository nutrition;
  final WaterRepository water;
  final ActivityRepository activity;

  Future<String> answer(
    String uid,
    JournalQuestion question,
    DateTime date,
  ) async {
    final range = localDayRange(date);
    final number = NumberFormat('#,##0.##', 'vi');
    final offset = range.start.timeZoneOffset.inMinutes;
    final timezone =
        'UTC${offset < 0 ? '-' : '+'}${(offset.abs() ~/ 60).toString().padLeft(2, '0')}:${(offset.abs() % 60).toString().padLeft(2, '0')}';
    final lines = <String>[
      'Nhật ký ${DateFormat('dd/MM/yyyy').format(date)} ($timezone, múi giờ thiết bị).',
    ];
    // Each branch catches independently: unavailable is never represented as zero.
    Future<void> meals() async {
      try {
        final logs = await nutrition.loadRange(uid, range.start, range.end);
        if (logs.isEmpty) {
          lines.add('Bữa ăn: chưa có bản ghi; chưa thể xác định lượng đã ăn.');
        } else {
          final totals = totalMealNutrition(logs);
          lines.add(
            totals.hasCompleteMacros
                ? '${logs.length} bữa đã ghi: ${number.format(totals.kcal)} kcal. Đạm ${number.format(totals.proteinG)} g; tinh bột ${number.format(totals.carbsG)} g; béo ${number.format(totals.fatG)} g.'
                : '${logs.length} bữa đã ghi: ${number.format(totals.kcal)} kcal. Số liệu ba chất chưa đầy đủ; không coi phần chưa biết là 0.',
          );
        }
      } catch (_) {
        throw const ChatFailure(
          'Chưa tải được bữa ăn. Không thể xác định tổng; hãy thử lại.',
        );
      }
    }

    Future<void> drinks() async {
      try {
        final logs = await water.loadRange(uid, range.start, range.end);
        lines.add(
          logs.isEmpty
              ? 'Nước: chưa có bản ghi.'
              : 'Nước đã ghi: ${number.format(totalWaterMl(logs))} ml (${logs.length} lần).',
        );
      } catch (_) {
        throw const ChatFailure(
          'Chưa tải được nước uống. Không thể xác định tổng; hãy thử lại.',
        );
      }
    }

    Future<void> activities() async {
      try {
        final logs = await activity.loadRange(uid, range.start, range.end);
        lines.add(
          logs.isEmpty
              ? 'Vận động: chưa có bản ghi.'
              : 'Vận động đã ghi: ${number.format(totalActivityMinutes(logs))} phút (${logs.length} lần).',
        );
      } catch (_) {
        throw const ChatFailure(
          'Chưa tải được vận động. Không thể xác định tổng; hãy thử lại.',
        );
      }
    }

    // A summary is all-or-error, so a failed source cannot masquerade as a full day.
    if (question == JournalQuestion.nutrition ||
        question == JournalQuestion.summary) {
      await meals();
    }
    if (question == JournalQuestion.water ||
        question == JournalQuestion.summary) {
      await drinks();
    }
    if (question == JournalQuestion.activity ||
        question == JournalQuestion.summary) {
      await activities();
    }
    lines.add(
      'Chỉ cộng dữ liệu đã ghi, không phản ánh toàn bộ ngày hay đánh giá sức khỏe. Số liệu này được tính trong ứng dụng, không gửi đến AI.',
    );
    return lines.join('\n\n');
  }
}
