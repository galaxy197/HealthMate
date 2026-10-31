import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import 'account_security_dialogs.dart';

/// Available from blocked access as well as Profile; never starts implicitly.
Future<void> requestAccountDeletion(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authSessionProvider).value;
  if (user == null) return;
  ref.read(accountSecurityControllerProvider.notifier).clearError();
  final password = await showDeleteAccountDialog(
    context,
    requirePassword: user.hasPassword,
  );
  if (password == null ||
      !context.mounted ||
      ref.read(authSessionProvider).value?.uid != user.uid) {
    return;
  }
  await ref
      .read(accountSecurityControllerProvider.notifier)
      .deleteAccount(password);
}
