import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_failure.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : AuthUser(uid: user.uid, email: user.email),
  );

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> register({required String email, required String password}) =>
      _run(() async {
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> reauthenticateWithPassword(
    String password, {
    String? expectedUid,
  }) => _run(() async {
    final user = _requireCurrentUser(expectedUid);
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthFailure(
        'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.',
        code: 'no-current-user',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  });

  @override
  Future<void> updatePassword(String newPassword, {String? expectedUid}) =>
      _run(
        () async =>
            _requireCurrentUser(expectedUid).updatePassword(newPassword),
      );

  @override
  Future<void> deleteCurrentUser({String? expectedUid}) =>
      _run(() async => _requireCurrentUser(expectedUid).delete());

  @override
  Future<void> signOut() => _run(_auth.signOut);

  User _requireCurrentUser([String? expectedUid]) {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(
        'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.',
        code: 'no-current-user',
      );
    }
    if (expectedUid != null && user.uid != expectedUid) {
      throw const AuthFailure(
        'Phiên đăng nhập đã thay đổi. Hãy thực hiện lại từ tài khoản hiện tại.',
        code: 'user-mismatch',
      );
    }
    return user;
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromCode(error.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure.fromCode('unknown');
    }
  }
}
