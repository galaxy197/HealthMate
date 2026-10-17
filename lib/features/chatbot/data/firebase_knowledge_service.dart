import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/operation_diagnostics.dart';

import '../models/chat_models.dart';
import 'knowledge_service.dart';

class FirebaseKnowledgeService implements KnowledgeService {
  FirebaseKnowledgeService({GenerativeModel? model}) : _providedModel = model;
  final GenerativeModel? _providedModel;
  static const modelName = String.fromEnvironment(
    'HEALTHMATE_CHAT_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  @override
  Stream<String> explain(KnowledgeTopic topic) async* {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ChatFailure(
        'AI hiện hỗ trợ bản Android có App Check. Bạn vẫn có thể tra cứu nhật ký tại đây.',
      );
    }
    final clock = Stopwatch()..start();
    operationDiagnostic('ai-knowledge', 'model-setup', 'start', clock);
    try {
      // Constructed lazily: opening Chat/local queries does not initialize AI.
      final model =
          _providedModel ??
          FirebaseAI.googleAI().generativeModel(
            model: modelName,
            systemInstruction: Content.system(KnowledgePrompt.system),
            generationConfig: GenerationConfig(
              temperature: 0.2,
              maxOutputTokens: 2048,
              thinkingConfig: ThinkingConfig.withThinkingLevel(
                ThinkingLevel.low,
              ),
            ),
          );
      var length = 0;
      var hasText = false;
      operationDiagnostic('ai-knowledge', 'sdk-request', 'start', clock);
      await for (final response in model.generateContentStream([
        Content.text(KnowledgePrompt.user(topic)),
      ])) {
        if (response.candidates.any(
          (candidate) =>
              candidate.finishReason != null &&
              candidate.finishReason != FinishReason.stop &&
              candidate.finishReason != FinishReason.unknown,
        )) {
          throw const ChatFailure(
            'Câu trả lời AI bị chặn hoặc chưa hoàn chỉnh. Hãy thử lại sau.',
          );
        }
        final text = response.text;
        if (text == null || text.isEmpty) continue;
        length += text.length;
        if (length > ChatLimits.outputCharacters) {
          throw const ChatFailure(
            'Câu trả lời AI vượt giới hạn độ dài. Hãy thử lại.',
          );
        }
        if (!hasText) {
          operationDiagnostic('ai-knowledge', 'first-chunk', 'success', clock);
        }
        hasText = true;
        yield text;
      }
      if (!hasText) {
        throw const ChatFailure(
          'AI chưa trả về nội dung hợp lệ. Hãy thử lại sau.',
        );
      }
      operationDiagnostic('ai-knowledge', 'stream-complete', 'success', clock);
    } on ChatFailure {
      rethrow;
    } catch (error) {
      operationDiagnostic(
        'ai-knowledge',
        'sdk-request',
        'error',
        clock,
        code: diagnosticErrorCode(error),
      );
      throw knowledgeFailure(error);
    }
  }
}
