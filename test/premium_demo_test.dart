import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/ai_access_policy.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/premium/data/premium_repository.dart';
import 'package:healthmate/features/premium/models/premium_models.dart';
import 'package:healthmate/features/premium/presentation/premium_screen.dart';
import 'package:healthmate/features/premium/providers/premium_providers.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';
import 'support/fake_auth_repository.dart';

final now = DateTime.utc(2026, 10, 30, 12);

class DemoRepository implements PremiumRepository {
  int purchases = 0;
  int consumed = 0;
  bool fail = false;
  PremiumMembership? membership;
  final ids = <String>[];
  @override
  String newTransactionId() => 'demo-order';
  @override
  Stream<PremiumMembership?> watchMembership(String uid) =>
      Stream.value(membership);
  @override
  Stream<PremiumDailyUsage> watchUsage(String uid, DateTime day) =>
      Stream.value(const PremiumDailyUsage(scans: 2, chats: 3));
  @override
  Future<void> purchaseDemo(String uid, String transactionId) async {
    purchases++;
    ids.add(transactionId);
    if (fail) throw const PremiumFailure('Lỗi xác nhận demo');
    membership = PremiumMembership(
      startedAt: now,
      expiresAt: now.add(PremiumDemoPlan.duration),
    );
  }

  @override
  Future<void> consume(String uid, PremiumAiFeature feature) async {
    consumed++;
  }
}

Future<void> open(
  WidgetTester tester,
  DemoRepository repository, {
  double scale = 1,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        premiumDemoEnabledProvider.overrideWithValue(true),
        premiumRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(FakeAuthRepository.testUser),
        ),
        localClockProvider.overrideWithValue(now),
        currentLocalTimeProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const PremiumScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> buy(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('purchase-premium-demo')),
  );
  await tester.tap(find.byKey(const ValueKey('purchase-premium-demo')));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'plan quotas, exact expiry and Vietnam midnight reset across UTC dates',
    () {
      expect(PremiumDemoPlan.priceVnd, 20000);
      expect(PremiumDemoPlan.limit(PremiumAiFeature.scan, false), 3);
      expect(PremiumDemoPlan.limit(PremiumAiFeature.chat, false), 5);
      expect(PremiumDemoPlan.limit(PremiumAiFeature.scan, true), 20);
      expect(PremiumDemoPlan.limit(PremiumAiFeature.chat, true), 50);
      final before = DateTime.parse('2026-10-30T16:59:59Z');
      final after = DateTime.parse('2026-10-30T17:00:00Z');
      expect(
        PremiumDemoPlan.dayStart(before),
        DateTime.parse('2026-10-29T17:00:00Z'),
      );
      expect(PremiumDemoPlan.dayStart(after), after);
      expect(
        PremiumDemoPlan.dayId(before),
        isNot(PremiumDemoPlan.dayId(after)),
      );
      final member = PremiumMembership(
        startedAt: now,
        expiresAt: now.add(PremiumDemoPlan.duration),
      );
      expect(member.activeAt(now), true);
      expect(member.activeAt(now.subtract(const Duration(seconds: 1))), false);
      expect(member.activeAt(member.expiresAt), false);
      expect(
        const PremiumDailyUsage(
          scans: 20,
        ).remaining(PremiumAiFeature.scan, false),
        0,
      );
    },
  );
  test('normal build quota is a no-op without initializing Firebase', () async {
    final container = ProviderContainer(
      overrides: [premiumDemoEnabledProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    await container.read(premiumQuotaProvider)(PremiumAiFeature.scan);
  });
  test(
    'scanner quota rejection happens before provider request; invalid image consumes nothing',
    () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          appFeatureFlagsProvider.overrideWithValue(
            const AppFeatureFlags(foodScannerEnabled: true),
          ),
          aiAccessProvider.overrideWithValue(
            const AiAccess(allowed: true, message: ''),
          ),
          premiumQuotaProvider.overrideWithValue((_) async {
            calls++;
            throw const PremiumFailure('Hết lượt demo');
          }),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(foodScannerServiceProvider);
      await expectLater(
        service.analyze(bytes: Uint8List(0), mimeType: 'image/png'),
        throwsA(isA<FoodScannerFailure>()),
      );
      expect(calls, 0);
      await expectLater(
        service.analyze(bytes: Uint8List.fromList([1]), mimeType: 'image/png'),
        throwsA(
          isA<FoodScannerFailure>().having(
            (e) => e.message,
            'message',
            'Hết lượt demo',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  testWidgets(
    'cancel purchase writes nothing; confirmed demo activates package and disables rebuy',
    (tester) async {
      final repository = DemoRepository();
      await open(tester, repository);
      expect(find.text('Hôm nay còn 1 lượt quét ảnh'), findsOneWidget);
      await buy(tester);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repository.purchases, 0);
      await buy(tester);
      await tester.tap(find.text('Xác nhận demo'));
      await tester.pumpAndSettle();
      expect(repository.purchases, 1);
      expect(find.text('Premium đang hoạt động'), findsOneWidget);
      expect(find.text('Hôm nay còn 18 lượt quét ảnh'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('purchase-premium-demo')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets('uncertain demo purchase retry uses same transaction ID', (
    tester,
  ) async {
    final repository = DemoRepository()..fail = true;
    await open(tester, repository);
    await buy(tester);
    await tester.tap(find.text('Xác nhận demo'));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi xác nhận demo'), findsOneWidget);
    repository.fail = false;
    await buy(tester);
    await tester.tap(find.text('Xác nhận demo'));
    await tester.pumpAndSettle();
    expect(repository.ids, ['demo-order', 'demo-order']);
  });
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('premium screen has no overflow at 320px scale $scale', (
      tester,
    ) async {
      await open(tester, DemoRepository(), scale: scale, width: 320);
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
