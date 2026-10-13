import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data_repository.dart';
import '../data/auth_repository.dart';
import '../data/firebase_account_data_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../models/account_action_failure.dart';
import '../models/auth_failure.dart';
import '../models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final accountDataRepositoryProvider = Provider<AccountDataRepository>(
  (ref) => FirebaseAccountDataRepository(FirebaseFirestore.instance),
);

final authSessionProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (retryCount, error) => null,
);

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

final accountSecurityControllerProvider =
    NotifierProvider<AccountSecurityController, AsyncValue<void>>(
      AccountSecurityController.new,
    );

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<void> signIn({required String email, required String password}) =>
      _perform(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email.trim(), password: password),
      );

  Future<void> register({required String email, required String password}) =>
      _perform(
        () => ref
            .read(authRepositoryProvider)
            .register(email: email.trim(), password: password),
      );

  Future<void> signOut() =>
      _perform(() => ref.read(authRepositoryProvider).signOut());

  Future<void> _perform(Future<void> Function() operation) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await operation();
      if (ref.mounted) state = const AsyncData(null);
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(
          error is AuthFailure ? error : AuthFailure.fromCode('unknown'),
          stack,
        );
      }
    }
  }
}

class AccountSecurityController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on AuthFailure catch (error, stack) {
      // Do not reveal whether an email is registered.
      if (error.code == 'user-not-found') {
        if (ref.mounted) state = const AsyncData(null);
        return true;
      }
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(_safeFailure(error), stack);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _perform(() async {
    final repository = ref.read(authRepositoryProvider);
    await _reauthenticate(repository, currentPassword);
    await repository.updatePassword(newPassword);
  });

  Future<bool> deleteAccount(String currentPassword) async {
    if (state.isLoading) return false;
    final user = ref.read(authSessionProvider).value;
    if (user == null) {
      state = AsyncError(
        const AccountActionFailure(
          'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.',
        ),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    try {
      await _reauthenticate(repository, currentPassword);
      try {
        await ref
            .read(accountDataRepositoryProvider)
            .deleteAllUserData(user.uid);
      } on AccountDataFailure {
        throw const AccountActionFailure(
          'Chưa thể xóa hết dữ liệu. Một phần dữ liệu có thể đã được xóa; tài khoản vẫn được giữ để bạn thử lại an toàn.',
          dataMayBeDeleted: true,
        );
      }
      try {
        await repository.deleteCurrentUser();
      } on AuthFailure {
        throw const AccountActionFailure(
          'Dữ liệu HealthMate đã được xóa nhưng tài khoản đăng nhập chưa thể xóa. Hãy thử lại để hoàn tất.',
          dataMayBeDeleted: true,
        );
      }
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(_safeFailure(error), stack);
      return false;
    }
  }

  Future<bool> _perform(Future<void> Function() operation) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await operation();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(_safeFailure(error), stack);
      return false;
    }
  }

  Future<void> _reauthenticate(
    AuthRepository repository,
    String password,
  ) async {
    try {
      await repository.reauthenticateWithPassword(password);
    } on AuthFailure catch (error) {
      if (const {
        'wrong-password',
        'invalid-credential',
        'invalid-login-credentials',
      }.contains(error.code)) {
        throw const AccountActionFailure('Mật khẩu hiện tại chưa đúng.');
      }
      rethrow;
    }
  }

  Object _safeFailure(Object error) => switch (error) {
    AuthFailure failure => failure,
    AccountActionFailure failure => failure,
    _ => const AccountActionFailure(
      'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
    ),
  };
}
