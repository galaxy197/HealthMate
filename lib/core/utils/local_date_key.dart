String localDateKey(DateTime value) {
  final date = value.toLocal();
  return _formatDateKey(date.year, date.month, date.day);
}

class LocalDayRange {
  const LocalDayRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

LocalDayRange localDayRange(DateTime value) {
  final date = value.toLocal();
  return LocalDayRange(
    start: DateTime(date.year, date.month, date.day),
    end: DateTime(date.year, date.month, date.day + 1),
  );
}

String dateKeyFromTimestampAndOffset(
  DateTime timestamp,
  int timezoneOffsetMinutes,
) {
  if (timezoneOffsetMinutes < -720 || timezoneOffsetMinutes > 840) {
    throw ArgumentError.value(
      timezoneOffsetMinutes,
      'timezoneOffsetMinutes',
      'Độ lệch múi giờ phải nằm trong khoảng -720 đến +840 phút.',
    );
  }
  final localClock = timestamp.toUtc().add(
    Duration(minutes: timezoneOffsetMinutes),
  );
  return _formatDateKey(localClock.year, localClock.month, localClock.day);
}

bool isValidDateKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return false;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }

  final normalized = DateTime.utc(year, month, day);
  return normalized.year == year &&
      normalized.month == month &&
      normalized.day == day;
}

bool dateKeyMatchesTimestamp({
  required String dateKey,
  required DateTime timestamp,
  required int timezoneOffsetMinutes,
}) {
  if (!isValidDateKey(dateKey)) return false;
  if (timezoneOffsetMinutes < -720 || timezoneOffsetMinutes > 840) {
    return false;
  }
  return dateKey ==
      dateKeyFromTimestampAndOffset(timestamp, timezoneOffsetMinutes);
}

DateTime localDateOnly(DateTime value) {
  final date = value.toLocal();
  return DateTime(date.year, date.month, date.day);
}

String _formatDateKey(int year, int month, int day) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${year.toString().padLeft(4, '0')}-${twoDigits(month)}-${twoDigits(day)}';
}
