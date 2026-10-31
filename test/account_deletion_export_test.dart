import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/auth/models/account_deletion_job.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/data_export/data/journal_export_service.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_water_repository.dart';

AccountDeletionJob deletionJob() => AccountDeletionJob(
  uid: FakeAuthRepository.testUser.uid,
  state: AccountDeletionState.requested,
  checkpoint: 0,
  requestedAt: DateTime(2026, 10, 31),
  updatedAt: DateTime(2026, 10, 31),
);

class ExportFixture {
  ExportFixture(Stream<AccountDeletionJob?> deletion) {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accountDeletionJobProvider.overrideWith((ref) => deletion),
        privateLocalDataProvider.overrideWithValue(local),
        nutritionRepositoryProvider.overrideWithValue(nutrition),
        waterRepositoryProvider.overrideWithValue(water),
        activityRepositoryProvider.overrideWithValue(activity),
        healthProfileRepositoryProvider.overrideWithValue(profile),
      ],
    );
    // The app's access gate keeps this stream actively subscribed. A plain
    // container.read(service) is otherwise paused by Riverpod with no UI watch.
    container.listen(accountDeletionJobProvider, (_, _) {});
    addTearDown(() async {
      container.dispose();
      await auth.dispose();
      await nutrition.dispose();
      await water.dispose();
      await activity.dispose();
      await profile.dispose();
    });
  }
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final local = FakePrivateLocalData();
  final nutrition = FakeNutritionRepository();
  final water = FakeWaterRepository();
  final activity = FakeActivityRepository();
  final profile = FakeHealthProfileRepository();
  late final ProviderContainer container;
  JournalExportService get service =>
      container.read(journalExportServiceProvider);
  void expectNoReadsOrNativeExport() {
    expect(nutrition.rangeCalls, 0);
    expect(water.rangeCalls, 0);
    expect(activity.rangeCalls, 0);
    expect(profile.metricRangeCalls, 0);
    expect(local.picked, 0);
    expect(local.written, 0);
  }
}

void main() {
  final start = DateTime(2026, 10, 18), end = DateTime(2026, 10, 19);

  test(
    'same UID deletion while OS picker is open cancels ticket without writing CSV',
    () async {
      final updates = StreamController<AccountDeletionJob?>.broadcast();
      addTearDown(updates.close);
      final fixture = ExportFixture(
        Stream.multi((controller) {
          controller.add(null);
          final sub = updates.stream.listen(
            controller.add,
            onError: controller.addError,
          );
          controller.onCancel = sub.cancel;
        }),
      );
      final service = fixture.service;
      await fixture.container.read(accountDeletionJobProvider.future);
      final pickerEntered = Completer<void>();
      final pickerResult = Completer<String?>();
      fixture.local.picker = () {
        pickerEntered.complete();
        return pickerResult.future;
      };
      final exporting = service.export(start, end);
      await pickerEntered.future.timeout(const Duration(seconds: 2));
      expect(fixture.nutrition.rangeCalls, 1);
      expect(fixture.water.rangeCalls, 1);
      expect(fixture.activity.rangeCalls, 1);
      expect(fixture.profile.metricRangeCalls, 1);
      updates.add(deletionJob());
      await Future<void>.delayed(Duration.zero);
      expect(fixture.auth.currentUid, FakeAuthRepository.testUser.uid);
      expect(
        fixture.container.read(accountDeletionJobProvider).value,
        isNotNull,
      );
      pickerResult.complete('synthetic-empty-document-ticket');
      await expectLater(exporting, throwsStateError);
      expect(fixture.local.cancelled, 1);
      expect(fixture.local.written, 0);
      expect(fixture.local.csv, isNull);
    },
  );

  test(
    'existing deletion marker prevents export before any repository read',
    () async {
      final fixture = ExportFixture(Stream.value(deletionJob()));
      final service = fixture.service;
      await fixture.container.read(accountDeletionJobProvider.future);
      await expectLater(service.export(start, end), throwsStateError);
      fixture.expectNoReadsOrNativeExport();
    },
  );

  test(
    'pending deletion check prevents export before any repository read',
    () async {
      final updates = StreamController<AccountDeletionJob?>();
      addTearDown(updates.close);
      final fixture = ExportFixture(updates.stream);
      final service = fixture.service;
      expect(
        fixture.container.read(accountDeletionJobProvider).isLoading,
        true,
      );
      await expectLater(service.export(start, end), throwsStateError);
      fixture.expectNoReadsOrNativeExport();
    },
  );

  test(
    'failed deletion check prevents export before any repository read',
    () async {
      final fixture = ExportFixture(Stream.error(StateError('unavailable')));
      final service = fixture.service;
      await expectLater(
        fixture.container.read(accountDeletionJobProvider.future),
        throwsStateError,
      );
      await expectLater(service.export(start, end), throwsStateError);
      fixture.expectNoReadsOrNativeExport();
    },
  );
}
