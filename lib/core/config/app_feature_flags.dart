import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local build configuration. Core builds keep AI off; no remote config or
/// account data is changed. Enabling a flag does not bypass AI eligibility.
class AppFeatureFlags {
  const AppFeatureFlags({
    this.chatbotEnabled = false,
    this.foodScannerEnabled = false,
  });

  final bool chatbotEnabled;
  final bool foodScannerEnabled;
}

final appFeatureFlagsProvider = Provider<AppFeatureFlags>(
  (ref) => const AppFeatureFlags(
    chatbotEnabled: bool.fromEnvironment('HEALTHMATE_ENABLE_CHATBOT'),
    foodScannerEnabled: bool.fromEnvironment('HEALTHMATE_ENABLE_FOOD_SCANNER'),
  ),
);
