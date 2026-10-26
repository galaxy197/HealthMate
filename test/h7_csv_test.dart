import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/data_export/models/journal_csv.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';

void main() {
  final start = DateTime(2026, 12, 31), end = DateTime(2027, 1, 2);
  test(
    'activity and weight retain units, notes and honest timezone provenance',
    () {
      final at = DateTime(2026, 12, 31, 12);
      final csv = buildJournalCsv(
        start: start,
        endExclusive: end,
        activities: [
          ActivityLog(
            id: 'a',
            type: ActivityType.walking,
            durationMinutes: 30,
            performedAt: at,
            dateKey: '2026-12-31',
            timezoneOffsetMinutes: at.timeZoneOffset.inMinutes,
            note: '=QA note',
          ),
        ],
        weights: [
          BodyMetric(
            id: 'b',
            weightKg: 70.5,
            measuredAt: at,
            note: 'Cân, buổi sáng',
            createdAt: at,
            updatedAt: at,
          ),
        ],
      );
      expect(csv, contains('"activity_logs_contract_v1"'));
      expect(csv, contains('"30"'));
      expect(csv, contains('"\'=QA note"'));
      expect(csv, contains('"body_metrics_contract_v1"'));
      expect(csv, contains('"device_at_export"'));
      expect(csv, contains('"70.5","Cân, buổi sáng"'));
    },
  );
  test(
    'CSV quotes Vietnamese, delimiters and multiline text; neutralizes formulas',
    () {
      expect(csvCell('Phở, "bò"\r\nít hành'), '"Phở, ""bò""\r\nít hành"');
      for (final prefix in [
        '',
        ' ',
        '\t',
        '\r\n',
        '\uFEFF',
        '\u200B',
        '\u202E',
      ]) {
        for (final formula in ['=SUM(1,2)', '+cmd', '-1+1', '@SUM(A1)']) {
          expect(csvCell('$prefix$formula'), startsWith('"\''));
        }
      }
      expect(csvCell(-420), '"-420"');
      expect(csvCell(null), '""');
      expect(() => csvCell(double.nan), throwsFormatException);
    },
  );
  MealLog meal({String id = 'm'}) => MealLog(
    id: id,
    schemaVersion: 4,
    type: MealType.snack,
    consumedAt: DateTime.utc(2026, 12, 30, 17),
    dateKey: '2026-12-31',
    timezoneOffsetMinutes: 420,
    source: MealSource.manual,
    totals: const NutritionTotals(kcal: 150),
    items: const [
      MealItemSnapshot(
        foodId: 'q',
        name: '=QA, món Việt',
        grams: 0,
        quantityUnit: 'ml',
        quantityValue: 250,
        nutrition: NutritionTotals(
          kcal: 150,
          proteinKnown: false,
          carbsG: 0,
          fatKnown: false,
          fiberG: 1.2,
          fiberKnown: false,
        ),
        sourceLabel: 'Người dùng nhập',
        isEstimated: true,
      ),
    ],
  );
  test(
    'selected stored day wins across UTC midnight; missing stays blank and partial stays labeled',
    () {
      final csv = buildJournalCsv(
        start: start,
        endExclusive: end,
        meals: [meal()],
        water: [
          WaterLog(
            id: 'w',
            amountMl: 200,
            consumedAt: DateTime.utc(2026, 12, 30, 17),
            dateKey: '2026-12-31',
            timezoneOffsetMinutes: 420,
          ),
          WaterLog(
            id: 'outside',
            amountMl: 500,
            consumedAt: DateTime.utc(2027, 1, 2),
            dateKey: '2027-01-02',
            timezoneOffsetMinutes: 0,
          ),
        ],
      );
      expect(csv, startsWith('\uFEFF"export_schema"'));
      expect(csv, contains('"2026-12-30T17:00:00.000Z","420","stored"'));
      expect(
        csv,
        contains(
          '"\'=QA, món Việt","250.0","ml","150.0","","unknown","0.0","known"',
        ),
      );
      expect(csv, contains('"1.2","partial"'));
      expect(csv, contains('"water"'));
      expect(csv, isNot(contains('outside')));
      expect(csv, isNot(contains('meal_total')));
      expect(csv.split('\r\n').length, 4); // Header + 2 records + terminator.
    },
  );
  test(
    'empty range has no invented data; limits are calendar based across New Year',
    () {
      final empty = buildJournalCsv(start: start, endExclusive: end);
      expect(empty.split('\r\n').length, 2);
      expect(
        () => buildJournalCsv(start: end, endExclusive: start),
        throwsFormatException,
      );
      expect(
        () => buildJournalCsv(start: start, endExclusive: start),
        throwsFormatException,
      );
      expect(
        () => buildJournalCsv(
          start: DateTime(2026, 1, 1),
          endExclusive: DateTime(2027, 1, 3), // 367 days exceeds annual export.
        ),
        throwsFormatException,
      );
      expect(
        () => buildJournalCsv(
          start: start,
          endExclusive: end,
          meals: [meal(), meal()],
        ),
        throwsFormatException,
      );
    },
  );
}
