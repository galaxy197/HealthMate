import 'dart:async';

import 'package:healthmate/features/auth/data/auth_repository.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';

/// Test-only implementation. Production always uses FirebaseAuthRepository.
class FakeAuthRepository implements AuthRepository {
  factory FakeAuthRepository({AuthUser? user}) => FakeAuthRepository._(user);

  FakeAuthRepository._(this._user);

  static const testUser = AuthUser(
    uid: 'test-uid',
    email: 'member@example.com',
  );
  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();
  bool emitInitial = true;
  AuthFailure? failure;
  Object? sessionError;
  Completer<void>? pending;
  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.multi((controller) {
    if (sessionError != null) {
      controller.addError(sessionError!);
    } else if (emitInitial) {
      controller.add(_user);
    }
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  void emitUser(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }

  Future<void> _operation() async {
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    await _operation();
    emitUser(testUser);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    lastEmail = email;
    lastPassword = password;
    await _operation();
    emitUser(AuthUser(uid: 'new-test-uid', email: email));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await _operation();
    emitUser(null);
  }

  Future<void> dispose() => _changes.close();
}
