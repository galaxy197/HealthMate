import 'dart:typed_data';
import 'package:healthmate/core/data/private_local_data.dart';

class FakePrivateLocalData extends PrivateLocalData {
  FakePrivateLocalData({this.available = true});
  final bool available;
  final drafts = <String, String>{};
  bool failWrite = false;
  bool failClear = false;
  int picked = 0, cancelled = 0, written = 0;
  Future<String?> Function()? picker;
  Uint8List? csv;
  @override
  bool get supported => available;
  @override
  Future<String?> read(String uid) async => drafts[uid];
  @override
  Future<void> write(String uid, String json) async {
    if (failWrite) throw StateError('disk full');
    drafts[uid] = json;
  }

  @override
  Future<void> clear(String uid) async {
    if (failClear) throw StateError('keystore unavailable');
    drafts.remove(uid);
  }

  @override
  Future<String?> chooseCsv(String filename) async {
    picked++;
    return picker == null ? 'synthetic-ticket' : picker!();
  }

  @override
  Future<int?> writeCsv(String ticket, Uint8List bytes) async {
    written++;
    csv = bytes;
    return bytes.length;
  }

  @override
  Future<void> cancelCsv(String ticket) async {
    cancelled++;
  }
}
