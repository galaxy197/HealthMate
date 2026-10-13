abstract interface class ThemePreferenceStore {
  Future<String?> readThemeMode();
  Future<void> writeThemeMode(String value);
}
