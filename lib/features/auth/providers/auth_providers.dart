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
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  bool _current(int generation, String? uid) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(authSessionProvider).value?.uid == uid;

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (state.isLoading) return false;
    final generation = _generation;
    final uid = ref.read(authSessionProvider).value?.uid;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!_current(generation, uid)) return false;
      state = const AsyncData(null);
      return true;
    } on AuthFailure catch (error, stack) {
      if (!_current(generation, uid)) return false;
      // Do not reveal whether an email is registered.
      if (error.code == 'user-not-found') {
        state = const AsyncData(null);
        return true;
      }
      state = AsyncError(error, stack);
      return false;
    } catch (error, stack) {
      if (_current(generation, uid)) {
        state = AsyncError(_safeFailure(error), stack);
      }
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    return _perform((current) async {
      final repository = ref.read(authRepositoryProvider);
      await _reauthenticate(repository, currentPassword, uid);
      if (!current()) return;
      await repository.updatePassword(newPassword, expectedUid: uid);
    });
  }

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
    final generation = _generation;
    bool current() => _current(generation, user.uid);
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    try {
      await _reauthenticate(repository, currentPassword, user.uid);
      if (!current()) return false;
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
      if (!current()) return false;
      try {
        // Repository also checks the SDK's current UID, even before the auth
        // stream has delivered a changed session to Riverpod.
        await repository.deleteCurrentUser(expectedUid: user.uid);
      } on AuthFailure {
        throw const AccountActionFailure(
          'Dữ liệu HealthMate đã được xóa nhưng tài khoản đăng nhập chưa thể xóa. Hãy thử lại để hoàn tất.',
          dataMayBeDeleted: true,
        );
      }
      if (current()) state = const AsyncData(null);
      // Successful Auth deletion naturally emits null and resets the provider.
      return ref.mounted &&
          (ref.read(authSessionProvider).value?.uid == null || current());
    } catch (error, stack) {
      if (current()) state = AsyncError(_safeFailure(error), stack);
      return false;
    }
  }

  Future<bool> _perform(
    Future<void> Function(bool Function() current) operation,
  ) async {
    if (state.isLoading) return false;
    final generation = _generation;
    final uid = ref.read(authSessionProvider).value?.uid;
    bool current() => _current(generation, uid);
    state = const AsyncLoading();
    try {
      await operation(current);
      if (!current()) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (current()) state = AsyncError(_safeFailure(error), stack);
      return false;
    }
  }

  Future<void> _reauthenticate(
    AuthRepository repository,
    String password,
    String uid,
  ) async {
    try {
      await repository.reauthenticateWithPassword(password, expectedUid: uid);
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
