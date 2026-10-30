enum PremiumAiFeature { scan, chat }

abstract final class PremiumDemoPlan {
  static const id = 'premium_demo_30d';
  static const priceVnd = 20000;
  static const duration = Duration(days: 30);
  static int limit(PremiumAiFeature feature, bool premium) => switch (feature) {
    PremiumAiFeature.scan => premium ? 20 : 3,
    PremiumAiFeature.chat => premium ? 50 : 5,
  };

  // Fixed reporting/reset timezone: Vietnam (UTC+7), independent of device zone.
  static DateTime dayStart(DateTime now) {
    final vietnam = now.toUtc().add(const Duration(hours: 7));
    return DateTime.utc(
      vietnam.year,
      vietnam.month,
      vietnam.day,
    ).subtract(const Duration(hours: 7));
  }

  static String dayId(DateTime now) =>
      '${dayStart(now).millisecondsSinceEpoch}';
}

class PremiumMembership {
  const PremiumMembership({required this.startedAt, required this.expiresAt});
  final DateTime startedAt;
  final DateTime expiresAt;
  bool activeAt(DateTime now) =>
      !now.isBefore(startedAt) && now.isBefore(expiresAt);
}

class PremiumDailyUsage {
  const PremiumDailyUsage({this.scans = 0, this.chats = 0});
  final int scans;
  final int chats;
  int used(PremiumAiFeature feature) =>
      feature == PremiumAiFeature.scan ? scans : chats;
  int remaining(PremiumAiFeature feature, bool premium) =>
      (PremiumDemoPlan.limit(feature, premium) - used(feature)).clamp(0, 50);
}

class PremiumFailure implements Exception {
  const PremiumFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
