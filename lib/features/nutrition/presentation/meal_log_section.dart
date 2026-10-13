import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';

class MealLogSection extends StatelessWidget {
  const MealLogSection({
    required this.catalogState,
    required this.mealsState,
    required this.catalog,
    required this.meals,
    required this.action,
    required this.onAdd,
    required this.onScan,
    required this.onEdit,
    this.onDuplicate,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
    super.key,
  });

  final AsyncValue<List<FoodCatalogItem>> catalogState;
  final AsyncValue<List<MealLog>> mealsState;
  final List<FoodCatalogItem> catalog;
  final List<MealLog> meals;
  final AsyncValue<void> action;
  final VoidCallback? onAdd;
  final VoidCallback? onScan;
  final ValueChanged<MealLog> onEdit;
  final ValueChanged<MealLog>? onDuplicate;
  final ValueChanged<MealLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadError = catalogState.error ?? mealsState.error;
    final totals = totalMealNutrition(meals);
    final integer = NumberFormat.decimalPattern('vi_VN');
    final decimal = NumberFormat('0.0', 'vi_VN');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bữa ăn & dinh dưỡng', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Giá trị được tính theo khối lượng từ danh mục tham khảo và không thay thế tư vấn chuyên môn.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const ValueKey('add-meal'),
                  onPressed: onAdd,
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Thêm thủ công')),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonal(
                  key: const ValueKey('scan-food'),
                  onPressed: onScan,
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt_outlined),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Quét món bằng Gemini')),
                    ],
                  ),
                ),
              ],
            ),
            if (action.isLoading) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
            if (action.error case final NutritionFailure error) ...[
              const SizedBox(height: AppSpacing.md),
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(error.message)),
                      IconButton(
                        onPressed: onDismissError,
                        tooltip: 'Đóng',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            if (!mealsState.isLoading && mealsState.error == null) ...[
              Text(
                '${integer.format(totals.kcal.round())} kcal · '
                'P ${decimal.format(totals.proteinG)} g · '
                'C ${decimal.format(totals.carbsG)} g · '
                'F ${decimal.format(totals.fatG)} g',
                key: const ValueKey('nutrition-daily-totals'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (catalogState.isLoading || mealsState.isLoading)
              const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Đang tải danh mục và nhật ký…')),
                ],
              )
            else if (loadError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loadError is NutritionFailure
                        ? loadError.message
                        : 'Chưa thể tải dữ liệu.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else if (meals.isEmpty)
              Text(
                catalog.isEmpty
                    ? 'Danh mục chưa có dữ liệu. Bạn vẫn có thể nhập món ngoài danh mục. Chưa có bữa ăn nào trong ngày này.'
                    : 'Danh mục có ${catalog.length} món. Chưa có bữa ăn nào trong ngày này.',
              )
            else ...[
              if (catalog.isEmpty)
                const Text(
                  'Danh mục chưa tải được; các bữa đã ghi vẫn hiển thị bên dưới.',
                ),
              ...meals.map(
                (meal) => _MealTile(
                  meal: meal,
                  onEdit: () => onEdit(meal),
                  onDuplicate: onDuplicate == null
                      ? null
                      : () => onDuplicate!(meal),
                  onDelete: () => onDelete(meal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.onEdit,
    this.onDuplicate,
    required this.onDelete,
  });

  final MealLog meal;
  final VoidCallback onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final integer = NumberFormat.decimalPattern('vi_VN');
    final decimal = NumberFormat('0.0', 'vi_VN');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.restaurant_outlined)),
      title: Text(
        '${meal.type.label} · ${integer.format(meal.totals.kcal.round())} kcal',
      ),
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy').format(meal.consumedAt)}, '
        '${DateFormat('HH:mm').format(meal.consumedAt)}\n'
        '${meal.items.map((item) => '${item.name} ${integer.format(item.grams)} g').join(' · ')}\n'
        'P ${decimal.format(meal.totals.proteinG)} g · '
        'C ${decimal.format(meal.totals.carbsG)} g · '
        'F ${decimal.format(meal.totals.fatG)} g'
        '${meal.source == MealSource.aiAssisted ? ' · Gemini hỗ trợ nhận diện' : ''}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'edit' => onEdit(),
          'duplicate' => onDuplicate!(),
          _ => onDelete(),
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Sửa')),
          if (onDuplicate != null)
            const PopupMenuItem(
              value: 'duplicate',
              child: Text('Nhân bản bữa'),
            ),
          const PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
    );
  }
}
