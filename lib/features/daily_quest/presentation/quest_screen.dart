import 'package:flutter/material.dart';

import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/pending_feature_card.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePage(
      title: 'Nhịp khỏe mỗi ngày',
      subtitle: 'Những nhiệm vụ nhỏ, theo nhịp sống của bạn.',
      children: [
        PendingFeatureCard(
          icon: Icons.eco_outlined,
          title: 'Daily Health Quest',
          description:
              'Nhiệm vụ hằng ngày sẽ được gợi ý từ mục tiêu và '
              'nhật ký của bạn. Tính năng chưa tạo hoặc lưu nhiệm vụ '
              'trong phiên bản này.',
        ),
      ],
    );
  }
}
