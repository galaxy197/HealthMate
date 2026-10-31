import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'google_identity_service.dart';

import '../models/auth_failure.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {GoogleIdentityService? google})
    : _google = google ?? DeviceGoogleIdentityService();

  final FirebaseAuth _auth;
  final GoogleIdentityService _google;
  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<AuthUser?> authStateChanges() => _auth
      .userChanges()
      .asyncMap((user) async {
        if (user == null) return null;
        // Do not open Firestore until the token also contains the verified claim.
        final token = await user.getIdTokenResult();
        if (_auth.currentUser?.uid != user.uid) return null;
        return AuthUser(
          uid: user.uid,
          email: user.email,
          emailVerified:
              user.emailVerified && token.claims?['email_verified'] == true,
          providerIds: user.providerData
              .map((p) => p.providerId)
              .toList(growable: false),
        );
      })
      .distinct(
        (a, b) =>
            a?.uid == b?.uid &&
            a?.email == b?.email &&
            a?.emailVerified == b?.emailVerified &&
            listEquals(a?.providerIds, b?.providerIds),
      );

  @override
  Future<void> signInWithGoogle() => _run(() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
    } else {
      final token = await _google.authenticate();
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    }
  });

  @override
  Future<void> reauthenticateWithGoogle({required String expectedUid}) =>
      _run(() async {
        final user = _requireCurrentUser(expectedUid);
        if (kIsWeb) {
          await user.reauthenticateWithPopup(
            GoogleAuthProvider()
              ..setCustomParameters({'prompt': 'select_account'}),
          );
        } else {
          final token = await _google.authenticate();
          _requireCurrentUser(expectedUid);
          await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(idToken: token),
          );
        }
        _requireCurrentUser(expectedUid);
        await user.getIdToken(true);
      });

  @override
  Future<void> sendEmailVerification({required String expectedUid}) =>
      _run(() async {
        await _auth.setLanguageCode('vi');
        await _requireCurrentUser(expectedUid).sendEmailVerification();
      });

  @override
  Future<void> reloadUser({required String expectedUid}) => _run(() async {
    await _requireCurrentUser(expectedUid).reload();
    await _requireCurrentUser(expectedUid).getIdToken(true);
  });

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
  Future<void> sendPasswordResetEmail(String email) => _run(() async {
    await _auth.setLanguageCode('vi');
    await _auth.sendPasswordResetEmail(email: email.trim());
  });

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
    _requireCurrentUser(expectedUid);
    await user.getIdToken(true);
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
  Future<void> signOut() => _run(() async {
    await _auth.signOut();
    // A provider cleanup failure must not undo a successful Firebase sign-out.
    if (!kIsWeb) {
      try {
        await _google.signOut();
      } catch (_) {
        /* Firebase session is already closed. */
      }
    }
  });

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
