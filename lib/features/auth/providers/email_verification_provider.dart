import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_failure.dart';
import 'auth_providers.dart';

class EmailVerificationState {
  const EmailVerificationState({
    this.busy = false,
    this.attempted = false,
    this.nextSendAt,
    this.message = '',
    this.error,
  });
  final bool busy, attempted;
  final DateTime? nextSendAt;
  final String message;
  final String? error;
}

final emailVerificationProvider =
    NotifierProvider<EmailVerificationController, EmailVerificationState>(
      EmailVerificationController.new,
    );

class EmailVerificationController extends Notifier<EmailVerificationState> {
  int _generation = 0;
  @override
  EmailVerificationState build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const EmailVerificationState();
  }

  int get cooldownSeconds {
    final ms =
        state.nextSendAt
            ?.difference(ref.read(authClockProvider)())
            .inMilliseconds ??
        0;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  Future<void> send({bool automatic = false}) async {
    final user = ref.read(authSessionProvider).value;
    if (user == null ||
        user.emailVerified ||
        state.busy ||
        cooldownSeconds > 0 ||
        (automatic && state.attempted)) {
      return;
    }
    final g = _generation;
    final previous = state;
    state = EmailVerificationState(
      busy: true,
      attempted: true,
      nextSendAt: previous.nextSendAt,
    );
    bool current() =>
        ref.mounted &&
        _generation == g &&
        ref.read(authSessionProvider).value?.uid == user.uid;
    try {
      await ref
          .read(authRepositoryProvider)
          .sendEmailVerification(expectedUid: user.uid);
      if (!current()) return;
      state = EmailVerificationState(
        attempted: true,
        nextSendAt: ref
            .read(authClockProvider)()
            .add(const Duration(seconds: 60)),
        message:
            'Đã gửi yêu cầu xác minh. Hãy kiểm tra hộp thư đến và thư rác.',
      );
    } catch (e) {
      if (!current()) return;
      state = EmailVerificationState(
        attempted: true,
        nextSendAt: e is AuthFailure && e.code == 'too-many-requests'
            ? ref.read(authClockProvider)().add(const Duration(seconds: 60))
            : previous.nextSendAt,
        error: e is AuthFailure
            ? e.message
            : AuthFailure.fromCode('unknown').message,
      );
    }
  }

  Future<void> refresh() async {
    final user = ref.read(authSessionProvider).value;
    if (user == null || state.busy) return;
    final g = _generation, previous = state;
    state = EmailVerificationState(
      busy: true,
      attempted: previous.attempted,
      nextSendAt: previous.nextSendAt,
      message: previous.message,
    );
    try {
      await ref.read(authRepositoryProvider).reloadUser(expectedUid: user.uid);
      if (!ref.mounted || _generation != g) return;
      state = EmailVerificationState(
        attempted: previous.attempted,
        nextSendAt: previous.nextSendAt,
        message:
            'Đã kiểm tra trạng thái xác minh. Nếu chưa tiếp tục được, hãy mở liên kết trong thư rồi kiểm tra lại.',
      );
    } catch (e) {
      if (!ref.mounted || _generation != g) return;
      state = EmailVerificationState(
        attempted: previous.attempted,
        nextSendAt: previous.nextSendAt,
        error: e is AuthFailure
            ? e.message
            : AuthFailure.fromCode('unknown').message,
      );
    }
  }
}
