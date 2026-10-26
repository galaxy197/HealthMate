import 'dart:convert';

import '../../../core/utils/local_date_key.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../profile/models/body_metric.dart';
import '../../water/models/water_log.dart';
import '../../reports/models/period_report.dart';

/// RFC 4180 cell encoding. Only generated finite numbers bypass text escaping.
/// The apostrophe neutralizes spreadsheet formulas without removing user text.
String csvCell(Object? value) {
  String text;
  if (value == null) {
    text = '';
  } else if (value is num) {
    if (!value.isFinite) throw const FormatException('Số liệu không hữu hạn.');
    text = value.toString();
  } else if (value is String || value is bool) {
    text = value.toString();
    if (RegExp(
      r'^[\s\u0000-\u0020\u007f-\u009f\uFEFF\u200B-\u200F\u202A-\u202E\u2060-\u206F]*[=+\-@]',
    ).hasMatch(text)) {
      text = "'$text";
    }
  } else {
    throw const FormatException('Kiểu ô CSV không được hỗ trợ.');
  }
  return '"${text.replaceAll('"', '""')}"';
}

const journalCsvColumns = [
  'export_schema',
  'range_start',
  'range_end_exclusive',
  'record_kind',
  'record_id',
  'record_schema',
  'date_key',
  'recorded_at_utc',
  'timezone_offset_minutes',
  'timezone_basis',
  'meal_type',
  'item_index',
  'name',
  'quantity',
  'quantity_unit',
  'kcal',
  'protein_g',
  'protein_status',
  'carbs_g',
  'carbs_status',
  'fat_g',
  'fat_status',
  'fiber_g',
  'fiber_status',
  'water_ml',
  'activity_minutes',
  'weight_kg',
  'note',
  'source_label',
  'is_estimated',
];

