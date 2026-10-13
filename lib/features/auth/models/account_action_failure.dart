class AccountActionFailure implements Exception {
  const AccountActionFailure(this.message, {this.dataMayBeDeleted = false});

  final String message;
  final bool dataMayBeDeleted;

  @override
  String toString() => message;
}
