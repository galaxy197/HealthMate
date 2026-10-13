import 'package:flutter/material.dart';

import '../models/auth_validation.dart';

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

Future<String?> showResetPasswordDialog(
  BuildContext context, {
  required String initialEmail,
}) => showDialog<String>(
  context: context,
  builder: (context) => _ResetPasswordDialog(initialEmail: initialEmail),
);

Future<ChangePasswordRequest?> showChangePasswordDialog(BuildContext context) =>
    showDialog<ChangePasswordRequest>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );

Future<String?> showDeleteAccountDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeleteAccountDialog(),
    );

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đặt lại mật khẩu'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        key: const ValueKey('reset-password-email'),
        controller: _email,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Email tài khoản',
          prefixIcon: Icon(Icons.alternate_email),
        ),
        validator: AuthValidation.email,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const ValueKey('send-reset-password'),
        onPressed: _submit,
        child: const Text('Gửi email'),
      ),
    ],
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ChangePasswordRequest(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi mật khẩu'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('current-password'),
              controller: _currentPassword,
              autofocus: true,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  AuthValidation.password(value, registering: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('new-password'),
              controller: _newPassword,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                helperText: 'Ít nhất 6 ký tự, không chỉ gồm khoảng trắng.',
                prefixIcon: Icon(Icons.password_rounded),
              ),
              validator: (value) {
                final validation = AuthValidation.password(
                  value,
                  registering: true,
                );
                if (validation != null) return validation;
                if (value == _currentPassword.text) {
                  return 'Mật khẩu mới cần khác mật khẩu hiện tại.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('new-password-confirmation'),
              controller: _confirmation,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                prefixIcon: const Icon(Icons.password_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  AuthValidation.confirmation(value, _newPassword.text),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const ValueKey('confirm-change-password'),
        onPressed: _submit,
        child: const Text('Đổi mật khẩu'),
      ),
    ],
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_understood || !_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Xóa vĩnh viễn tài khoản?'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HealthMate sẽ xóa hồ sơ, cân nặng, bữa ăn, nước uống, vận động và mọi dữ liệu thuộc tài khoản này. Thao tác không thể hoàn tác.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('delete-account-password'),
              controller: _password,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  AuthValidation.password(value, registering: false),
            ),
            CheckboxListTile(
              key: const ValueKey('delete-account-understood'),
              contentPadding: EdgeInsets.zero,
              value: _understood,
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
              title: const Text(
                'Tôi hiểu toàn bộ dữ liệu sẽ bị xóa vĩnh viễn.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Giữ tài khoản'),
      ),
      FilledButton(
        key: const ValueKey('confirm-delete-account'),
        onPressed: _understood ? _submit : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: const Text('Xóa tài khoản'),
      ),
    ],
  );
}
