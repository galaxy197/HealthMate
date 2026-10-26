import 'package:intl/intl.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/assistant_request.dart';
import '../models/chat_models.dart';
import 'chat_request.dart';
import 'personal_chat_context.dart';

class ChatDataReader {
  const ChatDataReader({required this.personal, required this.loadCatalog});
  final PersonalChatContext personal;
  final Future<List<FoodCatalogItem>> Function() loadCatalog;

  Future<List<ChatDataResult>> read(
    String uid,
    List<ChatDataRequest> requests,
    DateTime today,
    bool Function() isCurrent,
  ) async {
    void check() {
      if (!isCurrent()) throw const ChatFailure('Phiên đăng nhập đã thay đổi.');
    }

    if (requests.length > 3 || uid.isEmpty) {
      throw const ChatFailure('Quá nhiều yêu cầu dữ liệu.');
    }
    final results = <ChatDataResult>[];
    for (final original in requests) {
      check();
      final r = ChatDataRequest.parse(original.toJson(), today);
      String text;
      if (r.kind == 'foods') {
        final catalog = await loadCatalog();
        check();
        final query = normalizeFoodSearch(r.query!);
        final matches = catalog
            .where(
              (f) =>
                  f.dataSource != FoodDataSource.usda &&
                  f.servingBasis == ServingBasis.per100g &&
                  f.unit == 'g' &&
                  f.hasNutritionData &&
                  f.sourceLabel.trim().isNotEmpty &&
                  (query.isEmpty ||
                      normalizeFoodSearch(
                        '${f.name} ${f.alternateNames.join(' ')}',
                      ).contains(query)),
            )
            .take(5)
            .toList();
        String n(num value) => NumberFormat('0.##', 'vi').format(value);
        final lines = <String>[];
        for (final f in matches) {
          final v = f.forGrams(r.grams!);
          if ([
            v.kcal,
            v.proteinG,
            v.carbsG,
            v.fatG,
          ].any((x) => !x.isFinite || x < 0)) {
            continue;
          }
          lines.add(
            '${f.name}: ${n(r.grams!)} g; ${n(v.kcal)} kcal; '
            'đạm ${v.proteinKnown ? '${n(v.proteinG)} g' : 'chưa biết'}; '
            'carb ${v.carbsKnown ? '${n(v.carbsG)} g' : 'chưa biết'}; '
            'béo ${v.fatKnown ? '${n(v.fatG)} g' : 'chưa biết'}; '
            'nguồn ${f.sourceLabel}; ${f.isEstimated ? 'ước tính' : 'tham khảo theo nguồn'}.',
          );
        }
        text = lines.isEmpty
            ? 'Chưa tìm được món phù hợp có nguồn trong danh mục. Không tự tạo số dinh dưỡng.'
            : 'Các lựa chọn trong danh mục cho cùng khẩu phần, không phải tổng một bữa:\n${lines.join('\n')}';
      } else {
        text = await personal.answer(
          uid,
          ChatRequest(
            intent: switch (r.kind) {
              'nutrition' => ChatIntent.nutrition,
              'remaining' => ChatIntent.remaining,
              'water' => ChatIntent.water,
              'activity' => ChatIntent.activity,
              'weight' => ChatIntent.weight,
              _ => throw const ChatFailure('Nguồn dữ liệu không hợp lệ.'),
            },
            start: r.start!,
            end: DateTime(r.end!.year, r.end!.month, r.end!.day + 1),
          ),
        );
      }
      check();
      // Never send a silently truncated number/source to the model.
      if (text.length > 4000) {
        throw const ChatFailure(
          'Kết quả tra cứu quá dài. Hãy thu hẹp câu hỏi.',
        );
      }
      results.add(ChatDataResult(r, text));
    }
    return results;
  }
}
