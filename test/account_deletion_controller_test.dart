import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/auth/models/account_action_failure.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'support/fake_account_data_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_private_local_data.dart';

class DeletionDevice extends WellnessDevice {
  DeletionDevice(this.events);
  final List<String> events;
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<void> clearAccount(String uid) async {
    events.add('stop-native');
    if (fail) throw StateError('device cleanup failed');
  }
}

class DeletionDrafts extends FakePrivateLocalData {
  DeletionDrafts(this.events);
  final List<String> events;
  @override
  Future<void> clearForDeletion(String uid) async {
    events.add('clear-drafts');
    await super.clearForDeletion(uid);
  }
}

void main() {
  late List<String> events;
  late FakeAuthRepository auth;
  late FakeAccountDataRepository data;
  late DeletionDevice device;
  late ProviderContainer container;

  setUp(() async {
    events = [];
    auth = FakeAuthRepository(
      user: FakeAuthRepository.testUser,
      events: events,
    );
    data = FakeAccountDataRepository(events: events);
    device = DeletionDevice(events);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accountDataRepositoryProvider.overrideWithValue(data),
        wellnessDeviceProvider.overrideWithValue(device),
        privateLocalDataProvider.overrideWithValue(DeletionDrafts(events)),
      ],
    );
    container.listen(authSessionProvider, (_, _) {});
    await container.read(authSessionProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await auth.dispose();
  });

  test(
    'reauth and marker precede stopping local writers, server cleanup and Auth',
    () async {
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('synthetic'),
        true,
      );
      expect(events, [
        'reauthenticate',
        'request-deletion',
        'stop-native',
        'clear-drafts',
        'delete-data',
        'local-deleted',
        'delete-auth',
      ]);
    },
  );

  test('marker failure never starts cleanup or reports deleted data', () async {
    data.requestFailure = const AccountDataFailure();
    expect(
      await container
          .read(accountSecurityControllerProvider.notifier)
          .deleteAccount('synthetic'),
      false,
    );
    expect(events, ['reauthenticate', 'request-deletion']);
    expect(auth.deleteUserCalls, 0);
    final error =
        container.read(accountSecurityControllerProvider).error
            as AccountActionFailure;
    expect(error.dataMayBeDeleted, false);
  });

  test(
    'native stop failure preserves marker and Auth; retry is ordered',
    () async {
      device.fail = true;
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('synthetic'),
        false,
      );
      expect(data.job, isNotNull);
      expect(data.deleteCalls, 0);
      expect(auth.deleteUserCalls, 0);
      device.fail = false;
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('synthetic'),
        true,
      );
      expect(data.requestCalls, 2);
      expect(data.deleteCalls, 1);
    },
  );

  test('verification failure never advances to Auth deletion', () async {
    data.localFailure = const AccountDataFailure();
    expect(
      await container
          .read(accountSecurityControllerProvider.notifier)
          .deleteAccount('synthetic'),
      false,
    );
    expect(data.deleteCalls, 1);
    expect(auth.deleteUserCalls, 0);
    expect(auth.currentUid, FakeAuthRepository.testUser.uid);
    expect(
      (container.read(accountSecurityControllerProvider).error
              as AccountActionFailure)
          .dataMayBeDeleted,
      true,
    );
  });

  test(
    'Auth failure after cleanup has specific resumable status and same request',
    () async {
      auth.deleteUserFailure = AuthFailure.fromCode('requires-recent-login');
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('synthetic'),
        false,
      );
      final first = data.job;
      expect(data.localCalls, 1);
      expect(auth.currentUid, first!.uid);
      final error =
          container.read(accountSecurityControllerProvider).error
              as AccountActionFailure;
      expect(error.message, contains('tài khoản đăng nhập chưa thể xóa'));
      auth.deleteUserFailure = null;
      expect(
        await container
            .read(accountSecurityControllerProvider.notifier)
            .deleteAccount('synthetic'),
        true,
      );
      expect(data.job, same(first));
      expect(data.deleteCalls, 2);
      expect(auth.deleteUserCalls, 2);
    },
  );
}
