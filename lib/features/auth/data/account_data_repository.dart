abstract interface class AccountDataRepository {
  Future<void> deleteAllUserData(String uid);
}

class AccountDataFailure implements Exception {
  const AccountDataFailure();
}
