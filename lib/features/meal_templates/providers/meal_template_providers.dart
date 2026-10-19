import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/subscription_stream.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/meal_template_repository.dart';
import '../models/meal_template.dart';

final mealTemplateRepositoryProvider = Provider<MealTemplateRepository>(
  (ref) => FirebaseMealTemplateRepository(FirebaseFirestore.instance),
);
final mealTemplatesProvider = StreamProvider.autoDispose
    .family<List<MealTemplate>, int>((ref, limit) {
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) {
        return Stream.error(
          const MealTemplateFailure('Hãy đăng nhập để dùng bữa mẫu.'),
        );
      }
      return subscriptionStream(
        ref.watch(mealTemplateRepositoryProvider).watch(uid, limit: limit),
      );
    }, retry: (_, _) => null);

final mealTemplateControllerProvider =
    NotifierProvider<MealTemplateController, AsyncValue<void>>(
      MealTemplateController.new,
    );

class MealTemplateController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  Future<bool> _run(
    Future<void> Function(MealTemplateRepository, String) action,
  ) async {
    if (state.isLoading) return false;
    final uid = ref.read(authSessionProvider).value?.uid,
        generation = _generation;
    if (uid == null) return false;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(authSessionProvider).value?.uid == uid;
    state = const AsyncLoading();
    try {
      await action(ref.read(mealTemplateRepositoryProvider), uid);
      if (!current()) return false;
      ref.invalidate(mealTemplatesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      if (current()) {
        state = AsyncError(
          e is MealTemplateFailure ? e : const MealTemplateFailure(),
          st,
        );
      }
      return false;
    }
  }

  Future<bool> save(MealTemplate t, {required bool create}) =>
      _run((r, uid) => r.save(uid, t, create: create));
  Future<bool> delete(MealTemplate t) => _run((r, uid) => r.delete(uid, t.id));
}
