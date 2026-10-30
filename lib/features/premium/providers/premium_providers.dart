import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/subscription_stream.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_premium_repository.dart';
import '../data/premium_repository.dart';
import '../models/premium_models.dart';

final premiumDemoEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment(
    'HEALTHMATE_ENABLE_PREMIUM_DEMO',
    defaultValue: false,
  ),
);
final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => FirebasePremiumRepository(
    FirebaseFirestore.instance,
    now: ref.read(currentLocalTimeProvider),
  ),
);
final premiumMembershipProvider =
    StreamProvider.autoDispose<PremiumMembership?>((ref) {
      final uid = ref.watch(authSessionProvider).value?.uid;
      if (!ref.watch(premiumDemoEnabledProvider) || uid == null) {
        return Stream.value(null);
      }
      return subscriptionStream(
        ref.watch(premiumRepositoryProvider).watchMembership(uid),
      );
    });
final premiumUsageProvider = StreamProvider.autoDispose<PremiumDailyUsage>((
  ref,
) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  final start = ref.watch(localClockProvider.select(PremiumDemoPlan.dayStart));
  if (!ref.watch(premiumDemoEnabledProvider) || uid == null) {
    return Stream.value(const PremiumDailyUsage());
  }
  return subscriptionStream(
    ref.watch(premiumRepositoryProvider).watchUsage(uid, start),
  );
});

/// Returns a no-op for existing builds. No Firebase is touched unless the
/// explicitly labelled demo edition is enabled.
final premiumQuotaProvider = Provider<Future<void> Function(PremiumAiFeature)>((
  ref,
) {
  final enabled = ref.watch(premiumDemoEnabledProvider);
  return (feature) async {
    if (!enabled) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) {
      throw const PremiumFailure('Hãy đăng nhập trước khi dùng AI.');
    }
    await ref.read(premiumRepositoryProvider).consume(uid, feature);
    if (!ref.mounted || ref.read(authSessionProvider).value?.uid != uid) {
      throw const PremiumFailure('Phiên đăng nhập đã thay đổi.');
    }
  };
});
