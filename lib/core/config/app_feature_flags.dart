import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_runtime.dart';

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

final appFeatureFlagsProvider = Provider<AppFeatureFlags>((ref) {
  const local = AppFeatureFlags(
    chatbotEnabled: bool.fromEnvironment(
      'HEALTHMATE_ENABLE_CHATBOT',
      defaultValue: true,
    ),
    foodScannerEnabled: bool.fromEnvironment(
      'HEALTHMATE_ENABLE_FOOD_SCANNER',
      defaultValue: true,
    ),
  );
  if (!ref.watch(adminControlsEnabledProvider)) return local;
  final state = ref.watch(adminAppConfigProvider);
  final c = state.value;
  final ready =
      !state.isLoading &&
      !state.hasError &&
      c?.verified == true &&
      !c!.maintenanceMode;
  return AppFeatureFlags(
    chatbotEnabled: local.chatbotEnabled && ready && c.chatbotEnabled,
    foodScannerEnabled:
        local.foodScannerEnabled && ready && c.foodScannerEnabled,
  );
});
