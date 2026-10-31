import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

BodyMetric metric(int index, {DateTime? measuredAt}) => BodyMetric(
  id: 'm-${index.toString().padLeft(3, '0')}',
  weightKg: 60 + index / 10,
  measuredAt:
      measuredAt ?? DateTime(2026, 1, 1).subtract(Duration(days: index * 30)),
  note: 'Measurement $index',
  createdAt: null,
  updatedAt: null,
);

void main() {
  test(
    'history cursor covers years and timestamp ties without missing or duplicate IDs',
    () async {
      final repository = FakeHealthProfileRepository(
        metrics: [
          for (var i = 0; i < 63; i++)
            metric(i, measuredAt: DateTime(2026, 1, 1)),
        ],
      );
      addTearDown(repository.dispose);
      final ids = <String>[];
      BodyMetricCursor? after;
      var pages = 0;
      while (true) {
        final page = await repository
            .watchBodyMetricPage('uid', after: after)
            .first;
        expect(page.metrics.length, lessThanOrEqualTo(25));
        ids.addAll(page.metrics.map((m) => m.id));
        pages++;
        if (!page.hasMore) break;
        after = page.nextCursor;
      }
      expect(pages, 3);
      expect(ids.toSet().length, 63);
      expect(ids.length, 63);
      expect(ids.first, 'm-062');
      expect(ids.last, 'm-000');
    },
  );

  test(
    'first baseline and latest weight are independent of bounded history page',
    () async {
      final repository = FakeHealthProfileRepository(
        metrics: [for (var i = 0; i < 500; i++) metric(i)],
      );
      addTearDown(repository.dispose);
      final recent = await repository.watchBodyMetrics('uid').first;
      final first = await repository.watchFirstBodyMetric('uid').first;
      final latest = await repository
          .watchLatestBodyMetric('uid', DateTime(2026, 1, 2))
          .first;
      expect(recent.length, 25);
      expect(first.single.id, 'm-499');
      expect(latest.single.id, 'm-000');
      expect(recent.any((m) => m.id == first.single.id), false);
    },
  );

  testWidgets(
    'profile history exposes older/newer pages and retains true latest BMI',
    (tester) async {
      final repository = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [for (var i = 0; i < 51; i++) metric(i)],
      );
      final container = await pumpApp(
        tester,
        profileRepository: repository,
        dashboardNow: DateTime(2026, 2, 1),
      );
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(
        container.read(bodyMetricPageProvider(null)).value!.metrics.length,
        25,
      );
      final initialBmi = tester
          .widget<Text>(find.textContaining('BMI tham khảo:'))
          .data;
      final older = find.byKey(const ValueKey('weight-history-older'));
      await tester.ensureVisible(older);
      await tester.pumpAndSettle();
      await tester.tap(older);
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 2 ·'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-metric-m-025')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-metric-m-000')), findsNothing);
      expect(
        tester.widget<Text>(find.textContaining('BMI tham khảo:')).data,
        initialBmi,
      );
      final newer = find.byKey(const ValueKey('weight-history-newer'));
      await tester.ensureVisible(newer);
      await tester.pumpAndSettle();
      await tester.tap(newer);
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 1 ·'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-metric-m-000')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
