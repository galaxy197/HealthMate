class NutritionFailure implements Exception {
  const NutritionFailure(this.message);

  final String message;

  factory NutritionFailure.fromCode(String code) =>
      NutritionFailure(switch (code) {
        'permission-denied' => 'Bạn không có quyền truy cập dữ liệu này.',
        'unavailable' => 'Dịch vụ đang tạm gián đoạn. Vui lòng thử lại.',
        'network-request-failed' => 'Không có kết nối mạng.',
        _ => 'Chưa thể xử lý nhật ký. Vui lòng thử lại.',
      });

  @override
  String toString() => message;
}
