import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/feature_page.dart';
import '../models/auth_failure.dart';
import '../providers/auth_providers.dart';
import '../providers/email_verification_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  int _displayedCooldown = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(emailVerificationProvider.notifier).send(automatic: true),
        );
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          ref.read(emailVerificationProvider.notifier).cooldownSeconds !=
              _displayedCooldown) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(emailVerificationProvider.notifier).refresh());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        Future.microtask(() {
          if (mounted) {
            ref.read(emailVerificationProvider.notifier).send(automatic: true);
          }
        });
      }
    });
    final user = ref.watch(authSessionProvider).value,
        state = ref.watch(emailVerificationProvider),
        auth = ref.watch(authControllerProvider);
    final controller = ref.read(emailVerificationProvider.notifier),
        seconds = controller.cooldownSeconds;
    _displayedCooldown = seconds;
    final busy = state.busy || auth.isLoading;
    return Scaffold(
      body: SafeArea(
        child: FeaturePage(
          title: 'Xác minh email của bạn',
          subtitle: 'Mở liên kết xác minh trong email để tiếp tục.',
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, size: 56),
                    const SizedBox(height: 20),
                    Text(
                      user?.email ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Mở email xác minh từ HealthMate.\n2. Bấm liên kết xác minh.\n3. Quay lại và bấm “Tôi đã xác minh”.',
                    ),
                    const SizedBox(height: 16),
                    if (state.message.isNotEmpty)
                      Text(
                        state.message,
                        key: const ValueKey('verification-message'),
                      ),
                    if (state.error != null || auth.hasError)
                      Text(
                        state.error ??
                            (auth.error is AuthFailure
                                ? (auth.error as AuthFailure).message
                                : 'Chưa thể đăng xuất.'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('verification-check'),
                      onPressed: busy ? null : controller.refresh,
                      child: Text(
                        state.busy ? 'Đang xử lý…' : 'Tôi đã xác minh',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('verification-resend'),
                      onPressed: busy || seconds > 0 ? null : controller.send,
                      child: Text(
                        seconds > 0
                            ? 'Gửi lại sau ${seconds}s'
                            : 'Gửi lại email xác minh',
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('verification-sign-out'),
                      onPressed: busy
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                      child: const Text('Dùng tài khoản khác'),
                    ),
                    const Text(
                      'Chưa thấy thư? Kiểm tra địa chỉ email và thư rác. Có thể gửi lại khi hết thời gian chờ.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
