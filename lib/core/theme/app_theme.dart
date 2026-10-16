import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final seededScheme = ColorScheme.fromSeed(
      seedColor: isLight ? AppColors.lightPrimary : AppColors.darkPrimary,
      brightness: brightness,
    );
    final scheme = seededScheme.copyWith(
      primary: isLight ? AppColors.lightPrimary : AppColors.darkPrimary,
      onPrimary: isLight ? AppColors.lightOnPrimary : AppColors.darkOnPrimary,
      surface: isLight ? AppColors.lightSurface : AppColors.darkSurface,
      onSurface: isLight ? AppColors.lightText : AppColors.darkText,
      onSurfaceVariant: isLight
          ? AppColors.lightTextMuted
          : AppColors.darkTextMuted,
      outline: isLight ? AppColors.lightOutline : AppColors.darkOutline,
      outlineVariant: isLight ? AppColors.lightOutline : AppColors.darkOutline,
      surfaceContainerLowest: isLight
          ? AppColors.lightSurface
          : AppColors.darkSurface,
      surfaceContainerLow: isLight
          ? AppColors.lightSurfaceMuted
          : AppColors.darkSurfaceElevated,
      surfaceContainer: isLight
          ? AppColors.lightSurfaceMuted
          : AppColors.darkSurfaceElevated,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'BeVietnamPro',
      scaffoldBackgroundColor: isLight
          ? AppColors.lightCanvas
          : AppColors.darkCanvas,
      extensions: [isLight ? AppMetricColors.light : AppMetricColors.dark],
    );
    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    );
    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.8,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.lightCanvas : AppColors.darkCanvas,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: roundedShape.copyWith(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        errorMaxLines: 4,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
