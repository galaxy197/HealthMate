import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

void main() {
  group('daily log calculations and validation', () {
    test('creates a stable local date key', () {
      expect(localDateKey(DateTime(2026, 2, 3, 23, 30)), '2026-02-03');
    });

    test('validates water amount and activity duration', () {
      expect(WaterValidation.amount('49'), isNotNull);
      expect(WaterValidation.amount('250'), isNull);
      expect(WaterValidation.amount('5001'), isNotNull);
      expect(ActivityValidation.duration('0'), isNotNull);
      expect(ActivityValidation.duration('30'), isNull);
      expect(ActivityValidation.duration('1441'), isNotNull);
      final now = DateTime(2026, 10, 13, 10);
      expect(
        WaterValidation.consumedAt(now.add(const Duration(hours: 1)), now: now),
        isNotNull,
      );
      expect(ActivityValidation.performedAt(now, now: now), isNull);
    });

    test('totals reflect the current log list', () {
      final now = DateTime(2026, 10, 13, 8);
      expect(
        totalWaterMl([
          WaterLog(
            id: '1',
            amountMl: 250,
            consumedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
          ),
          WaterLog(
            id: '2',
            amountMl: 350,
            consumedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
          ),
        ]),
        600,
      );
      expect(
        totalActivityMinutes([
          ActivityLog(
            id: '1',
            type: ActivityType.walking,
            durationMinutes: 20,
            performedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
            note: '',
          ),
          ActivityLog(
            id: '2',
            type: ActivityType.yoga,
            durationMinutes: 15,
            performedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
            note: '',
          ),
        ]),
        35,
      );
    });
  });

  testWidgets('adds water and activity entries for the selected day', (
    tester,
  ) async {
    final water = FakeWaterRepository();
    final activity = FakeActivityRepository();
    final container = await pumpApp(
      tester,
      waterRepository: water,
      activityRepository: activity,
    );
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();

    final addWater = find.byKey(const ValueKey('add-water'));
    tester.widget<FilledButton>(addWater).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('water-amount')), '300');
    await tester.tap(find.byKey(const ValueKey('save-water')));
    await tester.pumpAndSettle();
    expect(water.addCalls, 1);
    expect(find.textContaining('300 ml'), findsWidgets);

    Finder waterMenu() => find.descendant(
      of: find.byKey(const ValueKey('water-log-water-1')),
      matching: find.byType(PopupMenuButton<String>),
    );
    tester.widget<PopupMenuButton<String>>(waterMenu()).onSelected!('edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('water-amount')), '450');
    await tester.tap(find.byKey(const ValueKey('save-water')));
    await tester.pumpAndSettle();
    expect(water.updateCalls, 1);
    expect(find.textContaining('450 ml'), findsWidgets);

    tester.widget<PopupMenuButton<String>>(waterMenu()).onSelected!('delete');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(water.deleteCalls, 1);
    expect(
      find.text('Chưa có lần uống nước nào trong ngày này.'),
      findsOneWidget,
    );

    final addActivity = find.byKey(const ValueKey('add-activity'));
    tester.widget<FilledButton>(addActivity).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('activity-duration')),
      '45',
    );
    await tester.tap(find.byKey(const ValueKey('save-activity')));
    await tester.pumpAndSettle();
    expect(activity.addCalls, 1);
    expect(find.textContaining('45 phút'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
