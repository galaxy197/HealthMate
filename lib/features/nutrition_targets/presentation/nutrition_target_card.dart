import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/nutrition_target.dart';
import '../providers/nutrition_target_providers.dart';
import 'nutrition_target_form.dart';

class NutritionTargetCard extends ConsumerWidget {
  const NutritionTargetCard({required this.day, this.meals, super.key});
  final DateTime day;
  final AsyncValue<List<MealLog>>? meals;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = localDateKey(day);
    final state = ref.watch(nutritionTargetProvider(key));
    final value = state.value;
    final today = localDateOnly(ref.watch(localClockProvider));
    final number = NumberFormat('0.#', 'vi');
    final totals =
        meals != null &&
            !meals!.isLoading &&
            !meals!.hasError &&
            meals!.value != null
        ? totalMealNutrition(meals!.value!)
        : null;
    final ready = !state.isLoading && !state.hasError;
    final theme = Theme.of(context);
    Widget line(String label, double target, double? recorded, String unit) {
      final comparison = recorded == null
          ? null
          : TargetComparison(recorded: recorded, target: target);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${recorded == null ? '—' : number.format(recorded)} / ${number.format(target)} $unit',
              style: theme.textTheme.titleSmall,
            ),
            if (comparison != null) ...[
              Text(
                comparison.excess > 0
                    ? 'Vượt ${number.format(comparison.excess)} $unit'
                    : 'Còn ${number.format(comparison.remaining)} $unit',
              ),
              if (comparison.progress != null)
                LinearProgressIndicator(value: comparison.progress),
            ],
          ],
        ),
      );
    }

    return Card(
      key: ValueKey('nutrition-target-$key'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mục tiêu dinh dưỡng', style: theme.textTheme.titleLarge),
            Text('Ngày ${DateFormat('dd/MM/yyyy').format(day)}'),
            if (state.isLoading) ...[
              const LinearProgressIndicator(),
              const Text('Đang tải mục tiêu…'),
            ] else if (state.hasError) ...[
              const Text(
                'Chưa tải được mục tiêu. Không coi lỗi tải là chưa đặt mục tiêu.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(nutritionTargetProvider(key)),
                child: const Text('Thử tải lại mục tiêu'),
              ),
            ] else if (value == null)
              const Text('Chưa đặt mục tiêu')
            else ...[
              Text(
                'Áp dụng từ ${value.effectiveFromDateKey} · Bạn tự thiết lập',
              ),
              if (meals == null)
                Text('Năng lượng: ${number.format(value.kcalTarget)} kcal/ngày')
              else ...[
                line(
                  'Năng lượng đã ghi / mục tiêu',
                  value.kcalTarget,
                  totals?.kcal,
                  'kcal',
                ),
                if (totals == null)
                  const Text(
                    'Nhật ký đang tải hoặc có lỗi; chưa tính còn/vượt.',
                  ),
              ],
              if (value.hasMacros) ...[
                if (meals == null)
                  Text(
                    'Đạm ${number.format(value.proteinGTarget)} · Tinh bột ${number.format(value.carbsGTarget)} · Béo ${number.format(value.fatGTarget)} g/ngày',
                  )
                else ...[
                  line('Đạm', value.proteinGTarget!, totals?.proteinG, 'g'),
                  line('Tinh bột', value.carbsGTarget!, totals?.carbsG, 'g'),
                  line('Béo', value.fatGTarget!, totals?.fatG, 'g'),
                ],
              ] else
                const Text('Chưa đặt mục tiêu cho ba chất'),
              if (meals != null)
                const Text(
                  'So sánh chỉ từ nhật ký đã ghi, không khẳng định bạn đã ghi đủ ngày.',
                ),
            ],
            if (ready)
              TextButton.icon(
                key: ValueKey('edit-nutrition-target-$key'),
                onPressed: () => openNutritionTargetForm(
                  context,
                  ref,
                  localDateKey(today) == key ? value : null,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  localDateKey(today) == key
                      ? (value == null
                            ? 'Thiết lập mục tiêu'
                            : 'Chỉnh mục tiêu từ hôm nay')
                      : 'Thiết lập từ hôm nay',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
