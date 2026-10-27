import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/design_illustration.dart';
import '../../nutrition/models/nutrition_models.dart';

class MealSummaryGrid extends StatelessWidget {
  const MealSummaryGrid({required this.meals, required this.onOpen, super.key});
  final AsyncValue<List<MealLog>> meals;
  final ValueChanged<MealType>? onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns =
          c.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? 1
          : 2;
      final ready = !meals.isLoading && !meals.hasError;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final type in MealType.values)
            SizedBox(
              width: (c.maxWidth - 12 * (columns - 1)) / columns,
              child: Builder(
                builder: (context) {
                  final entries = ready
                      ? meals.value?.where((m) => m.type == type).toList() ??
                            <MealLog>[]
                      : <MealLog>[];
                  return AppCard(
                    key: ValueKey('summary-meal-${type.name}'),
                    padding: const EdgeInsets.all(14),
                    onTap: onOpen == null ? null : () => onOpen!(type),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 142),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: DesignIllustration(switch (type) {
                                  MealType.breakfast => 'sun',
                                  MealType.dinner => 'moon',
                                  _ => 'food',
                                }, size: 26),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type.label,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  !ready || entries.isEmpty
                                      ? '—'
                                      : NumberFormat('#,##0', 'vi').format(
                                          totalMealNutrition(entries).kcal,
                                        ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 31,
                                        height: 1.2,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ),
                              if (entries.isNotEmpty)
                                Text(
                                  'kcal',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (entries.isEmpty)
                            Text(
                              !ready
                                  ? (meals.hasError
                                        ? 'Chưa tải được bữa ăn'
                                        : 'Đang tải…')
                                  : 'Chưa ghi nhận',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          if (entries.isNotEmpty) ...[
                            Text(
                              entries
                                  .expand((m) => m.items)
                                  .map((i) => i.name)
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}
