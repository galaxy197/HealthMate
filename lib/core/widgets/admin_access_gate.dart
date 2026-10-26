import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/admin_runtime.dart';
import '../../features/auth/providers/auth_providers.dart';

class AdminAccessGate extends ConsumerWidget {
  const AdminAccessGate({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(adminControlsEnabledProvider) ||
        ref.watch(authSessionProvider).value?.emailVerified != true) {
      return child;
    }
    final access = ref.watch(appAccountAccessProvider);
    final config = ref.watch(adminAppConfigProvider);
    final blocked = access.value?.suspended == true;
    final failed = access.hasError || config.hasError;
    final waiting =
        access.isLoading ||
        config.isLoading ||
        access.value?.verified != true ||
        config.value?.verified != true;
    final maintenance =
        !failed && !waiting && config.value?.maintenanceMode == true;
    if (!blocked && !failed && !waiting && !maintenance) return child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    blocked
                        ? Icons.lock_outline
                        : maintenance
                        ? Icons.build_outlined
                        : Icons.cloud_sync_outlined,
                    size: 48,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    blocked
                        ? 'Tạm khóa truy cập HealthMate'
                        : maintenance
                        ? 'HealthMate đang bảo trì'
                        : failed
                        ? 'Chưa xác nhận được quyền truy cập'
                        : 'Đang kiểm tra quyền truy cập',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    blocked
                        ? access.value!.reason
                        : maintenance
                        ? config.value!.maintenanceMessage
                        : 'Cần kết nối máy chủ để kiểm tra trạng thái tài khoản và cấu hình ứng dụng.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (waiting && !blocked && !maintenance && !failed)
                    const LinearProgressIndicator(),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(appAccountAccessProvider);
                      ref.invalidate(adminAppConfigProvider);
                    },
                    child: const Text('Kiểm tra lại'),
                  ),
                  TextButton(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
