import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../models/account_action_failure.dart';
import '../models/auth_failure.dart';
import '../models/auth_validation.dart';
import '../providers/auth_providers.dart';
import 'account_security_dialogs.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _registering = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isLoading ||
        ref.read(accountSecurityControllerProvider).isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    if (_registering) {
      await controller.register(email: _email.text, password: _password.text);
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
    if (mounted && !ref.read(authControllerProvider).hasError) {
      TextInput.finishAutofillContext();
    }
  }

  void _toggleMode() {
    ref.read(authControllerProvider.notifier).clearError();
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    _formKey.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _registering = !_registering;
      _hidePassword = true;
    });
  }

  Future<void> _forgotPassword() async {
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final email = await showResetPasswordDialog(
      context,
      initialEmail: _email.text,
    );
    if (email == null || !mounted) return;
    final sent = await ref
        .read(accountSecurityControllerProvider.notifier)
        .sendPasswordResetEmail(email);
    if (sent && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nếu email thuộc một tài khoản, Firebase sẽ gửi hướng dẫn đặt lại mật khẩu.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = ref.watch(authControllerProvider);
    final accountAction = ref.watch(accountSecurityControllerProvider);
    final busy = action.isLoading || accountAction.isLoading;
    final error = accountAction.error ?? action.error;
    return Scaffold(
      body: SafeArea(
        child: FeaturePage(
          title: _registering
              ? 'Bắt đầu cùng HealthMate'
              : 'Chào mừng bạn trở lại',
          subtitle: _registering
              ? 'Tạo tài khoản để bắt đầu hành trình theo dõi thói quen.'
              : 'Đăng nhập để mở không gian của bạn.',
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _registering ? 'Tạo tài khoản' : 'Đăng nhập',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          key: const ValueKey('auth-email'),
                          controller: _email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: AuthValidation.email,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const ValueKey('auth-password'),
                          controller: _password,
                          enabled: !busy,
                          obscureText: _hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: [
                            _registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: _registering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_registering) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            helperText: _registering
                                ? 'Ít nhất 6 ký tự. Nên kết hợp chữ, số và ký hiệu.'
                                : null,
                            helperMaxLines: 3,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: busy
                                  ? null
                                  : () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => AuthValidation.password(
                            value,
                            registering: _registering,
                          ),
                        ),
                        if (!_registering)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const ValueKey('forgot-password'),
                              onPressed: busy ? null : _forgotPassword,
                              child: const Text('Quên mật khẩu?'),
                            ),
                          ),
                        if (_registering) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            key: const ValueKey('auth-confirmation'),
                            controller: _confirmation,
                            enabled: !busy,
                            obscureText: _hidePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Nhập lại mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) => AuthValidation.confirmation(
                              value,
                              _password.text,
                            ),
                          ),
                        ],
                        if (error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              switch (error) {
                                AuthFailure failure => failure.message,
                                AccountActionFailure failure => failure.message,
                                _ =>
                                  'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
                              },
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          key: const ValueKey('auth-submit'),
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: 'Đang xử lý tài khoản',
                                  ),
                                )
                              : Text(
                                  _registering ? 'Tạo tài khoản' : 'Đăng nhập',
                                ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          key: const ValueKey('auth-toggle'),
                          onPressed: busy ? null : _toggleMode,
                          child: Text(
                            _registering
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
