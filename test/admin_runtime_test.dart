import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/admin_runtime.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/config/ai_access_policy.dart';
import 'package:healthmate/core/widgets/admin_access_gate.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';

class RuntimeFake implements AdminRuntimeRepository {
  AppAccountAccess access = const AppAccountAccess();
  AdminAppConfig config = const AdminAppConfig();
  final accesses = StreamController<AppAccountAccess>.broadcast();
  final configs = StreamController<AdminAppConfig>.broadcast();
  final synced = <Map<String, String>>[];
  @override
  Stream<AppAccountAccess> watchAccess(String uid) => Stream.multi((c) {
    c.add(access);
    final s = accesses.stream.listen(c.add, onError: c.addError);
    c.onCancel = s.cancel;
  });
  @override
  Stream<AdminAppConfig> watchConfig() => Stream.multi((c) {
    c.add(config);
    final s = configs.stream.listen(c.add, onError: c.addError);
    c.onCancel = s.cancel;
  });
  @override
  Future<void> syncDirectory({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    synced.add({'uid': uid, 'displayName': displayName, 'email': email});
  }

  Future<void> dispose() async {
    await accesses.close();
    await configs.close();
  }
}

ProviderContainer setup(RuntimeFake fake, {bool enabled = true}) {
  final container = ProviderContainer(
    overrides: [
      adminControlsEnabledProvider.overrideWithValue(enabled),
      adminRuntimeRepositoryProvider.overrideWithValue(fake),
      authSessionProvider.overrideWith(
        (ref) => Stream.value(FakeAuthRepository.testUser),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(FakeHealthProfileRepository.testProfile),
      ),
    ],
  );
  container.listen(authSessionProvider, (_, _) {});
  container.listen(userProfileProvider, (_, _) {});
  container.listen(appAccountAccessProvider, (_, _) {});
  container.listen(adminAppConfigProvider, (_, _) {});
  return container;
}

void main() {
  test(
    'runtime parsers reject malformed status and configuration, preserve unverified cache state',
    () {
      expect(AppAccountAccess.fromData(null).suspended, false);
      expect(
        AppAccountAccess.fromData({
          'status': 'suspended',
          'reason': 'Local test',
        }, verified: false).verified,
        false,
      );
      expect(
        () => AppAccountAccess.fromData({'status': 'deleted'}),
        throwsFormatException,
      );
      expect(
        () => AdminAppConfig.fromData({'chatbotEnabled': 'false'}),
        throwsFormatException,
      );
      expect(AdminAppConfig.fromData(null, verified: false).verified, false);
    },
  );
  test(
    'default build never constructs Firebase runtime and keeps local feature flags',
    () async {
      final c = ProviderContainer(
        overrides: [
          adminControlsEnabledProvider.overrideWithValue(false),
          adminRuntimeRepositoryProvider.overrideWith(
            (ref) => throw StateError('must not connect'),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(appAccountAccessProvider, (_, _) {});
      c.listen(adminAppConfigProvider, (_, _) {});
      expect((await c.read(appAccountAccessProvider.future)).suspended, false);
      expect(
        (await c.read(adminAppConfigProvider.future)).foodScannerEnabled,
        true,
      );
      expect(c.read(appFeatureFlagsProvider).foodScannerEnabled, true);
      await c.read(adminDirectorySyncProvider.future);
    },
  );
  test(
    'remote flags and AI access fail closed for loading, errors, cache, suspension and maintenance',
    () async {
      final fake = RuntimeFake();
      for (final state in [
        'active',
        'cached',
        'suspended',
        'maintenance',
        'scanner-off',
      ]) {
        fake.access = AppAccountAccess(
          verified: state != 'cached',
          suspended: state == 'suspended',
        );
        fake.config = AdminAppConfig(
          verified: state != 'cached',
          maintenanceMode: state == 'maintenance',
          foodScannerEnabled: state != 'scanner-off',
        );
        final container = setup(fake);
        expect(
          container.read(appFeatureFlagsProvider).foodScannerEnabled,
          false,
        );
        expect(container.read(aiAccessProvider).allowed, false);
        await container.read(authSessionProvider.future);
        await container.read(userProfileProvider.future);
        await container.read(appAccountAccessProvider.future);
        await container.read(adminAppConfigProvider.future);
        expect(
          container.read(appFeatureFlagsProvider).foodScannerEnabled,
          state == 'active' || state == 'suspended',
        );
        expect(
          container.read(aiAccessProvider).allowed,
          state == 'active' || state == 'scanner-off',
        );
        container.dispose();
      }
      final errors = ProviderContainer(
        overrides: [
          adminControlsEnabledProvider.overrideWithValue(true),
          adminAppConfigProvider.overrideWith(
            (ref) => Stream.error(StateError('offline')),
          ),
        ],
      );
      errors.listen(adminAppConfigProvider, (_, _) {});
      await expectLater(
        errors.read(adminAppConfigProvider.future),
        throwsStateError,
      );
      expect(errors.read(appFeatureFlagsProvider).foodScannerEnabled, false);
      errors.dispose();
      await fake.dispose();
    },
  );
  test(
    'directory sync sends identity only and skips suspended or unverified sessions',
    () async {
      for (final access in [
        const AppAccountAccess(),
        const AppAccountAccess(suspended: true),
        const AppAccountAccess(verified: false),
      ]) {
        final fake = RuntimeFake()..access = access, c = setup(fake);
        await c.read(authSessionProvider.future);
        await c.read(userProfileProvider.future);
        await c.read(appAccountAccessProvider.future);
        await c.read(adminDirectorySyncProvider.future);
        if (access.verified && !access.suspended) {
          expect(fake.synced.single, {
            'uid': 'test-uid',
            'displayName': 'HealthMate Tester',
            'email': 'member@example.com',
          });
        } else {
          expect(fake.synced, isEmpty);
        }
        c.dispose();
        await fake.dispose();
      }
    },
  );
  testWidgets(
    'suspension closes an already open form; reopening restores navigation; maintenance and offline hide content',
    (tester) async {
      final fake = RuntimeFake(), container = setup(fake);
      addTearDown(container.dispose);
      addTearDown(fake.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => AdminAccessGate(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(title: Text('Private meal form')),
                  ),
                  child: const Text('Private home'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private home'), findsOneWidget);
      await tester.tap(find.text('Private home'));
      await tester.pumpAndSettle();
      expect(find.text('Private meal form'), findsOneWidget);
      fake.accesses.add(
        const AppAccountAccess(suspended: true, reason: 'Local suspension'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tạm khóa truy cập HealthMate'), findsOneWidget);
      expect(find.text('Private meal form'), findsNothing);
      fake.accesses.add(const AppAccountAccess());
      await tester.pumpAndSettle();
      expect(find.text('Private home'), findsOneWidget);
      fake.configs.add(
        const AdminAppConfig(
          maintenanceMode: true,
          maintenanceMessage: 'Local maintenance',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Local maintenance'), findsOneWidget);
      expect(find.text('Private home'), findsNothing);
      fake.configs.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa xác nhận được quyền truy cập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
