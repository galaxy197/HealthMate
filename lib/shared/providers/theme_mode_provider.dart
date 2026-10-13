import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_theme_store.dart';
import '../data/theme_preference_store.dart';

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPreferencesThemeStore(),
);

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    final previous = state;
    state = mode;
    try {
      await ref.read(themePreferenceStoreProvider).writeThemeMode(mode.name);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}

Future<ThemeMode> loadThemeMode(ThemePreferenceStore store) async {
  try {
    final saved = await store.readThemeMode();
    return ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.system;
  } catch (_) {
    return ThemeMode.system;
  }
}
