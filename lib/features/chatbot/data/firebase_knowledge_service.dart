import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import 'knowledge_service.dart';

class FirebaseKnowledgeService implements KnowledgeService {
  FirebaseKnowledgeService();

  @override
  Stream<String> explain(KnowledgeTopic topic) async* {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ChatFailure(
        'AI hiện hỗ trợ bản Android có App Check. Bạn vẫn có thể tra cứu nhật ký tại đây.',
      );
    }
    // The former Firebase AI route had no authoritative quota/policy gate.
    // Do not silently send Google-consented content to a different provider.
    throw const ChatFailure(
      'Kiến thức AI trực tiếp đang tạm dừng để cấu hình bảo vệ hạn mức. Bạn có thể dùng chat AI đã cấu hình hoặc tra cứu nhật ký.',
    );
  }
}
