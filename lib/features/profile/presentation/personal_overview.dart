import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/design_illustration.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition/presentation/macro_distribution.dart';
import '../../journal/providers/journal_date_provider.dart';
import '../../../core/widgets/recorded_sparkline.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/theme/reference_palette.dart';
import '../../reports/models/period_report.dart';
import '../../reports/providers/report_providers.dart';
import '../../reports/presentation/day_review_controls.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../../wellness/presentation/wellness_hub.dart';
import '../../wellness/providers/wellness_providers.dart';
import '../providers/profile_providers.dart';
import '../models/body_metric.dart';

class PersonalOverview extends ConsumerWidget {
  const PersonalOverview({required this.onEdit, super.key});
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final user = profile.value;
    final today = localDateOnly(ref.watch(localClockProvider));
    final day = localDateKey(today);
    final meals = ref.watch(mealLogsProvider(today));
    final water = ref.watch(waterLogsProvider(day));
    final steps = ref.watch(stepHistoryProvider);
    final sleep = ref.watch(sleepHistoryProvider);
    final weight = ref
        .watch(bodyMetricPageProvider(null))
        .whenData((page) => page.metrics);
    final firstWeight = ref.watch(firstBodyMetricProvider);
    final latestWeight = ref.watch(latestBodyMetricProvider(today));
    final reviews = ref.watch(
      dayReviewsProvider(
        ReportRange(DateTime(today.year, today.month, today.day + 1), 1),
      ),
    );
    final totals = meals.isLoading || meals.hasError
        ? null
        : totalMealNutrition(meals.value ?? []);
    final complete =
        !reviews.isLoading &&
            !reviews.hasError &&
            !meals.isLoading &&
            !meals.hasError
        ? reviews.value?.any((r) => r.matches(meals.value ?? []))
        : null;
    final number = NumberFormat('#,##0.#', 'vi');
    final recordedWeights = weight.isLoading || weight.hasError
        ? <BodyMetric>[]
        : [...?weight.value];
    recordedWeights.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final measured = latestWeight.isLoading || latestWeight.hasError
        ? null
        : latestWeight.value?.firstOrNull;
    final step = !steps.hasError && !steps.isLoading
        ? steps.value?.where((s) => s.day == day).firstOrNull
        : null;
    final night = !sleep.hasError && !sleep.isLoading
        ? sleep.value?.firstOrNull
        : null;
    final cards = [
      HabitMetricCard(
        title: 'Cân nặng',
        art: 'weight',
        value: measured == null ? '—' : number.format(measured.weightKg),
        subtitle: latestWeight.hasError
            ? 'Chưa tải được lần cân'
            : measured == null
            ? 'Chưa có lần cân'
            : 'kg · ${DateFormat('dd/MM').format(measured.measuredAt)}',
        onTap: () => context.push('${AppRoutes.wellness}?tab=5'),
        chart: RecordedSparkline(
          values: recordedWeights.reversed.map((m) => m.weightKg).toList(),
          color: const Color(0xFF685CFF),
        ),
      ),
      HabitMetricCard(
        title: 'Nước uống',
        art: 'water',
        value:
            water.hasError || water.isLoading || (water.value?.isEmpty ?? true)
            ? '—'
            : number.format(totalWaterMl(water.value!)),
        subtitle: water.hasError
            ? 'Chưa tải được nhật ký'
            : water.isLoading
            ? 'Đang tải…'
            : (water.value?.isEmpty ?? true)
            ? 'Chưa ghi nước hôm nay'
            : 'ml đã ghi hôm nay',
        chart: RecordedSparkline(
          values: water.isLoading || water.hasError
              ? []
              : cumulativeWater(water.value ?? []),
          color: ReferencePalette.carb,
        ),
        onTap: () {
          ref.read(journalDateProvider.notifier).select(today);
          context.go(AppRoutes.journal);
        },
      ),
      HabitMetricCard(
        title: 'Bước chân',
        art: 'steps',
        value: step == null ? '—' : number.format(step.steps),
        subtitle: steps.hasError
            ? 'Chưa tải được bước chân'
            : step == null
            ? 'Chưa đồng bộ hôm nay'
            : 'bước · khoảng đã theo dõi',
        onTap: () => context.push('${AppRoutes.wellness}?tab=2'),
        chart: RecordedSparkline(
          values:
              steps.value?.reversed.map((s) => s.steps.toDouble()).toList() ??
              [],
          color: ReferencePalette.blue,
          bars: true,
        ),
      ),
      HabitMetricCard(
        title: 'Giấc ngủ',
        art: 'moon',
        value: night == null
            ? '—'
            : '${night.duration.inHours}g ${night.duration.inMinutes % 60}p',
        subtitle: sleep.hasError
            ? 'Chưa tải được giờ ngủ'
            : night == null
            ? 'Chưa ghi giờ ngủ'
            : 'giờ · tự ghi nhận',
        onTap: () => context.push('${AppRoutes.wellness}?tab=3'),
        chart: RecordedSparkline(
          values:
              sleep.value?.reversed
                  .map((s) => s.duration.inMinutes / 60)
                  .toList() ??
              [],
          color: const Color(0xFF9D94FF),
          bars: true,
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const ProfileAvatar(size: 57),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Hồ sơ của bạn',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 19),
                  ),
                  if (user?.email != null)
                    Text(
                      user!.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('edit-profile'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                minimumSize: const Size(46, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Sửa'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              const DesignIllustration('water', size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user?.healthGoal?.label ?? 'Chọn mục tiêu khi bạn sẵn sàng',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (user?.healthGoal?.needsTargetWeight == true) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: WeightGoalTrack(
                    metrics:
                        firstWeight.isLoading ||
                            firstWeight.hasError ||
                            latestWeight.isLoading ||
                            latestWeight.hasError
                        ? []
                        : <String, BodyMetric>{
                            for (final item in [
                              ...?firstWeight.value,
                              ...?latestWeight.value,
                            ])
                              item.id: item,
                          }.values.toList(),
                    target: user?.targetWeightKg,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        DailyMacroReflection(
          totals: totals,
          complete: complete,
          onReview: () => openDayReview(context, today),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final columns =
                c.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? 1
                : 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: (c.maxWidth - 12 * (columns - 1)) / columns,
                    child: card,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class DailyMacroReflection extends StatelessWidget {
  const DailyMacroReflection({
    required this.totals,
    required this.complete,
    required this.onReview,
    super.key,
  });
  final NutritionTotals? totals;
  final bool? complete;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    onTap: onReview,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nhìn lại hôm nay',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 21),
        ),
        const SizedBox(height: 12),
        MacroDistribution(
          totals: totals,
          extra: (
            label: 'Đủ bữa',
            value: complete == null
                ? '—'
                : complete!
                ? 'Đã ghi'
                : 'Chưa',
            color: ReferencePalette.carb,
          ),
        ),
      ],
    ),
  );
}

// The curve follows water events from this day; it does not invent earlier days.
List<double> cumulativeWater(List<WaterLog> logs) {
  final sorted = [...logs]
    ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
  var total = 0.0;
  return sorted.map((log) {
    total += log.amountMl;
    return total;
  }).toList();
}

class WeightGoalTrack extends StatelessWidget {
  const WeightGoalTrack({
    required this.metrics,
    required this.target,
    super.key,
  });
  final List<BodyMetric> metrics;
  final double? target;
  @override
  Widget build(BuildContext context) {
    final sorted = [...metrics]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final baseline = sorted.isEmpty ? null : sorted.first.weightKg;
    final latest = sorted.isEmpty ? null : sorted.last.weightKg;
    final distance = baseline == null || target == null
        ? null
        : baseline - target!;
    final progress =
        distance == null || distance == 0 || latest == null || sorted.length < 2
        ? null
        : ((baseline! - latest) / distance).clamp(0.0, 1.0);
    final label = progress == null
        ? 'Chưa đủ lần cân để tính tiến độ mục tiêu'
        : 'Tiến độ so với lần cân đầu tiên đã ghi: ${(progress * 100).round()}%';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress ?? 0,
            minHeight: 6,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}
