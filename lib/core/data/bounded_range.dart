import 'package:cloud_firestore/cloud_firestore.dart';

class RangeReadFailure implements Exception {
  const RangeReadFailure(this.message);
  final String message;
}

int calendarRangeDays(DateTime start, DateTime end) {
  final days = DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (days < 1 || days > 90 || !start.isBefore(end)) {
    throw const RangeReadFailure('Chỉ tải khoảng từ 1 đến 90 ngày.');
  }
  return days;
}

/// A bounded server read. Never report a silently truncated total.
Future<QuerySnapshot<Map<String, dynamic>>> readBoundedRange(
  Query<Map<String, dynamic>> query,
  DateTime start,
  DateTime end,
) async {
  calendarRangeDays(start, end);
  final result = await query
      .limit(2001)
      .get(const GetOptions(source: Source.server));
  if (result.docs.length > 2000) {
    throw const RangeReadFailure(
      'Khoảng này có hơn 2.000 bản ghi ở một nguồn; hãy chọn khoảng ngắn hơn.',
    );
  }
  return result;
}
