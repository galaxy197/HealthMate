import '../../../core/data/bounded_range.dart';
import '../models/period_report.dart';

/// All-or-error per source: a failed chunk never becomes a partial total.
/// Closing a report/account switch stops later chunks.
Future<List<T>> loadReportRange<T>(
  ReportRange range,
  Future<List<T>> Function(ReportRange) load, {
  required Object Function(T) keyOf,
  bool Function()? isCurrent,
  int maxRecords = 10000,
}) async {
  final chunks = range.chunks;
  final byKey = <Object, T>{};
  for (final chunk in chunks) {
    if (isCurrent?.call() == false) throw StateError('Phiên tải đã thay đổi.');
    final rows = await load(chunk).timeout(const Duration(seconds: 20));
    if (isCurrent?.call() == false) throw StateError('Phiên tải đã thay đổi.');
    for (final row in rows) {
      byKey[keyOf(row)] = row;
    }
    if (byKey.length > maxRecords) {
      throw const RangeReadFailure(
        'Khoảng này có quá nhiều bản ghi; hãy chọn khoảng ngắn hơn. Chưa tính tổng từ dữ liệu thiếu.',
      );
    }
  }
  return byKey.values.toList();
}
