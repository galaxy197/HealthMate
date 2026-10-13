import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Generated options belong to the real HealthMate Firebase project.
/// Firebase must initialize before any auth providers or app routes are built.
Future<void> initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // The web build remains a UI preview. AI image scanning is Android-only until
  // a production reCAPTCHA Enterprise site key is provisioned for this domain.
  if (!kIsWeb) {
    const debugToken = String.fromEnvironment(
      'HEALTHMATE_APP_CHECK_DEBUG_TOKEN',
    );
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: debugToken.isEmpty ? null : debugToken,
            )
          : const AndroidPlayIntegrityProvider(),
    );
  }
}
