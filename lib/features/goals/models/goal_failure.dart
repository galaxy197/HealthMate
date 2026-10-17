import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import '../../nutrition/models/nutrition_failure.dart';
import '../../journal/models/daily_log_failure.dart';

class GoalFailure implements Exception {
  const GoalFailure([
    this.message =
        'Chưa thể tải hoặc lưu mục tiêu/nhiệm vụ. Kiểm tra mạng rồi thử lại.',
  ]) : stage = 'unknown',
       code = 'unknown';
  factory GoalFailure.at(Object error, String stage) {
    final code = switch (error) {
      FirebaseException e => e.code,
      GoalFailure e => e.code,
      NutritionFailure e => e.code,
      DailyLogFailure e => e.code,
      TimeoutException() => 'timeout',
      FormatException() || TypeError() || ArgumentError() => 'invalid-data',
      _ => 'unknown',
    };
    return GoalFailure.detail(stage, code);
  }
  GoalFailure.detail(this.stage, this.code)
    : message =
          '${_stageLabel(stage)}: ${switch (code) {
            'permission-denied' => 'chưa được cấp quyền. Cần kiểm tra Rules/App Check của project.',
            'unauthenticated' => 'phiên đăng nhập chưa hợp lệ. Hãy đăng nhập lại.',
            'failed-precondition' => 'thiếu điều kiện truy vấn hoặc index; cần kiểm tra cấu hình.',
            'unavailable' => 'dịch vụ chưa kết nối được. Hãy kiểm tra mạng và thử lại.',
            'timeout' || 'deadline-exceeded' => 'quá thời gian tải. Chưa tạo nhiệm vụ từ dữ liệu chưa xác nhận.',
            'invalid-data' => 'dữ liệu chưa đúng định dạng; cần kiểm tra schema.',
            _ => 'chưa thể hoàn tất. Hãy thử lại.',
          }}';
  final String message;
  final String stage;
  final String code;
  @override
  String toString() => message;
}

String _stageLabel(String stage) => switch (stage) {
  'quest-read' => 'Tải nhiệm vụ đã lưu',
  'quest-create' => 'Tạo nhiệm vụ',
  'goals-read' => 'Tải mục tiêu',
  'meals-read' => 'Tải bữa ăn',
  'water-read' => 'Tải nước uống',
  'activity-read' => 'Tải vận động',
  'goal-save' => 'Lưu mục tiêu',
  _ => 'Cập nhật mục tiêu/nhiệm vụ',
};
