import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// MyFitnessPal-style calories summary card
/// Features:
/// - "0 cal / 2,420" display
/// - Progress bar
/// - "2,420 left" on right
class MfpCaloriesCard extends StatelessWidget {
  final double consumed;
  final double target;
  final double? burned; // Optional exercise calories

  const MfpCaloriesCard({
    required this.consumed,
    required this.target,
    this.burned,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = target - consumed + (burned ?? 0);
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.navy800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Calories"
          Text(
            'Calories',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Main row: Consumed / Target + Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Consumed / Target
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: consumed.toStringAsFixed(0),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                    ),
                    TextSpan(
                      text: ' cal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: DesignTokens.navy400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${target.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: DesignTokens.navy400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Remaining
              Text(
                '${remaining.toStringAsFixed(0)} left',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DesignTokens.navy300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: DesignTokens.navy700,
              valueColor: AlwaysStoppedAnimation<Color>(
                consumed > target
                    ? DesignTokens.error
                    : DesignTokens.blue500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
