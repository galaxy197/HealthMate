import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../models/auth_failure.dart';
import '../models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final authSessionProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (retryCount, error) => null,
);

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

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
