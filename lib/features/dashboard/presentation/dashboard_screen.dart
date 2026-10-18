import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/providers/activity_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/presentation/nutrition_target_card.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_goals_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _quickAddWater(
    BuildContext context,
    WidgetRef ref,
    DateTime now,
  ) async {
    final saved = await ref
        .read(waterControllerProvider.notifier)
        .add(WaterLogDraft(amountMl: 250, consumedAt: now));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Đã ghi nhanh 250 ml nước.'
              : 'Chưa thể ghi nước. Hãy thử lại.',
        ),
      ),
    );
  }

  void _retry(WidgetRef ref, DateTime today) {
    final dateKey = localDateKey(today);
    ref.invalidate(mealLogsProvider(today));
    ref.invalidate(waterLogsProvider(dateKey));
    ref.invalidate(activityLogsProvider(dateKey));
    ref.invalidate(latestBodyMetricProvider(today));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final now = ref.watch(dashboardClockProvider);
    final today = ref.watch(dashboardTodayProvider);
    final dateKey = localDateKey(today);
    final profileState = ref.watch(userProfileProvider);
    final mealsState = ref.watch(mealLogsProvider(today));
    final waterState = ref.watch(waterLogsProvider(dateKey));
    final activityState = ref.watch(activityLogsProvider(dateKey));
    final metricsState = ref.watch(latestBodyMetricProvider(today));
    final waterAction = ref.watch(waterControllerProvider);

    final meals = mealsState.value ?? const <MealLog>[];
    final water = waterState.value ?? const <WaterLog>[];
    final activities = activityState.value ?? const <ActivityLog>[];
    final metrics = metricsState.value ?? const <BodyMetric>[];
    final totals = totalMealNutrition(meals);
    final latestWeight = _latestWeight(
      metrics.where((m) => !m.measuredAt.isAfter(now)).toList(),
    );
    final states = [mealsState, waterState, activityState, metricsState];
    final isInitialLoading = states.every(
      (state) => state.isLoading && state.value == null,
    );
    final hasError = states.any((state) => state.hasError);
    final isResolved = states.every((state) => !state.isLoading);
    final hasData =
        meals.isNotEmpty ||
        water.isNotEmpty ||
        activities.isNotEmpty ||
        metrics.isNotEmpty;
    final displayName = profileState.value?.displayName.trim();

    return FeaturePage(
      key: const ValueKey('dashboard-screen'),
      title:
          '${_greeting(now.hour)}, ${displayName == null || displayName.isEmpty ? 'bạn' : displayName}',
      subtitle: _formatToday(today),
      children: [
        Text(
          'Giờ thiết bị · ${now.timeZoneName} (UTC${now.timeZoneOffset.isNegative ? '-' : '+'}${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(now.timeZoneOffset.inMinutes.abs() % 60).toString().padLeft(2, '0')})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        NutritionTargetCard(day: today, meals: mealsState),
        const SizedBox(height: AppSpacing.md),
        if (hasError) ...[
          _LoadErrorCard(onRetry: () => _retry(ref, today)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (isInitialLoading)
          const _DashboardLoading()
        else if (isResolved && !hasError && !hasData)
          EmptyState(
            key: const ValueKey('dashboard-empty'),
            icon: Icons.auto_awesome_outlined,
            title: 'Hôm nay bắt đầu từ một ghi nhận nhỏ',
            description:
                'Thêm bữa ăn, một cốc nước hoặc hoạt động đầu tiên để xem tổng quan trong ngày.',
            actionLabel: 'Mở nhật ký',
            onAction: () => context.go(AppRoutes.journal),
          )
        else ...[
          _TodayNutritionCard(
            totals: totals,
            isLoading: mealsState.isLoading || mealsState.hasError,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricGrid(
            waterMl: totalWaterMl(water),
            waterLoading: waterState.isLoading || waterState.hasError,
            waterActionLoading: waterAction.isLoading,
            onQuickAddWater: () => _quickAddWater(
              context,
              ref,
              ref.read(currentLocalTimeProvider)(),
            ),
            activityMinutes: totalActivityMinutes(activities),
            activityLoading: activityState.isLoading || activityState.hasError,
            mealCount: meals.length,
            mealLoading: mealsState.isLoading || mealsState.hasError,
            latestWeight: latestWeight,
            weightLoading: metricsState.isLoading || metricsState.hasError,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          key: const ValueKey('open-progress'),
          onPressed: () => context.go(AppRoutes.progress),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Xem tiến độ tuần'),
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardGoalsCard(
          today: today,
          meals: mealsState,
          water: waterState,
          activity: activityState,
          metrics: metricsState,
        ),
        const SizedBox(height: AppSpacing.lg),
        WeeklyReflectionCard(today: today),
      ],
    );
  }
}

String _greeting(int hour) {
  if (hour < 11) return 'Chào buổi sáng';
  if (hour < 14) return 'Chào buổi trưa';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String _formatToday(DateTime date) {
  final formatted = DateFormat('EEEE, d MMMM', 'vi').format(date);
  return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
}

BodyMetric? _latestWeight(List<BodyMetric> metrics) {
  if (metrics.isEmpty) return null;
  return metrics.reduce(
    (latest, current) =>
        current.measuredAt.isAfter(latest.measuredAt) ? current : latest,
  );
}

class _TodayNutritionCard extends StatelessWidget {
  const _TodayNutritionCard({required this.totals, required this.isLoading});

  final NutritionTotals totals;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.metricColors;
    final integer = NumberFormat.decimalPattern('vi');
    final decimal = NumberFormat('0.#', 'vi');
    final value = isLoading ? '—' : integer.format(totals.kcal.round());
    return AppCard(
      key: const ValueKey('dashboard-today-card'),
      color: colors.mealContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hôm nay',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onMealContainer,
                  ),
                ),
              ),
              Icon(Icons.restaurant_rounded, color: colors.onMealContainer),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: colors.onMealContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                  ),
                ),
                TextSpan(
                  text: ' kcal đã ghi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onMealContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _MacroValue(
                label: 'Đạm',
                value: isLoading ? '—' : '${decimal.format(totals.proteinG)} g',
                color: colors.onMealContainer,
              ),
              _MacroValue(
                label: 'Tinh bột',
                value: isLoading ? '—' : '${decimal.format(totals.carbsG)} g',
                color: colors.onMealContainer,
              ),
              _MacroValue(
                label: 'Béo',
                value: isLoading ? '—' : '${decimal.format(totals.fatG)} g',
                color: colors.onMealContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.waterMl,
    required this.waterLoading,
    required this.waterActionLoading,
    required this.onQuickAddWater,
    required this.activityMinutes,
    required this.activityLoading,
    required this.mealCount,
    required this.mealLoading,
    required this.latestWeight,
    required this.weightLoading,
  });

  final int waterMl;
  final bool waterLoading;
  final bool waterActionLoading;
  final VoidCallback onQuickAddWater;
  final int activityMinutes;
  final bool activityLoading;
  final int mealCount;
  final bool mealLoading;
  final BodyMetric? latestWeight;
  final bool weightLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.metricColors;
    final integer = NumberFormat.decimalPattern('vi');
    final decimal = NumberFormat('0.#', 'vi');
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 || textScale < 1.4 ? 2 : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        final height = columns == 1
            ? (textScale >= 1.4 ? 230.0 : 190.0)
            : 240.0;
        final tiles = [
          MetricTile(
            key: const ValueKey('dashboard-water'),
            title: 'Nước',
            icon: Icons.water_drop_outlined,
            value: waterLoading ? '—' : integer.format(waterMl),
            unit: 'ml',
            subtitle: 'Đã ghi hôm nay',
            accentBackground: colors.waterContainer,
            accentForeground: colors.onWaterContainer,
            action: FilledButton.tonal(
              key: const ValueKey('dashboard-quick-water'),
              onPressed: waterActionLoading ? null : onQuickAddWater,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('+250 ml'),
            ),
          ),
          MetricTile(
            key: const ValueKey('dashboard-activity'),
            title: 'Vận động',
            icon: Icons.directions_run_rounded,
            value: activityLoading ? '—' : integer.format(activityMinutes),
            unit: 'phút',
            subtitle: 'Tổng thời lượng hôm nay',
            accentBackground: colors.activityContainer,
            accentForeground: colors.onActivityContainer,
          ),
          MetricTile(
            key: const ValueKey('dashboard-meals'),
            title: 'Bữa ăn',
            icon: Icons.restaurant_menu_rounded,
            value: mealLoading ? '—' : integer.format(mealCount),
            unit: 'bữa',
            subtitle: 'Số bữa đã ghi',
            accentBackground: colors.mealContainer,
            accentForeground: colors.onMealContainer,
          ),
          MetricTile(
            key: const ValueKey('dashboard-weight'),
            title: 'Cân nặng gần nhất',
            icon: Icons.monitor_weight_outlined,
            value: weightLoading
                ? '—'
                : latestWeight == null
                ? '—'
                : decimal.format(latestWeight!.weightKg),
            unit: latestWeight == null || weightLoading ? '' : 'kg',
            subtitle: latestWeight == null
                ? 'Chưa có lần cân nào'
                : 'Ngày ${DateFormat('dd/MM/yyyy').format(latestWeight!.measuredAt)}',
            accentBackground: colors.weightContainer,
            accentForeground: colors.onWeightContainer,
          ),
        ];
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: tile,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.sync_problem_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Một số dữ liệu chưa tải được',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Các phần đã tải thành công vẫn được giữ lại.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const AppCard(
    child: SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}
