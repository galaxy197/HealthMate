import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/private_local_data.dart';
import '../../auth/providers/auth_providers.dart';
import '../../meal_drafts/data/meal_draft_store.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/data/water_repository.dart';
import '../../water/providers/water_providers.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/data/health_profile_repository.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/journal_csv.dart';

final journalExportServiceProvider = Provider<JournalExportService>((ref) {
  var session = 0;
  ref.listen(authSessionProvider.select((s) => s.value?.uid), (before, after) {
    if (before != after) session++;
  });
  return JournalExportService(
    local: ref.watch(privateLocalDataProvider),
    nutrition: ref.watch(nutritionRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    activity: ref.watch(activityRepositoryProvider),
    profile: ref.watch(healthProfileRepositoryProvider),
    currentUid: () =>
        ref.mounted ? ref.read(authRepositoryProvider).currentUid : null,
    sessionVersion: () => session,
  );
});

class JournalExportService {
  JournalExportService({
    required this.local,
    required this.nutrition,
    required this.water,
    required this.activity,
    required this.profile,
    required this.currentUid,
    this.sessionVersion,
  });
  final PrivateLocalData local;
  final NutritionRepository nutrition;
  final WaterRepository water;
  final ActivityRepository activity;
  final HealthProfileRepository profile;
  final String? Function() currentUid;
  final int Function()? sessionVersion;
  bool _busy = false;

  /// null = user cancelled; success is returned only after native byte readback.
  Future<int?> export(
    DateTime start,
    DateTime end, {
    bool Function()? stillOpen,
  }) async {
    if (_busy) throw StateError('Đang xuất dữ liệu.');
    if (!local.supported) {
      throw UnsupportedError('Xuất tệp hiện hỗ trợ Android.');
    }
    final uid = currentUid();
    final session = sessionVersion?.call();
    if (uid == null) throw StateError('Hãy đăng nhập trước khi xuất.');
    void check() {
      if (currentUid() != uid ||
          sessionVersion?.call() != session ||
          stillOpen?.call() == false) {
        throw StateError(
          'Phiên xuất đã thay đổi. Không ghi dữ liệu tài khoản cũ.',
        );
      }
    }

    // Validate range before starting any network reads.
    buildJournalCsv(start: start, endExclusive: end);
    _busy = true;
    String? ticket;
    try {
      final (meals, waterLogs, activities, weights) = await (
        nutrition.loadRange(uid, start, end),
        water.loadRange(uid, start, end),
        activity.loadRange(uid, start, end),
        profile.loadBodyMetricsRange(uid, start, end),
      ).wait.timeout(const Duration(seconds: 30));
      check();
      final csv = buildJournalCsv(
        start: start,
        endExclusive: end,
        meals: meals,
        water: waterLogs,
        activities: activities,
        weights: weights,
      );
      String date(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      ticket = await local.chooseCsv(
        'HealthMate-${date(start)}-${date(DateTime(end.year, end.month, end.day - 1))}.csv',
      );
      if (ticket == null) return null;
      check(); // The OS picker may have remained open through sign-out or account switch.
      final bytes = utf8.encode(csv);
      final verified = await local.writeCsv(ticket, bytes);
      ticket = null;
      if (verified != bytes.length) {
        throw StateError('Chưa kiểm chứng được tệp đã lưu.');
      }
      check();
      return verified;
    } finally {
      if (ticket != null) {
        try {
          await local.cancelCsv(ticket);
        } catch (_) {
          /* Empty document may need manual removal. */
        }
      }
      _busy = false;
    }
  }
}
