enum AccountDeletionState { requested, cleaning, authPending }

/// Client progress is a resumable checkpoint, never proof of server completion.
class AccountDeletionJob {
  const AccountDeletionJob({
    required this.uid,
    required this.state,
    required this.checkpoint,
    required this.requestedAt,
    required this.updatedAt,
  });

  final String uid;
  final AccountDeletionState state;
  final int checkpoint;
  final DateTime requestedAt, updatedAt;

  static AccountDeletionState parseState(String value) => switch (value) {
    'requested' => AccountDeletionState.requested,
    'cleaning' => AccountDeletionState.cleaning,
    'auth_pending' => AccountDeletionState.authPending,
    _ => throw const FormatException('Trạng thái yêu cầu xóa chưa hợp lệ.'),
  };
}
