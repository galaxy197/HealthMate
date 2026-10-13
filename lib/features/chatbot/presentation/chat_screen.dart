import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/pending_feature_card.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePage(
      title: 'Thêm một người đồng hành',
      subtitle: 'Khám phá thói quen cùng AI, khi bạn cần.',
      children: [
        PendingFeatureCard(
          icon: Icons.forum_outlined,
          title: 'Trò chuyện cùng HealthMate',
          description:
              'Trợ lý về thói quen và dinh dưỡng đang được chuẩn bị. '
              'Hiện chưa thể gửi tin nhắn hoặc nhận câu trả lời từ AI.',
        ),
        SizedBox(height: AppSpacing.md),
        PendingFeatureCard(
          icon: Icons.photo_camera_outlined,
          title: 'Nhận diện món ăn từ ảnh',
          description:
              'Food Scanner sẽ hỗ trợ gợi ý món ăn và cho bạn '
              'kiểm tra trước khi lưu. Hiện chưa thể chụp hoặc gửi ảnh.',
        ),
      ],
    );
  }
}
