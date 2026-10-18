import '../../../core/utils/subscription_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/favorite_food_repository.dart';
import '../data/firebase_favorite_food_repository.dart';
import '../models/favorite_food.dart';

final favoriteFoodRepositoryProvider = Provider<FavoriteFoodRepository>(
  (ref) => FirebaseFavoriteFoodRepository(FirebaseFirestore.instance),
);
final favoriteFoodsProvider = StreamProvider.autoDispose
    .family<FavoriteFoodPage, int>((ref, limit) {
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) {
        return Stream.error(
          const FavoriteFoodFailure('Hãy đăng nhập để xem yêu thích.'),
        );
      }
      return subscriptionStream(
        ref.watch(favoriteFoodRepositoryProvider).watch(uid, limit: limit),
      );
    }, retry: (_, _) => null);
final favoriteFoodControllerProvider =
    NotifierProvider<FavoriteFoodController, AsyncValue<void>>(
      FavoriteFoodController.new,
    );

class FavoriteFoodController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  Future<bool> setFavorite(
    String sourceId,
    bool selected, {
    FoodSourceKind sourceKind = FoodSourceKind.catalog,
  }) async {
    if (state.isLoading) return false;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(authSessionProvider).value?.uid == uid;
    state = const AsyncLoading();
    try {
      await ref
          .read(favoriteFoodRepositoryProvider)
          .setFavorite(uid, sourceId, selected, sourceKind: sourceKind);
      if (!current()) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (current()) {
        state = AsyncError(
          error is FavoriteFoodFailure ? error : const FavoriteFoodFailure(),
          stack,
        );
      }
      return false;
    }
  }
}
