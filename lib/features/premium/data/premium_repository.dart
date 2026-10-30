import '../models/premium_models.dart';

abstract interface class PremiumRepository {
  Stream<PremiumMembership?> watchMembership(String uid);
  Stream<PremiumDailyUsage> watchUsage(String uid, DateTime day);
  String newTransactionId();
  Future<void> purchaseDemo(String uid, String transactionId);
  Future<void> consume(String uid, PremiumAiFeature feature);
}
