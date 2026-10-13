import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/pending_feature_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FeaturePage(
      title: 'Từng bước nhỏ,\nsống khỏe hơn.',
      subtitle: 'Một nơi để chăm chút cho những thói quen mỗi ngày.',
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Bắt đầu từ điều giản dị',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Khám phá các mục theo dõi bữa ăn, nước uống và vận động. '
                'Tính năng ghi nhận sẽ có trong các bản tiếp theo.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.journal),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Khám phá nhật ký'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Không gian của bạn', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        const PendingFeatureCard(
          icon: Icons.insights_rounded,
          title: 'Tổng quan đang được chuẩn bị',
          description:
              'Dinh dưỡng, thể trạng và tiến độ mục tiêu sẽ được '
              'tổng hợp từ nhật ký bạn xác nhận. Hiện chưa có dữ liệu để hiển thị.',
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.profile),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Tùy chỉnh giao diện'),
        ),
      ],
    );
  }
}
