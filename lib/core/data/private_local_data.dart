import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android-only, encrypted app-private storage and user-directed document export.
/// Other platforms fail explicitly; health data never falls back to preferences.
class PrivateLocalData {
  static const channel = MethodChannel('healthmate/private_local_data');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String?> read(String uid) =>
      channel.invokeMethod<String>('readDrafts', {'uid': uid});
  Future<void> write(String uid, String json) =>
      channel.invokeMethod<void>('writeDrafts', {'uid': uid, 'json': json});
  Future<void> clear(String uid) =>
      channel.invokeMethod<void>('clearDrafts', {'uid': uid});
  Future<String?> chooseCsv(String filename) =>
      channel.invokeMethod<String>('chooseCsv', {'filename': filename});
  Future<int?> writeCsv(String ticket, Uint8List bytes) =>
      channel.invokeMethod<int>('writeCsv', {'ticket': ticket, 'bytes': bytes});
  Future<void> cancelCsv(String ticket) =>
      channel.invokeMethod<void>('cancelCsv', {'ticket': ticket});
}