/// Pure encoder for ALREADY owner-scoped repository results. This is not an
/// authorization boundary or a file writer. An eventual export controller must
/// capture/recheck the UID before loading and before writing a user-chosen file.
/// One row per meal item avoids counting both items and meal totals twice.
String buildJournalCsv({
  required DateTime start,
  required DateTime endExclusive,
  List<MealLog> meals = const [],
  List<WaterLog> water = const [],
  List<ActivityLog> activities = const [],
  List<BodyMetric> weights = const [],
}) {
  final first = localDateKey(start), last = localDateKey(endExclusive);
  final days = DateTime.utc(
    endExclusive.year,
    endExclusive.month,
    endExclusive.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (days < 1 || days > maxReportDays || !start.isBefore(endExclusive)) {
    throw const FormatException('Chọn khoảng xuất từ 1 đến 366 ngày.');
  }
  final rows = <Map<String, Object?>>[];
  final ids = <String>{};
  bool selected(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      throw const FormatException('Ngày của bản ghi không hợp lệ.');
    }
    final date = DateTime.tryParse(key);
    if (date == null || localDateKey(date) != key) {
      throw const FormatException('Ngày của bản ghi không tồn tại.');
    }
    return key.compareTo(first) >= 0 && key.compareTo(last) < 0;
  }

  void identity(String kind, String id) {
    if (id.isEmpty || !ids.add('$kind/$id')) {
      throw const FormatException(
        'Bản ghi thiếu mã hoặc bị trùng trong nguồn xuất.',
      );
    }
  }

  Map<String, Object?> base(
    String kind,
    String id,
    Object schema,
    String key,
    DateTime at,
    int offset,
    String basis,
  ) {
    if (offset < -720 || offset > 840) {
      throw const FormatException('Múi giờ của bản ghi không hợp lệ.');
    }
    return {
      'export_schema': 'healthmate_journal_csv_v1',
      'range_start': first,
      'range_end_exclusive': last,
      'record_kind': kind,
      'record_id': id,
      'record_schema': schema,
      'date_key': key,
      'recorded_at_utc': at.toUtc().toIso8601String(),
      'timezone_offset_minutes': offset,
      'timezone_basis': basis,
    };
  }

  void nutrient(
    Map<String, Object?> row,
    String name,
    double value,
    bool known,
  ) {
    if (!value.isFinite || value < 0) {
      throw const FormatException('Giá trị chất dinh dưỡng không hợp lệ.');
    }
    row['${name}_g'] = known || value > 0 ? value : null;
    row['${name}_status'] = known
        ? 'known'
        : value > 0
        ? 'partial'
        : 'unknown';
  }

  for (final meal in meals) {
    final offset =
        meal.timezoneOffsetMinutes ??
        meal.consumedAt.toLocal().timeZoneOffset.inMinutes;
    final key =
        meal.dateKey ?? dateKeyFromTimestampAndOffset(meal.consumedAt, offset);
    if (!selected(key)) continue;
    identity('meal_item', meal.id);
    if (meal.items.isEmpty) {
      throw const FormatException('Bữa ăn thiếu snapshot.');
    }
    for (final (index, item) in meal.items.indexed) {
      item.withQuantity(item.quantity); // Reject damaged historical snapshots.
      final n = item.nutrition;
      final row = base(
        'meal_item',
        meal.id,
        meal.schemaVersion,
        key,
        meal.consumedAt,
        offset,
        meal.timezoneOffsetMinutes == null
            ? 'device_at_export_legacy'
            : 'stored',
      );
      row.addAll({
        'meal_type': meal.type.name,
        'item_index': index + 1,
        'name': item.name,
        'quantity': item.quantity,
        'quantity_unit': item.quantityUnit,
        'kcal': n.kcal,
        'source_label': item.sourceLabel,
        'is_estimated': item.isEstimated,
      });
      nutrient(row, 'protein', n.proteinG, n.proteinKnown);
      nutrient(row, 'carbs', n.carbsG, n.carbsKnown);
      nutrient(row, 'fat', n.fatG, n.fatKnown);
      nutrient(row, 'fiber', n.fiberG, n.fiberKnown);
      rows.add(row);
    }
  }
  for (final log in water) {
    if (!selected(log.dateKey)) continue;
    if (log.amountMl < WaterValidation.minAmountMl ||
        log.amountMl > WaterValidation.maxAmountMl) {
      throw const FormatException('Lượng nước của bản ghi không hợp lệ.');
    }
    identity('water', log.id);
    rows.add(
      base(
        'water',
        log.id,
        'water_logs_contract_v1',
        log.dateKey,
        log.consumedAt,
        log.timezoneOffsetMinutes,
        'stored',
      )..['water_ml'] = log.amountMl,
    );
  }
  for (final log in activities) {
    if (!selected(log.dateKey)) continue;
    if (log.durationMinutes < 1 || log.durationMinutes > 1440) {
      throw const FormatException('Thời lượng của bản ghi không hợp lệ.');
    }
    identity('activity', log.id);
    rows.add(
      base(
        'activity',
        log.id,
        'activity_logs_contract_v1',
        log.dateKey,
        log.performedAt,
        log.timezoneOffsetMinutes,
        'stored',
      )..addAll({
        'name': log.type.label,
        'activity_minutes': log.durationMinutes,
        'note': log.note,
      }),
    );
  }
  for (final log in weights) {
    final at = log.measuredAt.toLocal(),
        key = localDateKey(log.measuredAt.toLocal());
    if (!selected(key)) continue;
    if (!log.weightKg.isFinite || log.weightKg < 20 || log.weightKg > 500) {
      throw const FormatException('Cân nặng của bản ghi không hợp lệ.');
    }
    identity('weight', log.id);
    rows.add(
      base(
        'weight',
        log.id,
        'body_metrics_contract_v1',
        key,
        at,
        at.timeZoneOffset.inMinutes,
        'device_at_export',
      )..addAll({'weight_kg': log.weightKg, 'note': log.note}),
    );
  }
  rows.sort((a, b) {
    for (final key in ['recorded_at_utc', 'record_kind', 'record_id']) {
      final comparison = (a[key] as String).compareTo(b[key] as String);
      if (comparison != 0) return comparison;
    }
    return ((a['item_index'] as int?) ?? 0).compareTo(
      (b['item_index'] as int?) ?? 0,
    );
  });
  final output =
      '\uFEFF${[journalCsvColumns.map(csvCell).join(','), for (final row in rows) journalCsvColumns.map((key) => csvCell(row[key])).join(',')].join('\r\n')}\r\n';
  if (utf8.encode(output).length > 5 * 1024 * 1024) {
    throw const FormatException('File vượt 5 MB; hãy chọn khoảng ngắn hơn.');
  }
  return output;
}
