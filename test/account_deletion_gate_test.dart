import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/admin_runtime.dart';
import 'package:healthmate/core/widgets/admin_access_gate.dart';
import 'package:healthmate/features/auth/models/account_deletion_job.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_nutrition_repository.dart';

class DeletionDevice extends WellnessDevice {
  final cleared = <String>[];
  final activated = <String?>[];
  Object? clearError;
  @override
  bool get supported => true;
  @override
  Future<void> clearAccount(String uid) async {
    cleared.add(uid);
    if (clearError != null) throw clearError!;
  }

  @override
  Future<void> setAccount(String? uid) async => activated.add(uid);
  @override
  Future<List<MealReminder>> readSettings(String uid) async =>
      defaultMealReminders;
  @override
  Future<SleepReminder> readSleepReminder(String uid) async =>
      const SleepReminder();
  @override
  Future<bool> notificationsAllowed() async => true;
}

AccountDeletionJob job() => AccountDeletionJob(
  uid: FakeAuthRepository.testUser.uid,
  state: AccountDeletionState.cleaning,
  checkpoint: 1,
  requestedAt: DateTime(2026, 10, 31),
  updatedAt: DateTime(2026, 10, 31),
);

Future<void> pumpGate(
  WidgetTester tester, {
  required Stream<AccountDeletionJob?> deletion,
  bool controls = false,
  bool suspended = false,
  DeletionDevice? device,
  FakePrivateLocalData? local,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => Stream.value(FakeAuthRepository.testUser),
        ),
        accountDeletionJobProvider.overrideWith((ref) => deletion),
        adminControlsEnabledProvider.overrideWithValue(controls),
        appAccountAccessProvider.overrideWith(
          (ref) => Stream.value(
            AppAccountAccess(
              suspended: suspended,
              reason: 'Tạm khóa thử nghiệm',
            ),
          ),
        ),
        adminAppConfigProvider.overrideWith(
          (ref) => Stream.value(const AdminAppConfig()),
        ),
        wellnessDeviceProvider.overrideWithValue(device ?? DeletionDevice()),
        privateLocalDataProvider.overrideWithValue(
          local ?? FakePrivateLocalData(),
        ),
      ],
      child: const MaterialApp(
        home: AdminAccessGate(child: Scaffold(body: Text('product content'))),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

SavedMealDraft draft(String id) => SavedMealDraft(
  operationId: id,
  updatedAt: DateTime.now(),
  draft: MealDraft(
    type: MealType.lunch,
    consumedAt: DateTime.now(),
    source: MealSource.manual,
    items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100)],
  ),
);

void main() {
  testWidgets(
    'suspended owner can open deletion confirmation without product access',
    (tester) async {
      await pumpGate(
        tester,
        deletion: Stream.value(null),
        controls: true,
        suspended: true,
      );
      expect(find.text('product content'), findsNothing);
      expect(find.text('Tạm khóa truy cập HealthMate'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('blocked-delete-account')));
      await tester.pumpAndSettle();
      expect(find.text('Xóa vĩnh viễn tài khoản?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('delete-account-password')),
        findsOneWidget,
      );
      final confirm = tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirm-delete-account')),
      );
      expect(confirm.onPressed, isNull);
      expect(
        find.text('UID, trạng thái xóa và nhật ký quản trị vẫn được giữ.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Giữ tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Tạm khóa truy cập HealthMate'), findsOneWidget);
    },
  );

  testWidgets(
    'deletion marker blocks product and stops local writers with admin runtime disabled',
    (tester) async {
      final device = DeletionDevice();
      final local = FakePrivateLocalData();
      local.drafts[FakeAuthRepository.testUser.uid] = 'fixture';
      await pumpGate(
        tester,
        deletion: Stream.value(job()),
        device: device,
        local: local,
      );
      expect(find.text('product content'), findsNothing);
      expect(find.text('Tài khoản đang chờ xóa'), findsOneWidget);
      expect(find.text('Tiếp tục xóa tài khoản'), findsOneWidget);
      expect(device.cleared, [FakeAuthRepository.testUser.uid]);
      expect(device.activated, isEmpty);
      expect(local.drafts, isEmpty);
      expect(local.deletingUids, contains(FakeAuthRepository.testUser.uid));
    },
  );

  testWidgets(
    'loading and failed deletion check fail closed independently of runtime flag',
    (tester) async {
      final stream = StreamController<AccountDeletionJob?>();
      addTearDown(stream.close);
      await pumpGate(tester, deletion: stream.stream);
      expect(find.text('product content'), findsNothing);
      expect(find.text('Đang kiểm tra quyền truy cập'), findsOneWidget);
      stream.addError(StateError('unsafe detail'));
      await tester.pump();
      expect(find.text('product content'), findsNothing);
      expect(find.text('Chưa xác nhận được quyền truy cập'), findsOneWidget);
      expect(find.textContaining('unsafe detail'), findsNothing);
    },
  );

  testWidgets(
    'failed local cleanup is reported and can retry without auto deleting Auth',
    (tester) async {
      final device = DeletionDevice()..clearError = StateError('native fail');
      final local = FakePrivateLocalData();
      await pumpGate(
        tester,
        deletion: Stream.value(job()),
        device: device,
        local: local,
      );
      expect(local.deletingUids, contains(FakeAuthRepository.testUser.uid));
      expect(find.textContaining('Chưa dừng hoặc dọn xong'), findsOneWidget);
      expect(find.text('Tài khoản đang chờ xóa'), findsOneWidget);
      device.clearError = null;
      await tester.tap(find.text('Thử dọn thiết bị lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(device.cleared.length, 2);
      expect(find.textContaining('Chưa dừng hoặc dọn xong'), findsNothing);
    },
  );

  test(
    'deletion draft guard survives store recreation, retry and isolates another UID',
    () async {
      final local = FakePrivateLocalData();
      final first = MealDraftStore(local);
      await first.put('A', draft('before'));
      await first.clearForAccountDeletion('A');
      final reopened = MealDraftStore(local);
      await expectLater(reopened.put('A', draft('late')), throwsStateError);
      await reopened.clearForAccountDeletion('A');
      await reopened.put('B', draft('other'));
      expect(await reopened.list('A'), isEmpty);
      expect((await reopened.list('B')).single.operationId, 'other');
    },
  );

  test(
    'native activation waits for deletion result and never reactivates marked UID',
    () async {
      final device = DeletionDevice();
      final stream = StreamController<AccountDeletionJob?>();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(FakeAuthRepository.testUser),
          ),
          accountDeletionJobProvider.overrideWith((ref) => stream.stream),
          wellnessDeviceProvider.overrideWithValue(device),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(stream.close);
      container.listen(authSessionProvider, (_, _) {});
      await container.read(authSessionProvider.future);
      container.listen(localWellnessProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(device.activated, isEmpty);
      stream.add(job());
      final result = await container.read(localWellnessProvider.future);
      expect(result.available, false);
      expect(device.activated, isEmpty);
      expect(device.cleared, [FakeAuthRepository.testUser.uid]);
    },
  );
}
