import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/feature_page.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/presentation/activity_log_dialog.dart';
import '../../activity/providers/activity_providers.dart';
import '../../food_scanner/presentation/food_scanner_dialog.dart';
import '../models/daily_log_failure.dart';
import '../providers/journal_date_provider.dart';
import '../../nutrition/models/nutrition_failure.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/presentation/meal_form_dialog.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/presentation/water_log_dialog.dart';
import '../../water/providers/water_providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  Future<void> _openMealForm(
    BuildContext context,
    WidgetRef ref,
    List<FoodCatalogItem> catalog, {
    MealLog? meal,
    FoodCatalogItem? suggestedFood,
    String initialSearch = '',
    bool aiAssisted = false,
  }) async {
    final draft = await showDialog<MealDraft>(
      context: context,
      builder: (_) => MealFormDialog(
        catalog: catalog,
        meal: meal,
        suggestedFood: suggestedFood,
        initialSearch: initialSearch,
        aiAssisted: aiAssisted,
      ),
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(nutritionControllerProvider.notifier);
    final saved = meal == null
        ? await controller.addMeal(draft)
        : await controller.updateMeal(mealId: meal.id, draft: draft);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            meal == null ? 'Đã lưu bữa ăn.' : 'Đã cập nhật bữa ăn.',
          ),
        ),
      );
    }
  }

  Future<void> _scanFood(
    BuildContext context,
    WidgetRef ref,
    List<FoodCatalogItem> catalog,
  ) async {
    final result = await showDialog<FoodScanChoice>(
      context: context,
      builder: (_) => FoodScannerDialog(catalog: catalog),
    );
    if (result == null || !context.mounted) return;
    await _openMealForm(
      context,
      ref,
      catalog,
      suggestedFood: result.food,
      initialSearch: result.food == null ? result.query : '',
      aiAssisted: true,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MealLog meal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bữa ăn?'),
        content: Text(
          'Bữa ${meal.type.label.toLowerCase()} này sẽ bị xóa khỏi nhật ký.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(nutritionControllerProvider.notifier)
        .deleteMeal(meal.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa bữa ăn.')));
    }
  }

  Future<void> _openWaterForm(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate, {
    WaterLog? log,
  }) async {
    final draft = await showDialog<WaterLogDraft>(
      context: context,
      builder: (_) => WaterLogDialog(selectedDate: selectedDate, log: log),
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(waterControllerProvider.notifier);
    final saved = log == null
        ? await controller.add(draft)
        : await controller.update(log.id, draft);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            log == null ? 'Đã ghi nước uống.' : 'Đã cập nhật nước uống.',
          ),
        ),
      );
    }
  }

  Future<void> _openActivityForm(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate, {
    ActivityLog? log,
  }) async {
    final draft = await showDialog<ActivityLogDraft>(
      context: context,
      builder: (_) => ActivityLogDialog(selectedDate: selectedDate, log: log),
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(activityControllerProvider.notifier);
    final saved = log == null
        ? await controller.add(draft)
        : await controller.update(log.id, draft);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            log == null ? 'Đã ghi hoạt động.' : 'Đã cập nhật hoạt động.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String title,
    Future<bool> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Dữ liệu này sẽ bị xóa khỏi nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  Future<void> _pickJournalDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Ngày nhật ký',
    );
    if (date != null) ref.read(journalDateProvider.notifier).select(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(foodCatalogProvider);
    final mealsState = ref.watch(mealLogsProvider);
    final action = ref.watch(nutritionControllerProvider);
    final selectedDate = ref.watch(journalDateProvider);
    final dateKey = localDateKey(selectedDate);
    final waterState = ref.watch(waterLogsProvider(dateKey));
    final waterAction = ref.watch(waterControllerProvider);
    final activityState = ref.watch(activityLogsProvider(dateKey));
    final activityAction = ref.watch(activityControllerProvider);
    final catalog = catalogState.value ?? const <FoodCatalogItem>[];
    final meals = mealsState.value ?? const <MealLog>[];

    return FeaturePage(
      title: 'Nhật ký của bạn',
      subtitle:
          'Ghi bữa ăn, kiểm tra khẩu phần và theo dõi dinh dưỡng theo thời gian.',
      children: [
        _NutritionCard(
          catalogState: catalogState,
          mealsState: mealsState,
          catalog: catalog,
          meals: meals,
          action: action,
          onAdd: catalog.isEmpty || action.isLoading
              ? null
              : () => _openMealForm(context, ref, catalog),
          onScan: catalog.isEmpty || action.isLoading
              ? null
              : () => _scanFood(context, ref, catalog),
          onEdit: (meal) => _openMealForm(context, ref, catalog, meal: meal),
          onDelete: (meal) => _delete(context, ref, meal),
          onRetry: () {
            ref.invalidate(foodCatalogProvider);
            ref.invalidate(mealLogsProvider);
          },
          onDismissError: ref
              .read(nutritionControllerProvider.notifier)
              .clearError,
        ),
        const SizedBox(height: AppSpacing.md),
        _DateSelector(
          date: selectedDate,
          onPrevious: ref.read(journalDateProvider.notifier).previousDay,
          onNext: selectedDate.isBefore(localDateOnly(DateTime.now()))
              ? ref.read(journalDateProvider.notifier).nextDay
              : null,
          onPick: () => _pickJournalDate(context, ref, selectedDate),
        ),
        const SizedBox(height: AppSpacing.md),
        _WaterCard(
          state: waterState,
          action: waterAction,
          onAdd: () => _openWaterForm(context, ref, selectedDate),
          onEdit: (log) => _openWaterForm(context, ref, selectedDate, log: log),
          onDelete: (log) => _confirmDelete(
            context,
            'Xóa lần uống nước?',
            () => ref.read(waterControllerProvider.notifier).delete(log.id),
          ),
          onRetry: () => ref.invalidate(waterLogsProvider(dateKey)),
          onDismissError: ref.read(waterControllerProvider.notifier).clearError,
        ),
        const SizedBox(height: AppSpacing.md),
        _ActivityCard(
          state: activityState,
          action: activityAction,
          onAdd: () => _openActivityForm(context, ref, selectedDate),
          onEdit: (log) =>
              _openActivityForm(context, ref, selectedDate, log: log),
          onDelete: (log) => _confirmDelete(
            context,
            'Xóa hoạt động?',
            () => ref.read(activityControllerProvider.notifier).delete(log.id),
          ),
          onRetry: () => ref.invalidate(activityLogsProvider(dateKey)),
          onDismissError: ref
              .read(activityControllerProvider.notifier)
              .clearError,
        ),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.catalogState,
    required this.mealsState,
    required this.catalog,
    required this.meals,
    required this.action,
    required this.onAdd,
    required this.onScan,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
  });

  final AsyncValue<List<FoodCatalogItem>> catalogState;
  final AsyncValue<List<MealLog>> mealsState;
  final List<FoodCatalogItem> catalog;
  final List<MealLog> meals;
  final AsyncValue<void> action;
  final VoidCallback? onAdd;
  final VoidCallback? onScan;
  final ValueChanged<MealLog> onEdit;
  final ValueChanged<MealLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadError = catalogState.error ?? mealsState.error;
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
            else if (catalog.isEmpty)
              const Text(
                'Danh mục món ăn chưa có dữ liệu. Vui lòng thử lại sau.',
              )
            else if (meals.isEmpty)
              Text(
                'Danh mục có ${catalog.length} món. Hãy thêm bữa ăn đầu tiên.',
              )
            else
              ...meals.map(
                (meal) => _MealTile(
                  meal: meal,
                  onEdit: () => onEdit(meal),
                  onDelete: () => onDelete(meal),
                ),
              ),
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
    required this.onDelete,
  });

  final MealLog meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.restaurant_outlined)),
      title: Text(
        '${meal.type.label} · ${meal.totals.kcal.toStringAsFixed(0)} kcal',
      ),
      subtitle: Text(
        '${locale.formatMediumDate(meal.consumedAt)}, '
        '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(meal.consumedAt))}\n'
        '${meal.items.map((item) => '${item.name} ${item.grams.toStringAsFixed(0)} g').join(' · ')}\n'
        'P ${meal.totals.proteinG.toStringAsFixed(1)} g · '
        'C ${meal.totals.carbsG.toStringAsFixed(1)} g · '
        'F ${meal.totals.fatG.toStringAsFixed(1)} g'
        '${meal.source == MealSource.aiAssisted ? ' · Gemini hỗ trợ nhận diện' : ''}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Sửa')),
          PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('journal-previous-day'),
              onPressed: onPrevious,
              tooltip: 'Ngày trước',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('journal-pick-date'),
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  locale.formatFullDate(date),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('journal-next-day'),
              onPressed: onNext,
              tooltip: 'Ngày sau',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
  });

  final AsyncValue<List<WaterLog>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final ValueChanged<WaterLog> onEdit;
  final ValueChanged<WaterLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final logs = state.value ?? const <WaterLog>[];
    final total = totalWaterMl(logs);
    return _DailyLogCard(
      icon: Icons.water_drop_outlined,
      title: 'Nước uống',
      summary: '$total ml · ${(total / 1000).toStringAsFixed(2)} lít',
      description: 'Tổng theo ngày đã chọn, dựa trên các lần bạn tự ghi.',
      addKey: const ValueKey('add-water'),
      addLabel: 'Ghi nước uống',
      state: state,
      action: action,
      onAdd: onAdd,
      onRetry: onRetry,
      onDismissError: onDismissError,
      emptyText: 'Chưa có lần uống nước nào trong ngày này.',
      children: [
        for (final log in logs)
          ListTile(
            key: ValueKey('water-log-${log.id}'),
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.water_drop_outlined)),
            title: Text('${log.amountMl} ml'),
            subtitle: Text(
              MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(TimeOfDay.fromDateTime(log.consumedAt)),
            ),
            trailing: _LogMenu(
              onEdit: () => onEdit(log),
              onDelete: () => onDelete(log),
            ),
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
  });

  final AsyncValue<List<ActivityLog>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final ValueChanged<ActivityLog> onEdit;
  final ValueChanged<ActivityLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final logs = state.value ?? const <ActivityLog>[];
    final total = totalActivityMinutes(logs);
    return _DailyLogCard(
      icon: Icons.directions_walk_outlined,
      title: 'Vận động',
      summary: '$total phút',
      description:
          'Do bạn nhập; ứng dụng chưa đo bước chân hoặc tự tính calories tiêu hao.',
      addKey: const ValueKey('add-activity'),
      addLabel: 'Ghi hoạt động',
      state: state,
      action: action,
      onAdd: onAdd,
      onRetry: onRetry,
      onDismissError: onDismissError,
      emptyText: 'Chưa có hoạt động nào trong ngày này.',
      children: [
        for (final log in logs)
          ListTile(
            key: ValueKey('activity-log-${log.id}'),
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.directions_walk_outlined),
            ),
            title: Text('${log.type.label} · ${log.durationMinutes} phút'),
            subtitle: Text(
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(log.performedAt))}'
              '${log.note.isEmpty ? '' : '\n${log.note}'}',
            ),
            trailing: _LogMenu(
              onEdit: () => onEdit(log),
              onDelete: () => onDelete(log),
            ),
          ),
      ],
    );
  }
}

class _DailyLogCard<T> extends StatelessWidget {
  const _DailyLogCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.description,
    required this.addKey,
    required this.addLabel,
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onRetry,
    required this.onDismissError,
    required this.emptyText,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String description;
  final Key addKey;
  final String addLabel;
  final AsyncValue<List<T>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(summary, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: addKey,
              onPressed: action.isLoading ? null : onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(addLabel),
            ),
            if (action.isLoading) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ],
            if (action.error case final DailyLogFailure error) ...[
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(error.message),
                  trailing: IconButton(
                    onPressed: onDismissError,
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            if (state.isLoading)
              const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Đang tải nhật ký…')),
                ],
              )
            else if (state.hasError)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.error is DailyLogFailure
                        ? (state.error! as DailyLogFailure).message
                        : 'Chưa thể tải nhật ký.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else if (children.isEmpty)
              Text(emptyText)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _LogMenu extends StatelessWidget {
  const _LogMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'edit', child: Text('Sửa')),
      PopupMenuItem(value: 'delete', child: Text('Xóa')),
    ],
  );
}
