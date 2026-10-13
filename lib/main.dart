import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/widgets/startup_error_app.dart';
import 'shared/data/shared_preferences_theme_store.dart';
import 'shared/providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final themeStore = SharedPreferencesThemeStore();
    final results = await Future.wait([
      initializeFirebase(),
      loadThemeMode(themeStore),
    ]);
    final initialTheme = results[1] as ThemeMode;
    runApp(
      ProviderScope(
        overrides: [
          themePreferenceStoreProvider.overrideWithValue(themeStore),
          initialThemeModeProvider.overrideWithValue(initialTheme),
        ],
        child: const HealthMateApp(),
      ),
    );
  } catch (_) {
    runApp(StartupErrorApp(onRetry: main));
  }
}
