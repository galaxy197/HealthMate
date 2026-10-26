import 'dart:async';
import 'package:healthmate/core/utils/subscription_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'support/fake_auth_repository.dart';
import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/profile/data/health_profile_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

class PendingData implements AccountDataRepository {
  final pending = Completer<void>();
  @override
  Future<void> deleteAllUserData(String uid) => pending.future;
}

class PendingMetrics implements HealthProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final gates = <String, Completer<void>>{};
  bool failA = false;
  @override
  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  }) async {
    await gates.putIfAbsent(uid, Completer<void>.new).future;
    if (uid == 'test-uid' && failA) throw const ProfileFailure('A-only');
    return 'metric-$uid';
  }
}

const userB = AuthUser(emailVerified: true, uid: 'user-b', email: 'b@example.com');
Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'active stream read errors stay errors, with no fabricated empty value',
    () async {
      final source = StreamController<List<int>>();
      final data = <List<int>>[], errors = <Object>[];
      final subscription = subscriptionStream(
        source.stream,
      ).listen(data.add, onError: errors.add);
      const failure = ProfileFailure('Active permission error');
      source.addError(failure);
      await tick();
      expect(errors, [failure]);
      expect(data, isEmpty);
      source.add([1]);
      await tick();
      expect(data, [
        [1],
      ]);
      await subscription.cancel();
      await source.close();
    },
  );

  test(
    'async cancel errors from revoked old subscriptions do not escape to a new session',
    () async {
      final gate = Completer<void>();
      final source = StreamController<int>(onCancel: () => gate.future);
      final values = <int>[], errors = <Object>[];
      final subscription = subscriptionStream(
        source.stream,
      ).listen(values.add, onError: errors.add);
      source.add(1);
      await tick();
      final cancelled = subscription.cancel();
      await tick();
      gate.completeError(const ProfileFailure('Old session cancellation'));
      await cancelled;
      expect(values, [1]);
      expect(errors, isEmpty);
      await source.close();
    },
  );

  for (final failA in [false, true]) {
    test(
      'profile completion from A cannot overwrite B pending state: fail=$failA',
      () async {
        final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
        final repo = PendingMetrics()..failA = failA;
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            healthProfileRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await auth.dispose();
        });
        container.listen(authSessionProvider, (_, _) {});
        await container.read(authSessionProvider.future);
        final controller = container.read(profileControllerProvider.notifier);
        final draft = BodyMetricDraft(
          weightKg: 70,
          measuredAt: DateTime.now(),
          note: '',
        );
        final old = controller.addBodyMetric(draft);
        await tick();
        auth.emitUser(userB);
        await tick();
        await tick();
        expect(container.read(profileControllerProvider).isLoading, isFalse);
        final next = controller.addBodyMetric(draft);
        await tick();
        repo.gates['test-uid']!.complete();
        expect(await old, isFalse);
        expect(container.read(profileControllerProvider).isLoading, isTrue);
        expect(container.read(profileControllerProvider).hasError, isFalse);
        repo.gates['user-b']!.complete();
        expect(await next, isTrue);
      },
    );
  }

  test(
    'changing password stops after reauthentication if UID changes',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser)
        ..pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(() async {
        container.dispose();
        await auth.dispose();
      });
      container.listen(authSessionProvider, (_, _) {});
      await container.read(authSessionProvider.future);
      final request = container
          .read(accountSecurityControllerProvider.notifier)
          .changePassword(
            currentPassword: 'synthetic',
            newPassword: 'synthetic-new',
          );
      await tick();
      auth.emitUser(userB);
      await tick();
      await tick();
      auth.pending!.complete();
      expect(await request, isFalse);
      expect(auth.updatePasswordCalls, 0);
      expect(
        container.read(accountSecurityControllerProvider).hasError,
        isFalse,
      );
    },
  );

  test(
    'account deletion cannot delete B Auth after A data cleanup completes late',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final data = PendingData();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          accountDataRepositoryProvider.overrideWithValue(data),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await auth.dispose();
      });
      container.listen(authSessionProvider, (_, _) {});
      await container.read(authSessionProvider.future);
      final request = container
          .read(accountSecurityControllerProvider.notifier)
          .deleteAccount('synthetic');
      await tick();
      await tick();
      auth.emitUser(userB);
      await tick();
      await tick();
      data.pending.complete();
      expect(await request, isFalse);
      expect(auth.deleteUserCalls, 0);
      expect(
        container.read(accountSecurityControllerProvider).hasError,
        isFalse,
      );
    },
  );

  for (final profileForm in [true, false]) {
    testWidgets(
      'Profile ${profileForm ? "profile" : "weight"} save failure keeps the draft and retry succeeds',
      (tester) async {
        final repo = FakeHealthProfileRepository(
          profile: FakeHealthProfileRepository.testProfile,
        );
        final container = await pumpApp(tester, profileRepository: repo);
        container.read(appRouterProvider).go(AppRoutes.profile);
        await tester.pumpAndSettle();
        final open = find.byKey(
          ValueKey(profileForm ? 'edit-profile' : 'add-metric'),
        );
        await Scrollable.ensureVisible(tester.element(open));
        await tester.pumpAndSettle();
        await tester.tap(open);
        await tester.pumpAndSettle();
        final field = find.byKey(
          ValueKey(profileForm ? 'profile-name' : 'metric-weight'),
        );
        await tester.enterText(field, profileForm ? 'Giữ bản nháp C6' : '71,5');
        repo.failure = const ProfileFailure('Synthetic rejection');
        final save = find.byKey(
          ValueKey(profileForm ? 'save-profile' : 'save-metric'),
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Thông tin vẫn được giữ trong form'),
          findsOneWidget,
        );
        expect(field, findsOneWidget);
        repo.failure = null;
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(field, findsNothing);
        if (profileForm) {
          expect(repo.currentProfile!.displayName, 'Giữ bản nháp C6');
        } else {
          expect(repo.metrics.single.weightKg, 71.5);
        }
      },
    );
  }
  testWidgets(
    'a new weight after onboarding today becomes the latest measured weight',
    (tester) async {
      final earlier = DateTime.now().subtract(const Duration(hours: 1));
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          BodyMetric(
            id: 'onboarding-current',
            weightKg: 70,
            measuredAt: earlier,
            note: '',
            createdAt: earlier,
            updatedAt: earlier,
          ),
        ],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('add-metric'));
      await Scrollable.ensureVisible(tester.element(open));
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('metric-weight')),
        '69,5',
      );
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(repo.metrics.first.weightKg, 69.5);
      expect(repo.metrics.first.measuredAt.isAfter(earlier), isTrue);
    },
  );

  testWidgets(
    'editing only weight keeps its original timestamp including time',
    (tester) async {
      final measured = DateTime(2026, 1, 15, 12, 35, 42, 123, 456);
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          BodyMetric(
            id: 'record',
            weightKg: 70,
            measuredAt: measured,
            note: '',
            createdAt: measured,
            updatedAt: measured,
          ),
        ],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('edit-metric-record'));
      await Scrollable.ensureVisible(tester.element(open));
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('metric-weight')),
        '69,5',
      );
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(repo.metrics.single.measuredAt, measured);
    },
  );

  for (final profileForm in [true, false]) {
    testWidgets(
      'pending Profile ${profileForm ? "profile" : "weight"} form is disposed on logout',
      (tester) async {
        final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
        final repo = FakeHealthProfileRepository(
          profile: FakeHealthProfileRepository.testProfile,
        );
        final container = await pumpApp(
          tester,
          profileRepository: repo,
          repository: auth,
        );
        container.read(appRouterProvider).go(AppRoutes.profile);
        await tester.pumpAndSettle();
        final open = find.byKey(
          ValueKey(profileForm ? 'edit-profile' : 'add-metric'),
        );
        await Scrollable.ensureVisible(tester.element(open));
        await tester.pumpAndSettle();
        await tester.tap(open);
        await tester.pumpAndSettle();
        final field = find.byKey(
          ValueKey(profileForm ? 'profile-name' : 'metric-weight'),
        );
        await tester.enterText(field, profileForm ? 'Old draft' : '69,5');
        final gate = Completer<void>();
        repo.pending = gate;
        await tester.tap(
          find.byKey(ValueKey(profileForm ? 'save-profile' : 'save-metric')),
        );
        await tester.pump();
        auth.emitUser(null);
        await tester.pump();
        await tester.pump();
        expect(field, findsNothing);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.text('Đã cập nhật hồ sơ.'), findsNothing);
        expect(find.text('Đã thêm lần đo.'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
