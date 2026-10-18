import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> reauthenticateWithPassword(
    String password, {
    String? expectedUid,
  });
  Future<void> updatePassword(String newPassword, {String? expectedUid});
  Future<void> deleteCurrentUser({String? expectedUid});
  Future<void> signOut();
}
