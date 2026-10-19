import 'dart:async';

import 'package:healthmate/features/auth/data/auth_repository.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';

/// Test-only implementation. Production always uses FirebaseAuthRepository.
class FakeAuthRepository implements AuthRepository {
  factory FakeAuthRepository({AuthUser? user, List<String>? events}) =>
      FakeAuthRepository._(user, events);

  FakeAuthRepository._(this._user, this.events);

  static const testUser = AuthUser(
    uid: 'test-uid',
    email: 'member@example.com',
  );
  AuthUser? _user;
  @override
  String? get currentUid => _user?.uid;
  final List<String>? events;
  final _changes = StreamController<AuthUser?>.broadcast();
  bool emitInitial = true;
  AuthFailure? failure;
  AuthFailure? resetFailure;
  AuthFailure? reauthenticateFailure;
  AuthFailure? updatePasswordFailure;
  AuthFailure? deleteUserFailure;
  Object? sessionError;
  Completer<void>? pending;
  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;
  int resetPasswordCalls = 0;
  int reauthenticateCalls = 0;
  int updatePasswordCalls = 0;
  int deleteUserCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastNewPassword;

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
  Future<void> sendPasswordResetEmail(String email) async {
    resetPasswordCalls++;
    lastEmail = email;
    await _operation();
    if (resetFailure != null) throw resetFailure!;
  }

  @override
  Future<void> reauthenticateWithPassword(
    String password, {
    String? expectedUid,
  }) async {
    events?.add('reauthenticate');
    reauthenticateCalls++;
    lastPassword = password;
    await _operation();
    if (reauthenticateFailure != null) throw reauthenticateFailure!;
  }

  @override
  Future<void> updatePassword(String newPassword, {String? expectedUid}) async {
    events?.add('update-password');
    updatePasswordCalls++;
    lastNewPassword = newPassword;
    await _operation();
    if (updatePasswordFailure != null) throw updatePasswordFailure!;
  }

  @override
  Future<void> deleteCurrentUser({String? expectedUid}) async {
    events?.add('delete-auth');
    deleteUserCalls++;
    await _operation();
    if (deleteUserFailure != null) throw deleteUserFailure!;
    emitUser(null);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await _operation();
    emitUser(null);
  }

  Future<void> dispose() => _changes.close();
}
