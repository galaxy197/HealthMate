import 'package:healthmate/shared/data/theme_preference_store.dart';

class FakeThemePreferenceStore implements ThemePreferenceStore {
  FakeThemePreferenceStore({this.savedMode});

  String? savedMode;
  Object? writeError;
  int writeCalls = 0;

  @override
  Future<String?> readThemeMode() async => savedMode;

  @override
  Future<void> writeThemeMode(String value) async {
    writeCalls++;
    if (writeError != null) throw writeError!;
    savedMode = value;
  }
}
