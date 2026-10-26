import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_failure.dart';

abstract interface class GoogleIdentityService {
  Future<String> authenticate();
  Future<void> signOut();
}

/// Requests identity only; no Drive, Contacts or other Google API scopes.
class DeviceGoogleIdentityService implements GoogleIdentityService {
  static Future<void>? _initialization;
  Future<void> _initialize() =>
      _initialization ??= GoogleSignIn.instance.initialize(
        serverClientId:
            const String.fromEnvironment(
              'HEALTHMATE_GOOGLE_SERVER_CLIENT_ID',
            ).isEmpty
            ? null
            : const String.fromEnvironment(
                'HEALTHMATE_GOOGLE_SERVER_CLIENT_ID',
              ),
      );
  @override
  Future<String> authenticate() async {
    try {
      await _initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw AuthFailure.fromCode('google-configuration');
      }
      return token;
    } on GoogleSignInException catch (e) {
      throw AuthFailure.fromCode(switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'sign-in-cancelled',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'google-configuration',
        GoogleSignInExceptionCode.interrupted => 'sign-in-interrupted',
        _ => 'google-sign-in-failed',
      });
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization != null) {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}
