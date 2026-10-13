import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../providers/auth_providers.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return Scaffold(
      body: SafeArea(
        child: FeaturePage(
          title: session.hasError ? 'Chưa thể mở phiên đăng nhập' : 'Chào bạn',
          subtitle: session.hasError
              ? 'Kiểm tra kết nối rồi thử lại để tiếp tục.'
              : 'HealthMate đang kiểm tra phiên đăng nhập của bạn.',
          children: [
            if (session.hasError)
              FilledButton.icon(
                onPressed: () => ref.invalidate(authSessionProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              )
            else
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Đang kiểm tra phiên đăng nhập',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
