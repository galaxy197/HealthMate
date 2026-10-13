import 'package:healthmate/features/auth/data/account_data_repository.dart';

class FakeAccountDataRepository implements AccountDataRepository {
  FakeAccountDataRepository({this.events});

  final List<String>? events;
  int deleteCalls = 0;
  String? lastUid;
  AccountDataFailure? failure;

  @override
  Future<void> deleteAllUserData(String uid) async {
    events?.add('delete-data');
    deleteCalls++;
    lastUid = uid;
    if (failure != null) throw failure!;
  }
}
