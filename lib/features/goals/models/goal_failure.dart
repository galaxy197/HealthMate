class GoalFailure implements Exception {
  const GoalFailure([
    this.message =
        'Chưa thể tải hoặc lưu mục tiêu/nhiệm vụ. Kiểm tra mạng rồi thử lại.',
  ]);
  final String message;
  @override
  String toString() => message;
}
