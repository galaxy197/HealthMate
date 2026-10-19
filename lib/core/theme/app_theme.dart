import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'design_tokens.dart';

/// Modern minimalist theme for HealthMate
/// Key features:
/// - Deep navy + electric cyan color scheme
/// - Inter typography (fallback BeVietnamPro)
/// - Generous whitespace
/// - Smooth animations
/// - Subtle shadows & glass effects
abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Build color scheme from modern palette
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
      // Secondary accent - warm orange
      secondary: DesignTokens.orange500,
      onSecondary: DesignTokens.navy900,
      // Semantic colors
      error: DesignTokens.error,
      errorContainer: isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      // Typography: Inter with fallback BeVietnamPro
      fontFamily: DesignTokens.fontFamily,
      fontFamilyFallback: const [DesignTokens.fontFamilyFallback],
      scaffoldBackgroundColor: isLight
          ? AppColors.lightCanvas
          : AppColors.darkCanvas,
      extensions: [isLight ? AppMetricColors.light : AppMetricColors.dark],
    );

    // Build text theme with modern typography
    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    // Rounded card shape with softer radius
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    );

    return base.copyWith(
      // ========================================================================
      // TYPOGRAPHY - Modern, readable, tight headings
      // ========================================================================
      textTheme: textTheme.copyWith(
        // Display - Large headings
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.headingLineHeight,
          letterSpacing: DesignTokens.headingLetterSpacing,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.headingLineHeight,
          letterSpacing: DesignTokens.headingLetterSpacing,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.headingLineHeight,
        ),

        // Headlines
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.headingLineHeight,
          letterSpacing: DesignTokens.headingLetterSpacing,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.compactLineHeight,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: DesignTokens.bold,
          height: DesignTokens.compactLineHeight,
        ),

        // Titles
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: DesignTokens.bold,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: DesignTokens.semibold,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: DesignTokens.semibold,
        ),

        // Body - Generous line height for readability
        bodyLarge: textTheme.bodyLarge?.copyWith(
          height: DesignTokens.bodyLineHeight,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          height: DesignTokens.bodyLineHeight,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          height: DesignTokens.bodyLineHeight,
        ),

        // Labels
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: DesignTokens.semibold,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: DesignTokens.medium,
        ),
      ),

      // ========================================================================
      // APP BAR - Clean, minimal, no elevation
      // ========================================================================
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.lightCanvas : AppColors.darkCanvas,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: DesignTokens.bold,
          color: scheme.onSurface,
        ),
      ),

      // ========================================================================
      // CARDS - Floating with subtle shadow
      // ========================================================================
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shadowColor: isLight ? Colors.black12 : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape.copyWith(
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      // ========================================================================
      // BUTTONS - Modern, rounded, proper sizing
      // ========================================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, DesignTokens.buttonHeightMd),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.semibold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, DesignTokens.buttonHeightMd),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.semibold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, DesignTokens.buttonHeightSm),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: DesignTokens.semibold,
          ),
        ),
      ),

      // ========================================================================
      // NAVIGATION - Clean, modern indicators
      // ========================================================================
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? DesignTokens.bold
                : DesignTokens.medium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: DesignTokens.bold,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: DesignTokens.medium,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ========================================================================
      // INPUTS - Clean, spacious, modern
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        errorMaxLines: 4,
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),

      // ========================================================================
      // DIVIDERS - Subtle
      // ========================================================================
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),

      // ========================================================================
      // TOOLTIPS
      // ========================================================================
      tooltipTheme: TooltipThemeData(
        preferBelow: false,
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      // ========================================================================
      // CHIPS - Modern pill shape
      // ========================================================================
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
      ),

      // ========================================================================
      // FLOATING ACTION BUTTON
      // ========================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
    );
  }
}

