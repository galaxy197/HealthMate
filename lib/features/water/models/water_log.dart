import '../../../core/utils/local_date_key.dart';

class WaterLogDraft {
  const WaterLogDraft({required this.amountMl, required this.consumedAt});

  final int amountMl;
  final DateTime consumedAt;

  String get dateKey => localDateKey(consumedAt);
  int get timezoneOffsetMinutes => consumedAt.timeZoneOffset.inMinutes;
}

class WaterLog {
  const WaterLog({
    required this.id,
    required this.amountMl,
    required this.consumedAt,
    required this.dateKey,
    required this.timezoneOffsetMinutes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int amountMl;
  final DateTime consumedAt;
  final String dateKey;
  final int timezoneOffsetMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WaterLogDraft toDraft() =>
      WaterLogDraft(amountMl: amountMl, consumedAt: consumedAt);
}

int totalWaterMl(Iterable<WaterLog> logs) =>
    logs.fold(0, (sum, log) => sum + log.amountMl);

abstract final class WaterValidation {
  static const minAmountMl = 50;
  static const maxAmountMl = 5000;

  static String? amount(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Nhập lượng nước bằng số nguyên.';
    if (parsed < minAmountMl || parsed > maxAmountMl) {
      return 'Mỗi lần ghi từ 50 đến 5.000 ml.';
    }
    return null;
  }

  static String? consumedAt(DateTime value, {DateTime? now}) {
    if (value.isAfter(
      (now ?? DateTime.now()).add(const Duration(minutes: 5)),
    )) {
      return 'Thời điểm uống không thể ở tương lai.';
    }
    return null;
  }
}
