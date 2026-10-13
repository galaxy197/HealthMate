String localDateKey(DateTime value) {
  final date = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}

DateTime localDateOnly(DateTime value) {
  final date = value.toLocal();
  return DateTime(date.year, date.month, date.day);
}
