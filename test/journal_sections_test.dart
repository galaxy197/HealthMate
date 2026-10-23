import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/presentation/activity_log_section.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';
import 'package:healthmate/features/journal/presentation/journal_date_selector.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_log_section.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/presentation/water_log_section.dart';

import 'support/fake_nutrition_repository.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

MealLog _meal() => MealLog(
  id: 'meal-1',
  type: MealType.lunch,
  consumedAt: DateTime(2026, 10, 13, 12),
  items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100)],
  totals: FakeNutritionRepository.rice.forGrams(100),
  source: MealSource.manual,
);

void main() {
  testWidgets('meal section preserves actions and async states', (
    tester,
  ) async {
    var addCalls = 0;
    var scanCalls = 0;
    var editCalls = 0;
    var deleteCalls = 0;
    var retryCalls = 0;
    final meal = _meal();

    await tester.pumpWidget(
      _host(
        MealLogSection(
          catalogState: const AsyncData([FakeNutritionRepository.rice]),
          mealsState: AsyncData([meal]),
          catalog: const [FakeNutritionRepository.rice],
          meals: [meal],
          action: const AsyncData(null),
          onAdd: () => addCalls++,
          onScan: () => scanCalls++,
          showScanner: true,
          onEdit: (_) => editCalls++,
          onDelete: (_) => deleteCalls++,
          onRetry: () => retryCalls++,
          onDismissError: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-meal')));
    await tester.tap(find.byKey(const ValueKey('scan-food')));
    final menu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    menu.onSelected!('edit');
    menu.onSelected!('delete');
    expect((addCalls, scanCalls, editCalls, deleteCalls), (1, 1, 1, 1));

    await tester.pumpWidget(
      _host(
        MealLogSection(
          catalogState: const AsyncData([FakeNutritionRepository.rice]),
          mealsState: const AsyncLoading(),
          catalog: const [FakeNutritionRepository.rice],
          meals: const [],
          action: const AsyncData(null),
          onAdd: () {},
          onScan: () {},
          onEdit: (_) {},
          onDelete: (_) {},
          onRetry: () => retryCalls++,
          onDismissError: () {},
        ),
      ),
    );
    expect(find.text('Đang tải danh mục và nhật ký…'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        MealLogSection(
          catalogState: const AsyncData([FakeNutritionRepository.rice]),
          mealsState: AsyncError(
            const NutritionFailure('Không tải được bữa ăn.'),
            StackTrace.empty,
          ),
          catalog: const [FakeNutritionRepository.rice],
          meals: const [],
          action: const AsyncData(null),
          onAdd: () {},
          onScan: () {},
          onEdit: (_) {},
          onDelete: (_) {},
          onRetry: () => retryCalls++,
          onDismissError: () {},
        ),
      ),
    );
    expect(find.text('Không tải được bữa ăn.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retryCalls, 1);

    await tester.pumpWidget(
      _host(
        MealLogSection(
          catalogState: const AsyncData([FakeNutritionRepository.rice]),
          mealsState: const AsyncData([]),
          catalog: const [FakeNutritionRepository.rice],
          meals: const [],
          action: const AsyncData(null),
          onAdd: () {},
          onScan: () {},
          onEdit: (_) {},
          onDelete: (_) {},
          onRetry: () {},
          onDismissError: () {},
        ),
      ),
    );
    expect(
      find.textContaining('Chưa có bữa ăn. Chọn Thêm để bắt đầu.'),
      findsOneWidget,
    );
  });

  testWidgets('water and activity sections preserve CRUD callbacks', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 13, 8);
    final water = WaterLog(
      id: 'water-1',
      amountMl: 250,
      consumedAt: now,
      dateKey: '2026-10-13',
      timezoneOffsetMinutes: 420,
    );
    final activity = ActivityLog(
      id: 'activity-1',
      type: ActivityType.walking,
      durationMinutes: 30,
      performedAt: now,
      dateKey: '2026-10-13',
      timezoneOffsetMinutes: 420,
      note: '',
    );
    var waterActions = 0;
    var activityActions = 0;

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            WaterLogSection(
              state: AsyncData([water]),
              action: const AsyncData(null),
              onAdd: () => waterActions++,
              onEdit: (_) => waterActions++,
              onDelete: (_) => waterActions++,
              onRetry: () {},
              onDismissError: () {},
            ),
            ActivityLogSection(
              state: AsyncData([activity]),
              action: const AsyncData(null),
              onAdd: () => activityActions++,
              onEdit: (_) => activityActions++,
              onDelete: (_) => activityActions++,
              onRetry: () {},
              onDismissError: () {},
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-water')));
    await tester.tap(find.byKey(const ValueKey('add-activity')));
    final menus = tester.widgetList<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    menus.elementAt(0).onSelected!('edit');
    menus.elementAt(0).onSelected!('delete');
    menus.elementAt(1).onSelected!('edit');
    menus.elementAt(1).onSelected!('delete');

    expect(waterActions, 3);
    expect(activityActions, 3);
    expect(find.text('250 ml'), findsWidgets);
    expect(find.text('30 phút'), findsWidgets);
  });

  testWidgets('daily section and date selector keep error and empty behavior', (
    tester,
  ) async {
    var previousCalls = 0;
    var nextCalls = 0;
    var pickCalls = 0;
    var retryCalls = 0;

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            JournalDateSelector(
              date: DateTime(2026, 10, 13),
              onPrevious: () => previousCalls++,
              onNext: () => nextCalls++,
              onPick: () => pickCalls++,
            ),
            WaterLogSection(
              state: AsyncError(
                const DailyLogFailure('Không tải được nước uống.'),
                StackTrace.empty,
              ),
              action: const AsyncData(null),
              onAdd: () {},
              onEdit: (_) {},
              onDelete: (_) {},
              onRetry: () => retryCalls++,
              onDismissError: () {},
            ),
            ActivityLogSection(
              state: const AsyncData([]),
              action: const AsyncData(null),
              onAdd: () {},
              onEdit: (_) {},
              onDelete: (_) {},
              onRetry: () {},
              onDismissError: () {},
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('journal-previous-day')));
    await tester.tap(find.byKey(const ValueKey('journal-next-day')));
    await tester.tap(find.byKey(const ValueKey('journal-pick-date')));
    await tester.tap(find.text('Thử lại'));

    expect((previousCalls, nextCalls, pickCalls, retryCalls), (1, 1, 1, 1));
    expect(find.text('Không tải được nước uống.'), findsOneWidget);
    expect(find.text('Chưa có hoạt động nào trong ngày này.'), findsOneWidget);
  });
}
