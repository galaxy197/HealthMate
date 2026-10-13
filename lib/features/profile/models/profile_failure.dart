class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  factory ProfileFailure.fromCode(String code) {
    return switch (code) {
      'permission-denied' => const ProfileFailure(
        'Bạn không có quyền thực hiện thao tác này.',
      ),
      'unavailable' || 'network-request-failed' => const ProfileFailure(
        'Không thể kết nối. Hãy kiểm tra mạng rồi thử lại.',
      ),
      'deadline-exceeded' => const ProfileFailure(
        'Yêu cầu mất quá nhiều thời gian. Hãy thử lại.',
      ),
      'not-found' => const ProfileFailure(
        'Không tìm thấy dữ liệu cần cập nhật.',
      ),
      _ => const ProfileFailure(
        'Chưa thể cập nhật dữ liệu. Vui lòng thử lại sau.',
      ),
    };
  }

  @override
  String toString() => message;
}
