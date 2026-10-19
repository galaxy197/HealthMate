import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// App-wide color definitions
/// Modern minimalist palette: Deep navy + electric cyan + warm orange
abstract final class AppColors {
  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Canvas/Scaffold background - Off-white
  static const lightCanvas = DesignTokens.navy50;  // #F8FAFC

  /// Surface - Pure white cards
  static const lightSurface = Color(0xFFFFFFFF);

  /// Surface muted - Subtle gray
  static const lightSurfaceMuted = DesignTokens.navy100;  // #F1F5F9

  /// Primary - Electric cyan
  static const lightPrimary = DesignTokens.cyan500;  // #06B6D4

  /// On primary - Dark navy (readable on cyan)
  static const lightOnPrimary = DesignTokens.navy900;  // #0F172A

  /// Text - Dark navy
  static const lightText = DesignTokens.navy900;  // #0F172A

  /// Text muted - Mid navy
  static const lightTextMuted = DesignTokens.navy600;  // #475569

  /// Outline - Light gray
  static const lightOutline = DesignTokens.navy200;  // #E2E8F0

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Canvas - True black for OLED
  static const darkCanvas = Color(0xFF000000);

  /// Surface - Dark navy
  static const darkSurface = DesignTokens.navy900;  // #0F172A

  /// Surface elevated - Slightly lighter navy
  static const darkSurfaceElevated = DesignTokens.navy800;  // #1E293B

  /// Primary - Bright cyan (more vibrant for dark)
  static const darkPrimary = DesignTokens.cyan400;  // #22D3EE

  /// On primary - Dark navy
  static const darkOnPrimary = DesignTokens.navy900;  // #0F172A

  /// Text - Off-white
  static const darkText = DesignTokens.navy50;  // #F8FAFC

  /// Text muted - Light gray
  static const darkTextMuted = DesignTokens.navy400;  // #94A3B8

  /// Outline - Dark gray
  static const darkOutline = DesignTokens.navy700;  // #334155
}

@immutable
class AppMetricColors extends ThemeExtension<AppMetricColors> {
  const AppMetricColors({
    required this.waterContainer,
    required this.onWaterContainer,
    required this.mealContainer,
    required this.onMealContainer,
    required this.activityContainer,
    required this.onActivityContainer,
    required this.weightContainer,
    required this.onWeightContainer,
  });

  /// Updated metric colors with modern palette
  static const light = AppMetricColors(
    // Water - Electric cyan
    waterContainer: DesignTokens.cyan100,      // Light cyan background
    onWaterContainer: DesignTokens.cyan600,    // Dark cyan text

    // Meal - Warm orange
    mealContainer: DesignTokens.orange100,     // Light orange background
    onMealContainer: DesignTokens.orange600,   // Dark orange text

    // Activity - Emerald green
    activityContainer: DesignTokens.activityLight,  // Light green background
    onActivityContainer: DesignTokens.activityDark, // Dark green text

    // Weight - Purple
    weightContainer: DesignTokens.weightLight,      // Light purple background
    onWeightContainer: DesignTokens.weightDark,     // Dark purple text
  );

  static const dark = AppMetricColors(
    // Water - Electric cyan (vibrant for dark)
    waterContainer: Color(0xFF164E63),         // Dark cyan background
    onWaterContainer: DesignTokens.cyan300,    // Light cyan text

    // Meal - Warm orange
    mealContainer: Color(0xFF7C2D12),          // Dark orange background
    onMealContainer: DesignTokens.orange300,   // Light orange text

    // Activity - Emerald green
    activityContainer: Color(0xFF065F46),      // Dark green background
    onActivityContainer: Color(0xFF6EE7B7),    // Light green text

    // Weight - Purple
    weightContainer: Color(0xFF581C87),        // Dark purple background
    onWeightContainer: Color(0xFFC4B5FD),      // Light purple text
  );

  final Color waterContainer;
  final Color onWaterContainer;
  final Color mealContainer;
  final Color onMealContainer;
  final Color activityContainer;
  final Color onActivityContainer;
  final Color weightContainer;
  final Color onWeightContainer;

  @override
  AppMetricColors copyWith({
    Color? waterContainer,
    Color? onWaterContainer,
    Color? mealContainer,
    Color? onMealContainer,
    Color? activityContainer,
    Color? onActivityContainer,
    Color? weightContainer,
    Color? onWeightContainer,
  }) => AppMetricColors(
    waterContainer: waterContainer ?? this.waterContainer,
    onWaterContainer: onWaterContainer ?? this.onWaterContainer,
    mealContainer: mealContainer ?? this.mealContainer,
    onMealContainer: onMealContainer ?? this.onMealContainer,
    activityContainer: activityContainer ?? this.activityContainer,
    onActivityContainer: onActivityContainer ?? this.onActivityContainer,
    weightContainer: weightContainer ?? this.weightContainer,
    onWeightContainer: onWeightContainer ?? this.onWeightContainer,
  );

  @override
  AppMetricColors lerp(AppMetricColors? other, double t) {
    if (other == null) return this;
    return AppMetricColors(
      waterContainer: Color.lerp(waterContainer, other.waterContainer, t)!,
      onWaterContainer: Color.lerp(
        onWaterContainer,
        other.onWaterContainer,
        t,
      )!,
      mealContainer: Color.lerp(mealContainer, other.mealContainer, t)!,
      onMealContainer: Color.lerp(onMealContainer, other.onMealContainer, t)!,
      activityContainer: Color.lerp(
        activityContainer,
        other.activityContainer,
        t,
      )!,
      onActivityContainer: Color.lerp(
        onActivityContainer,
        other.onActivityContainer,
        t,
      )!,
      weightContainer: Color.lerp(weightContainer, other.weightContainer, t)!,
      onWeightContainer: Color.lerp(
        onWeightContainer,
        other.onWeightContainer,
        t,
      )!,
    );
  }
}

extension AppMetricColorsX on BuildContext {
  AppMetricColors get metricColors =>
      Theme.of(this).extension<AppMetricColors>() ?? AppMetricColors.light;
}
