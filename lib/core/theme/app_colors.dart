import 'package:flutter/material.dart';

abstract final class AppColors {
  static const lightCanvas = Color(0xFFFBF7EF);
  static const lightSurface = Color(0xFFFFFDFC);
  static const lightSurfaceMuted = Color(0xFFF5F0E7);
  static const lightPrimary = Color(0xFF216B52);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF17352D);
  static const lightTextMuted = Color(0xFF52655D);
  static const lightOutline = Color(0xFFD8DED8);

  static const darkCanvas = Color(0xFF101815);
  static const darkSurface = Color(0xFF17211D);
  static const darkSurfaceElevated = Color(0xFF1D2924);
  static const darkPrimary = Color(0xFF76D3A9);
  static const darkOnPrimary = Color(0xFF082116);
  static const darkText = Color(0xFFEEF7F1);
  static const darkTextMuted = Color(0xFFB7C7BF);
  static const darkOutline = Color(0xFF33463E);
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

  static const light = AppMetricColors(
    waterContainer: Color(0xFFE7F3FA),
    onWaterContainer: Color(0xFF1F6080),
    mealContainer: Color(0xFFFCEEDC),
    onMealContainer: Color(0xFF874A0F),
    activityContainer: Color(0xFFE7F4EA),
    onActivityContainer: Color(0xFF28643B),
    weightContainer: Color(0xFFF0EBF8),
    onWeightContainer: Color(0xFF5C447C),
  );

  static const dark = AppMetricColors(
    waterContainer: Color(0xFF162B35),
    onWaterContainer: Color(0xFF9DDCF6),
    mealContainer: Color(0xFF34271A),
    onMealContainer: Color(0xFFF5C886),
    activityContainer: Color(0xFF183023),
    onActivityContainer: Color(0xFF9ED9AE),
    weightContainer: Color(0xFF292338),
    onWeightContainer: Color(0xFFD4C2F2),
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
