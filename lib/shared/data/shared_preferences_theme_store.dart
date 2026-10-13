import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preference_store.dart';

class SharedPreferencesThemeStore implements ThemePreferenceStore {
  SharedPreferencesThemeStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'healthmate.theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readThemeMode() => _preferences.getString(_key);

  @override
  Future<void> writeThemeMode(String value) =>
      _preferences.setString(_key, value);
}
