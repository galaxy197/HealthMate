class DailyLogFailure implements Exception {
  const DailyLogFailure(this.message);

  factory DailyLogFailure.fromCode(String code) =>
      DailyLogFailure(switch (code) {
        'permission-denied' => 'Bạn không có quyền truy cập nhật ký này.',
        'unavailable' => 'Dịch vụ đang gián đoạn. Vui lòng thử lại.',
        'failed-precondition' =>
          'Dữ liệu đang được thiết lập. Vui lòng thử lại sau.',
        _ => 'Chưa thể cập nhật nhật ký. Vui lòng thử lại.',
      });

  final String message;

  @override
  String toString() => message;
}
