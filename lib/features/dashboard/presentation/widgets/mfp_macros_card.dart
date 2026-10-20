import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// MyFitnessPal-style macros card
/// Features:
/// - 3 horizontal progress bars (Carbs, Fat, Protein)
/// - "X / Y g" format for each macro
/// - Macro-specific colors
class MfpMacrosCard extends StatelessWidget {
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final double proteinConsumed;
  final double proteinTarget;

  const MfpMacrosCard({
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.navy800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Macros"
          Text(
            'Macros',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Carbs row
          _buildMacroRow(
            label: 'Carbs',
            consumed: carbsConsumed,
            target: carbsTarget,
            color: DesignTokens.carbsColor,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Fat row
          _buildMacroRow(
            label: 'Fat',
            consumed: fatConsumed,
            target: fatTarget,
            color: DesignTokens.fatColor,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Protein row
          _buildMacroRow(
            label: 'Protein',
            consumed: proteinConsumed,
            target: proteinTarget,
            color: DesignTokens.proteinColor,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double consumed,
    required double target,
    required Color color,
    required ThemeData theme,
  }) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + Value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.navy300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: DesignTokens.navy700,
            valueColor: AlwaysStoppedAnimation<Color>(
              consumed > target ? DesignTokens.error : color,
            ),
          ),
        ),
      ],
    );
  }
}
