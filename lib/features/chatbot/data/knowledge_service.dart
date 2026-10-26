import '../models/chat_models.dart';

/// No API accepts free text, UID, history, profile, or repository context.
abstract interface class KnowledgeService {
  Stream<String> explain(KnowledgeTopic topic);
}

abstract final class KnowledgePrompt {
  static const system =
      'Bạn là trợ lý kiến thức chung của HealthMate. Trả lời tiếng Việt, '
      'ngắn gọn, dễ hiểu, tối đa 5 đoạn. Chỉ giải thích kiến thức phổ thông '
      'về ghi nhận thói quen và dinh dưỡng. Bạn không có dữ liệu người dùng. '
      'Không nêu số liệu cá nhân, không chẩn đoán, không kê thuốc, không '
      'đề xuất điều trị hoặc chế độ ăn đặc biệt. Không tạo điểm sức khỏe '
      'hay khẳng định quan hệ nhân quả. Nội dung chỉ tham khảo, không thay '
      'thế chuyên gia y tế. Không yêu cầu cung cấp thông tin nhạy cảm.';

  static String user(KnowledgeTopic topic) => switch (topic) {
    KnowledgeTopic.balancedMeals =>
      'Giải thích khái niệm bữa ăn cân bằng cho người trưởng thành nói chung; '
          'không cá nhân hóa và không chỉ định lượng calo hoặc khẩu phần.',
    KnowledgeTopic.readingLabels =>
      'Giải thích cách đọc nhãn dinh dưỡng: cơ sở khẩu phần, năng lượng và '
          'các chất đa lượng; phân biệt mỗi khẩu phần với mỗi 100 g.',
    KnowledgeTopic.buildingHabits =>
      'Gợi ý cách bắt đầu ghi nhật ký bữa ăn, nước và vận động đều đặn, '
          'không gây áp lực và không suy đoán sức khỏe từ ngày thiếu bản ghi.',
    KnowledgeTopic.protein =>
      'Giải thích vai trò của đạm và ví dụ nguồn đạm trong bữa ăn thông thường. '
          'Không tính nhu cầu cá nhân hoặc kê chế độ ăn.',
    KnowledgeTopic.fiber =>
      'Giải thích chất xơ, nguồn thực phẩm phổ biến và cách đọc chất xơ trên nhãn. '
          'Không đưa chỉ định y tế hoặc nhu cầu cá nhân.',
    KnowledgeTopic.carbohydrates =>
      'Giải thích carbohydrate, tinh bột và đường; ví dụ thực phẩm và cách đọc nhãn. '
          'Không khuyên loại bỏ nhóm thực phẩm hoặc điều trị bệnh.',
    KnowledgeTopic.fats =>
      'Giải thích chất béo không bão hòa, bão hòa và chuyển hóa bằng ví dụ dễ hiểu. '
          'Không kê chế độ ăn hoặc tư vấn điều trị.',
    KnowledgeTopic.hydration =>
      'Gợi ý cách xây dựng thói quen ghi lại nước đã uống và nhắc nhớ sinh hoạt. '
          'Không chỉ định lượng nước cá nhân hay điều trị bệnh.',
    KnowledgeTopic.portions =>
      'Giải thích khẩu phần, gram, thực phẩm sống/chín, phần ăn được và dầu chế biến. '
          'Nêu giới hạn ước lượng từ ảnh và lợi ích kiểm tra bằng cân.',
    KnowledgeTopic.energyBalance =>
      'Giải thích kcal, cân bằng năng lượng và giới hạn của số liệu nhật ký. '
          'Không tính mức ăn cá nhân hoặc hứa kết quả giảm cân.',
  };
}

ChatFailure knowledgeFailure(Object error) {
  // SDK details can contain request information; never expose or log them.
  final text = error.toString().toLowerCase();
  if (text.contains('429') ||
      text.contains('quota') ||
      text.contains('resource_exhausted')) {
    return const ChatFailure(
      'AI đã chạm hạn mức. Hãy thử lại sau; tra cứu nhật ký vẫn dùng được.',
    );
  }
  if (text.contains('403') ||
      text.contains('app check') ||
      text.contains('permission')) {
    return const ChatFailure(
      'Chưa xác thực được dịch vụ AI. Kiểm tra cấu hình App Check.',
    );
  }
  if (text.contains('404') || text.contains('model not found')) {
    return const ChatFailure(
      'Mô hình AI chưa khả dụng. Cần kiểm tra cấu hình model.',
    );
  }
  return const ChatFailure(
    'Chưa nhận được câu trả lời AI. Kiểm tra mạng rồi thử lại.',
  );
}
