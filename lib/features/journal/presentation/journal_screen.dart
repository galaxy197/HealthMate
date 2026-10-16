import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/feature_page.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/presentation/activity_log_dialog.dart';
import '../../activity/presentation/activity_log_section.dart';
import '../../activity/providers/activity_providers.dart';
import '../../food_scanner/presentation/food_scanner_dialog.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/presentation/meal_form_dialog.dart';
import '../../nutrition/presentation/meal_log_section.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/presentation/water_log_dialog.dart';
import '../../water/presentation/water_log_section.dart';
import '../../water/providers/water_providers.dart';
import '../providers/journal_date_provider.dart';
import '../providers/journal_quick_action_provider.dart';
import 'journal_date_selector.dart';
import 'daily_summary_card.dart';

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
    DateTime? initialConsumedAt,
    MealLog? duplicateFrom,
  }) async {
    final draft = await showDialog<MealDraft>(
      context: context,
      builder: (_) => MealFormDialog(
        catalog: catalog,
        recentItems: ref.read(recentMealItemsProvider).value ?? const [],
        meal: meal,
        initialConsumedAt: initialConsumedAt,
        initialType: duplicateFrom?.type,
        initialItems: duplicateFrom?.items ?? const [],
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

  DateTime _timeOnSelectedDate(DateTime selectedDate, {DateTime? source}) {
    final time = source ?? DateTime.now();
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _quickAddWater(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    int amountMl,
  ) async {
    final saved = await ref
        .read(waterControllerProvider.notifier)
        .add(
          WaterLogDraft(
            amountMl: amountMl,
            consumedAt: _timeOnSelectedDate(selectedDate),
          ),
        );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ghi nhanh $amountMl ml nước.')),
      );
    }
  }

  Future<void> _scanFood(
    BuildContext context,
    WidgetRef ref,
    List<FoodCatalogItem> catalog,
    DateTime selectedDate,
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
      initialConsumedAt: _timeOnSelectedDate(selectedDate),
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

  Future<void> _openQuickAction(
    BuildContext context,
    WidgetRef ref,
    JournalQuickAction action,
    List<FoodCatalogItem> catalog,
    DateTime selectedDate,
  ) async {
    switch (action) {
      case JournalQuickAction.addMeal:
        await _openMealForm(
          context,
          ref,
          catalog,
          initialConsumedAt: _timeOnSelectedDate(selectedDate),
        );
      case JournalQuickAction.scanFood:
        await _scanFood(context, ref, catalog, selectedDate);
      case JournalQuickAction.addWater:
        await _openWaterForm(context, ref, selectedDate);
      case JournalQuickAction.addActivity:
        await _openActivityForm(context, ref, selectedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final selectedDate = ref.watch(journalDateProvider);
    final catalogState = ref.watch(foodCatalogProvider);
    final mealsState = ref.watch(mealLogsProvider(selectedDate));
    final action = ref.watch(nutritionControllerProvider);
    final dateKey = localDateKey(selectedDate);
    final waterState = ref.watch(waterLogsProvider(dateKey));
    final waterAction = ref.watch(waterControllerProvider);
    final activityState = ref.watch(activityLogsProvider(dateKey));
    final activityAction = ref.watch(activityControllerProvider);
    ref.watch(recentMealItemsProvider);
    final catalog = catalogState.value ?? const <FoodCatalogItem>[];
    final meals = mealsState.value ?? const <MealLog>[];
    ref.listen<JournalQuickAction?>(journalQuickActionProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final action = ref.read(journalQuickActionProvider.notifier).take();
        if (action == null) return;
        _openQuickAction(context, ref, action, catalog, selectedDate);
      });
    });

    return FeaturePage(
      title: 'Nhật ký của bạn',
      subtitle:
          'Ghi bữa ăn, kiểm tra khẩu phần và theo dõi dinh dưỡng theo thời gian.',
      children: [
        JournalDateSelector(
          date: selectedDate,
          onPrevious: ref.read(journalDateProvider.notifier).previousDay,
          onNext: selectedDate.isBefore(localDateOnly(DateTime.now()))
              ? ref.read(journalDateProvider.notifier).nextDay
              : null,
          onPick: () => _pickJournalDate(context, ref, selectedDate),
        ),
        const SizedBox(height: AppSpacing.md),
        if (action.isLoading ||
            waterAction.isLoading ||
            activityAction.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Đang chờ máy chủ xác nhận thay đổi. Nếu mất mạng, thao tác có thể được đồng bộ khi kết nối lại; đừng gửi lặp.',
            ),
          ),
        DailySummaryCard(
          date: selectedDate,
          mealsState: mealsState,
          waterState: waterState,
          activityState: activityState,
        ),
        const SizedBox(height: AppSpacing.md),
        MealLogSection(
          catalogState: catalogState,
          mealsState: mealsState,
          catalog: catalog,
          meals: meals,
          action: action,
          onAdd: action.isLoading
              ? null
              : () => _openMealForm(
                  context,
                  ref,
                  catalog,
                  initialConsumedAt: _timeOnSelectedDate(selectedDate),
                ),
          onScan: action.isLoading
              ? null
              : () => _scanFood(context, ref, catalog, selectedDate),
          onEdit: (meal) => _openMealForm(context, ref, catalog, meal: meal),
          onDuplicate: (meal) => _openMealForm(
            context,
            ref,
            catalog,
            initialConsumedAt: _timeOnSelectedDate(
              selectedDate,
              source: meal.consumedAt,
            ),
            duplicateFrom: meal,
          ),
          onDelete: (meal) => _delete(context, ref, meal),
          onRetry: () {
            ref.invalidate(foodCatalogProvider);
            ref.invalidate(mealLogsProvider(selectedDate));
          },
          onDismissError: ref
              .read(nutritionControllerProvider.notifier)
              .clearError,
        ),
        const SizedBox(height: AppSpacing.md),
        WaterLogSection(
          state: waterState,
          action: waterAction,
          onAdd: () => _openWaterForm(context, ref, selectedDate),
          onQuickAdd: (amount) =>
              _quickAddWater(context, ref, selectedDate, amount),
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
        ActivityLogSection(
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
