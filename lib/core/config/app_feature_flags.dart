import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local build configuration. Feature entry points are visible by default.
/// Explicit false build flags keep core-only builds available. Enabling a flag
/// does not bypass AI eligibility or consent.
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
    chatbotEnabled: bool.fromEnvironment(
      'HEALTHMATE_ENABLE_CHATBOT',
      defaultValue: true,
    ),
    foodScannerEnabled: bool.fromEnvironment(
      'HEALTHMATE_ENABLE_FOOD_SCANNER',
      defaultValue: true,
    ),
  ),
);
