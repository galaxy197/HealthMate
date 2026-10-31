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
import '../models/account_deletion_job.dart';
import '../../meal_drafts/data/meal_draft_store.dart';
import 'package:flutter/services.dart';
import '../../wellness/providers/wellness_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final authClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final accountDataRepositoryProvider = Provider<AccountDataRepository>(
  (ref) => FirebaseAccountDataRepository(FirebaseFirestore.instance),
);

final authSessionProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (retryCount, error) => null,
);

/// Independent of profile/admin runtime so deletion can resume after users/{uid}
/// is gone and suspended owners retain access to their deletion request.
final accountDeletionJobProvider = StreamProvider<AccountDeletionJob?>((ref) {
  final user = ref.watch(authSessionProvider).value;
  if (user?.emailVerified != true) return Stream.value(null);
  return ref.watch(accountDataRepositoryProvider).watchDeletion(user!.uid);
}, retry: (_, _) => null);

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

  Future<void> signInWithGoogle() =>
      _perform(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<void> signOut() => _perform(() async {
    final device = ref.read(wellnessDeviceProvider);
    if (device.supported) {
      try {
        await device.setAccount(null);
      } on MissingPluginException {
        /* No native feature on this platform. */
      }
    }
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      ref.invalidate(localWellnessProvider);
      rethrow;
    }
  });

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
  DateTime? _nextResetAt;
  int get resetCooldownSeconds {
    final ms =
        _nextResetAt
            ?.difference(ref.read(authClockProvider)())
            .inMilliseconds ??
        0;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

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
    if (state.isLoading || resetCooldownSeconds > 0) return false;
    final generation = _generation;
    final uid = ref.read(authSessionProvider).value?.uid;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!_current(generation, uid)) return false;
      _nextResetAt = ref
          .read(authClockProvider)()
          .add(const Duration(seconds: 60));
      state = const AsyncData(null);
      return true;
    } on AuthFailure catch (error, stack) {
      if (!_current(generation, uid)) return false;
      // Do not reveal whether an email is registered.
      if (error.code == 'user-not-found') {
        _nextResetAt = ref
            .read(authClockProvider)()
            .add(const Duration(seconds: 60));
        state = const AsyncData(null);
        return true;
      }
      if (error.code == 'too-many-requests') {
        _nextResetAt = ref
            .read(authClockProvider)()
            .add(const Duration(seconds: 60));
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
    if (uid == null ||
        ref.read(authSessionProvider).value?.hasPassword != true) {
      return false;
    }
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
      final data = ref.read(accountDataRepositoryProvider);
      try {
        // Confirmed on the server BEFORE deleting data or local state.
        await data.requestDeletion(user.uid);
      } on AccountDataFailure {
        throw const AccountActionFailure(
          'Chưa xác nhận được yêu cầu xóa trên máy chủ. Hãy kết nối mạng và thử lại; chưa báo hoàn tất.',
        );
      }
      if (!current()) return false;
      // Stop local writers first. Both operations are idempotent and persist a
      // per-UID block on supported native storage, including across restarts.
      try {
        final device = ref.read(wellnessDeviceProvider);
        final local = ref.read(privateLocalDataProvider);
        await Future.wait<void>([
          if (device.supported) device.clearAccount(user.uid),
          if (local.supported)
            ref.read(mealDraftStoreProvider).clearForAccountDeletion(user.uid),
        ]);
      } catch (_) {
        throw const AccountActionFailure(
          'Yêu cầu xóa đã khóa ghi dữ liệu, nhưng chưa dừng hoặc dọn xong dữ liệu trên máy. Hãy thử lại để tiếp tục.',
          dataMayBeDeleted: true,
        );
      }
      if (!current()) return false;
      try {
        await data.deleteAllUserData(user.uid);
      } on AccountDataFailure {
        throw const AccountActionFailure(
          'Chưa thể xóa hết dữ liệu. Tài khoản đã khóa ghi mới; một phần dữ liệu có thể đã xóa. Giữ kết nối và thử lại để tiếp tục.',
          dataMayBeDeleted: true,
        );
      }
      if (!current()) return false;
      try {
        await data.markLocalDataDeleted(user.uid);
        // Repository also checks the SDK's current UID, even before the auth
        // stream has delivered a changed session to Riverpod.
        if (!current()) return false;
        await repository.deleteCurrentUser(expectedUid: user.uid);
      } on AccountDataFailure {
        throw const AccountActionFailure(
          'Chưa xác minh xong phần dữ liệu cần dọn. Tài khoản đăng nhập vẫn được giữ để thử lại.',
          dataMayBeDeleted: true,
        );
      } on AuthFailure {
        throw const AccountActionFailure(
          'Dữ liệu ứng dụng đã dọn nhưng tài khoản đăng nhập chưa thể xóa. Yêu cầu xóa vẫn được giữ; hãy thử lại để hoàn tất.',
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
      final user = ref.read(authSessionProvider).value;
      if (user?.uid != uid) throw AuthFailure.fromCode('user-mismatch');
      if (user!.hasPassword) {
        await repository.reauthenticateWithPassword(password, expectedUid: uid);
      } else if (user.providerIds.contains('google.com')) {
        await repository.reauthenticateWithGoogle(expectedUid: uid);
      } else {
        throw const AccountActionFailure(
          'Cách đăng nhập này chưa hỗ trợ xác thực lại.',
        );
      }
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
