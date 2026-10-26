/// Only the identity needed by the app shell; never includes credentials.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.providerIds = const ['password'],
  });

  final String uid;
  final String? email;
  final bool emailVerified;
  final List<String> providerIds;
  bool get hasPassword => providerIds.contains('password');
}
