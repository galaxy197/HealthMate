import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../journal/models/daily_log_failure.dart';
import '../data/firebase_water_repository.dart';
import '../data/water_repository.dart';
import '../models/water_log.dart';

final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => FirebaseWaterRepository(FirebaseFirestore.instance),
);

final waterLogsProvider = StreamProvider.autoDispose
    .family<List<WaterLog>, String>((ref, dateKey) async* {
      final user = ref.watch(authSessionProvider).value;
      if (user == null) {
        yield const [];
        return;
      }
      yield* ref.watch(waterRepositoryProvider).watchLogs(user.uid, dateKey);
    });

final waterControllerProvider =
    NotifierProvider<WaterController, AsyncValue<void>>(WaterController.new);

class WaterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> add(WaterLogDraft draft) => _perform((user) async {
    await ref.read(waterRepositoryProvider).add(uid: user.uid, draft: draft);
  });

  Future<bool> update(String id, WaterLogDraft draft) => _perform((user) {
    return ref
        .read(waterRepositoryProvider)
        .update(uid: user.uid, logId: id, draft: draft);
  });

  Future<bool> delete(String id) => _perform((user) {
    return ref.read(waterRepositoryProvider).delete(uid: user.uid, logId: id);
  });

  Future<bool> _perform(Future<void> Function(AuthUser user) operation) async {
    if (state.isLoading) return false;
    final user = ref.read(authSessionProvider).value;
    if (user == null) {
      state = AsyncError(
        const DailyLogFailure('Phiên đăng nhập đã hết hạn.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      await operation(user);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(
          error is DailyLogFailure
              ? error
              : DailyLogFailure.fromCode('unknown'),
          stack,
        );
      }
      return false;
    }
  }
}
