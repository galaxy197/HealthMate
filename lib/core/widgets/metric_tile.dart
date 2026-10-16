import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'icon_chip.dart';
import 'metric_value.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.unit,
    required this.accentBackground,
    required this.accentForeground,
    super.key,
    this.subtitle,
    this.action,
  });

  final String title;
  final IconData icon;
  final String value;
  final String unit;
  final Color accentBackground;
  final Color accentForeground;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconChip(
                icon: icon,
                backgroundColor: accentBackground,
                foregroundColor: accentForeground,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MetricValue(value: value, unit: unit),
          if (subtitle != null || action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (action != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  action!,
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
