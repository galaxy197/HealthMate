import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> reauthenticateWithPassword(String password);
  Future<void> updatePassword(String newPassword);
  Future<void> deleteCurrentUser();
  Future<void> signOut();
}
