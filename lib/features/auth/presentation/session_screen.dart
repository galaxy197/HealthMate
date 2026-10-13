import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final profile = ref.watch(userProfileProvider);
    final profileFailed = session.value != null && profile.hasError;
    final failed = session.hasError || profileFailed;
    return Scaffold(
      body: SafeArea(
        child: FeaturePage(
          title: session.hasError
              ? 'Chưa thể mở phiên đăng nhập'
              : profileFailed
              ? 'Chưa thể mở dữ liệu tài khoản'
              : 'Chào bạn',
          subtitle: failed
              ? 'Kiểm tra kết nối rồi thử lại để tiếp tục.'
              : session.value == null
              ? 'HealthMate đang kiểm tra phiên đăng nhập của bạn.'
              : 'HealthMate đang tải hồ sơ sức khỏe của bạn.',
          children: [
            if (failed)
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(authSessionProvider);
                  ref.invalidate(profileBootstrapProvider);
                  ref.invalidate(userProfileProvider);
                },
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
