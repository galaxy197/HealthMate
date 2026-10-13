/// Only the identity needed by the app shell; never includes credentials.
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String? email;
}
