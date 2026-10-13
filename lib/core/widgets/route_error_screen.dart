import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_spacing.dart';
import 'feature_page.dart';

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FeaturePage(
          title: 'Không tìm thấy trang',
          subtitle: 'Đường dẫn này chưa có trong HealthMate.',
          children: [
            const Icon(Icons.explore_outlined, size: 64),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Về Tổng quan'),
            ),
          ],
        ),
      ),
    );
  }
}
