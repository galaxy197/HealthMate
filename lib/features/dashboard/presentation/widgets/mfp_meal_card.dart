import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// MyFitnessPal-style meal card
/// Features:
/// - Icon + meal name on left
/// - "Log" button on right (blue)
/// - Recent meal suggestion below
/// - Dark card background
class MfpMealCard extends StatelessWidget {
  final IconData icon;
  final String mealName;
  final String? recentMealHint;
  final VoidCallback onLogTap;
  final VoidCallback? onQuickAddTap;

  const MfpMealCard({
    required this.icon,
    required this.mealName,
    required this.onLogTap,
    this.recentMealHint,
    this.onQuickAddTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.navy800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main row: Icon + Name + Log button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignTokens.blue500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: DesignTokens.blue400,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // Meal name
                Expanded(
                  child: Text(
                    mealName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // More button
                IconButton(
                  onPressed: () {}, // TODO: Show meal options
                  icon: const Icon(Icons.more_horiz),
                  color: DesignTokens.navy400,
                  iconSize: 24,
                ),

                // Log button (MyFitnessPal blue)
                ElevatedButton(
                  onPressed: onLogTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.blue500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent meal hint (if provided)
          if (recentMealHint != null) ...[
            const Divider(
              height: 1,
              color: Color(0xFF363A4D),
              indent: 16,
              endIndent: 16,
            ),
            InkWell(
              onTap: onQuickAddTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Log Yesterday's meal again",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recentMealHint!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.navy400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline,
                      color: DesignTokens.navy400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

