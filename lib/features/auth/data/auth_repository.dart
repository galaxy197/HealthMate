import '../models/auth_user.dart';

abstract interface class AuthRepository {
  /// Immediate SDK session check at privacy-sensitive async boundaries.
  String? get currentUid;
  Stream<AuthUser?> authStateChanges();
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> sendEmailVerification({required String expectedUid});
  Future<void> reloadUser({required String expectedUid});
  Future<void> reauthenticateWithGoogle({required String expectedUid});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> reauthenticateWithPassword(
    String password, {
    String? expectedUid,
  });
  Future<void> updatePassword(String newPassword, {String? expectedUid});
  Future<void> deleteCurrentUser({String? expectedUid});
  Future<void> signOut();
}
