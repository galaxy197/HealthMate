import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ai_food_suggestion.dart';
import 'food_scanner_service.dart';

abstract final class FoodScannerConfig {
  /// Override during build when Firebase publishes a newer supported model.
  static const modelName = String.fromEnvironment(
    'HEALTHMATE_AI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );
  static const maxImageBytes = 8 * 1024 * 1024;
}

class FirebaseFoodScannerService implements FoodScannerService {
  FirebaseFoodScannerService({GenerativeModel? model})
    : _model =
          model ??
          FirebaseAI.googleAI().generativeModel(
            model: FoodScannerConfig.modelName,
            generationConfig: GenerationConfig(
              temperature: 0.1,
              maxOutputTokens: 512,
              responseMimeType: 'application/json',
              responseSchema: Schema.object(
                properties: {
                  'dishName': Schema.string(
                    description: 'Tên ngắn gọn của món ăn bằng tiếng Việt.',
                  ),
                  'description': Schema.string(
                    description:
                        'Mô tả ngắn những gì nhìn thấy, không suy đoán dinh dưỡng.',
                  ),
                  'ingredients': Schema.array(
                    items: Schema.string(),
                    description:
                        'Nguyên liệu có thể nhìn thấy hoặc suy luận hợp lý.',
                  ),
                  'searchTerms': Schema.array(
                    items: Schema.string(),
                    description: 'Các tên ngắn để đối chiếu danh mục món ăn.',
                  ),
                },
                optionalProperties: const [],
              ),
            ),
            systemInstruction: Content.text(
              'Bạn hỗ trợ nhận diện món ăn từ ảnh. Chỉ mô tả món và nguyên liệu. '
              'Không đưa ra calories, macro, khối lượng, chẩn đoán hay lời khuyên y tế. '
              'Nếu ảnh không thể hiện món ăn, hãy gọi món là "Không xác định" và mô tả lý do.',
            ),
          );

  final GenerativeModel _model;

  @override
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (bytes.isEmpty || bytes.length > FoodScannerConfig.maxImageBytes) {
      throw const FoodScannerFailure(
        'Ảnh phải nhỏ hơn 8 MB. Hãy chọn ảnh khác hoặc chụp lại.',
      );
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw const FoodScannerFailure('Định dạng ảnh chưa được hỗ trợ.');
    }
    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(
            'Nhận diện món trong ảnh. Trả lời bằng tiếng Việt theo JSON schema đã cung cấp.',
          ),
          InlineDataPart(mimeType, bytes),
        ]),
      ]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const FormatException('Empty model response.');
      }
      return AiFoodSuggestion.fromJsonText(text);
    } on FoodScannerFailure {
      rethrow;
    } on FormatException {
      throw const FoodScannerFailure(
        'Gemini trả về dữ liệu không hợp lệ. Bạn có thể thử lại hoặc nhập thủ công.',
      );
    } on FirebaseAIException catch (error) {
      final text = error.message.toLowerCase();
      if (text.contains('quota') || text.contains('429')) {
        throw const FoodScannerFailure(
          'Đã chạm giới hạn Gemini miễn phí. Hãy thử lại sau hoặc nhập thủ công.',
        );
      }
      throw const FoodScannerFailure(
        'Chưa thể phân tích ảnh. Kiểm tra mạng rồi thử lại hoặc nhập thủ công.',
      );
    } catch (_) {
      throw const FoodScannerFailure(
        'Chưa thể phân tích ảnh. Bạn vẫn có thể nhập món thủ công.',
      );
    }
  }
}
