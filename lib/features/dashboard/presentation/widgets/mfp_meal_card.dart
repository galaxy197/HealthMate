import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';

class MfpMealCard extends StatelessWidget {
  const MfpMealCard({
    required this.icon,
    required this.mealName,
    required this.onLogTap,
    this.summary,
    this.recentMealHint,
    this.onQuickAddTap,
    this.onView,
    super.key,
  });
  final IconData icon;
  final String mealName;
  final String? summary, recentMealHint;
  final VoidCallback? onLogTap, onQuickAddTap, onView;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final header = Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      mealName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
              final button = FilledButton(
                onPressed: onLogTap,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Ghi bữa'),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                  c.maxWidth < 270) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, const SizedBox(height: 12), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            },
          ),
          if (summary != null) ...[
            const SizedBox(height: 14),
            Text(
              summary!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (onView != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onView,
                  child: const Text('Xem chi tiết'),
                ),
              ),
          ],
          if (recentMealHint != null && onQuickAddTap != null) ...[
            const Divider(height: 28),
            InkWell(
              onTap: onQuickAddTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi lại bữa hôm trước',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recentMealHint!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add),
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
