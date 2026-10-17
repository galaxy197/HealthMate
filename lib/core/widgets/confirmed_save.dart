import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Keep a draft until the repository Future acknowledges the write. Never time
/// out and submit another write while the SDK may still be syncing this one.
mixin ConfirmedSave<T, W extends StatefulWidget> on State<W> {
  bool saving = false;
  String? saveError;

  Future<void> saveDraft(T draft, Future<bool> Function(T)? persist) async {
    if (saving) return;
    if (persist == null) {
      Navigator.pop(context, draft);
      return;
    }
    setState(() {
      saving = true;
      saveError = null;
    });
    bool saved;
    try {
      saved = await persist(draft);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, draft);
      return;
    }
    setState(() {
      saving = false;
      saveError =
          'Chưa thể lưu. Thông tin vẫn được giữ trong form; hãy thử lại.';
    });
  }

  Widget saveFeedback() => saving
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Đang chờ máy chủ xác nhận. Nếu mất mạng, hãy kết nối lại; không gửi lặp.',
              ),
            ],
          ),
        )
      : saveError == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            saveError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );

  Widget guardSave(Widget child) => PopScope(
    canPop: !saving,
    child: AbsorbPointer(absorbing: saving, child: child),
  );
}

/// Pageless entry forms must not survive a change of account, including while
/// they are waiting for server confirmation. No draft is persisted across UIDs.
class AccountBoundDialog extends ConsumerWidget {
  const AccountBoundDialog({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      before,
      after,
    ) {
      if (before == after) return;
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || route?.isActive != true) return;
        // Dispose the draft even if its pending-write PopScope blocks user back.
        navigator.popUntil(
          (candidate) => candidate == route || candidate.isFirst,
        );
        if (route!.isCurrent) navigator.removeRoute(route);
      });
    });
    return child;
  }
}
