import '../models/account_deletion_job.dart';

abstract interface class AccountDataRepository {
  Stream<AccountDeletionJob?> watchDeletion(String uid);
  Future<AccountDeletionJob> requestDeletion(String uid);
  Future<void> deleteAllUserData(String uid);
  Future<void> markLocalDataDeleted(String uid);
}

class AccountDataFailure implements Exception {
  const AccountDataFailure();
}
