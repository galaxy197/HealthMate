import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/auth/models/account_deletion_job.dart';

class FakeAccountDataRepository implements AccountDataRepository {
  FakeAccountDataRepository({this.events});

  final List<String>? events;
  int deleteCalls = 0;
  String? lastUid;
  AccountDataFailure? failure;
  AccountDataFailure? requestFailure, localFailure;
  int requestCalls = 0, localCalls = 0;
  AccountDeletionJob? job;

  @override
  Stream<AccountDeletionJob?> watchDeletion(String uid) => Stream.value(null);

  @override
  Future<AccountDeletionJob> requestDeletion(String uid) async {
    events?.add('request-deletion');
    requestCalls++;
    if (requestFailure != null) throw requestFailure!;
    return job ??= AccountDeletionJob(
      uid: uid,
      state: AccountDeletionState.requested,
      checkpoint: 0,
      requestedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> markLocalDataDeleted(String uid) async {
    events?.add('local-deleted');
    localCalls++;
    if (localFailure != null) throw localFailure!;
  }

  @override
  Future<void> deleteAllUserData(String uid) async {
    events?.add('delete-data');
    deleteCalls++;
    lastUid = uid;
    if (failure != null) throw failure!;
  }
}
