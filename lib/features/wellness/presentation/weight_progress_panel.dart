import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';
import '../../profile/presentation/weight_chart.dart';
import '../../reports/models/period_report.dart';
import '../../reports/providers/report_providers.dart';
import '../providers/wellness_providers.dart';
import 'energy_panel.dart';

class WeightProgressPanel extends ConsumerStatefulWidget {
  const WeightProgressPanel({super.key});
  @override
  ConsumerState<WeightProgressPanel> createState() =>
      _WeightProgressPanelState();
}

class _WeightProgressPanelState extends ConsumerState<WeightProgressPanel> {
  int days = 30;
  @override
  Widget build(BuildContext context) {
    final today = localDateOnly(ref.watch(localClockProvider)),
        profile = ref.watch(userProfileProvider);
    final range = ReportRange(
      DateTime(today.year, today.month, today.day + 1),
      days,
    );
    final metrics = ref.watch(periodMetricsProvider(range)),
        meals = ref.watch(periodMealsProvider(range)),
        steps = ref.watch(stepHistoryProvider);
    final latest = ref.watch(latestBodyMetricProvider(today));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tiến độ mục tiêu cân nặng',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'Kết nối mục tiêu ăn, bữa đã ghi, bước chân và xu hướng cân nặng. Không suy số kg mỡ từ kcal hoặc từ thay đổi cân ngắn hạn.',
        ),
        EnergyBudgetCard(day: today),
        TextButton(
          onPressed: () => context.go(AppRoutes.profile),
          child: const Text('Cập nhật cân nặng hoặc mục tiêu trong Hồ sơ'),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final n in [7, 30, 90])
              ChoiceChip(
                key: ValueKey('weight-window-$n'),
                label: Text('$n ngày'),
                selected: days == n,
                onSelected: (_) => setState(() => days = n),
              ),
          ],
        ),
        if (profile.isLoading || latest.isLoading)
          const LinearProgressIndicator(),
        if (profile.hasError || latest.hasError)
          TextButton(
            onPressed: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(latestBodyMetricProvider(today));
            },
            child: const Text('Chưa tải đủ hồ sơ/cân nặng · Thử lại'),
          ),
        if (!profile.isLoading &&
            !profile.hasError &&
            !latest.isLoading &&
            !latest.hasError) ...[
          Text(
            'Mục tiêu hồ sơ: ${profile.value?.healthGoal?.label ?? 'Chưa đặt'}',
          ),
          Text(
            profile.value?.targetWeightKg == null
                ? 'Chưa đặt cân nặng mục tiêu trong Hồ sơ.'
                : 'Cân nặng mục tiêu: ${energyNumber(profile.value!.targetWeightKg!)} kg',
          ),
          Text(
            latest.value!.isEmpty
                ? 'Chưa ghi cân nặng.'
                : 'Gần nhất: ${energyNumber(latest.value!.first.weightKg)} kg · ${DateFormat('dd/MM/yyyy').format(latest.value!.first.measuredAt)}',
          ),
          if (profile.value?.targetWeightKg != null && latest.value!.isNotEmpty)
            Text(
              'Chênh so mục tiêu: ${energyNumber(latest.value!.first.weightKg - profile.value!.targetWeightKg!)} kg',
            ),
        ],
        metrics.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(periodMetricsProvider(range)),
            child: const Text('Thử tải xu hướng cân nặng'),
          ),
          data: (items) {
            final sorted = [...items]
              ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sorted.length < 2)
                  const Text(
                    'Cần ít nhất hai lần cân trong khoảng đã chọn để xem thay đổi.',
                  )
                else
                  Text(
                    'Thay đổi trong khoảng: ${energyNumber(sorted.last.weightKg - sorted.first.weightKg)} kg',
                  ),
                if (sorted.isNotEmpty) WeightChart(metrics: sorted),
                for (final group in weeklyWeightAverages(sorted).entries)
                  Text(
                    'Tuần từ ${group.key}: trung bình ${energyNumber(group.value)} kg',
                  ),
                const Text(
                  'Trung bình tuần chỉ dùng những ngày có cân; nhiều lần cùng ngày được lấy trung bình trước để không làm lệch trọng số.',
                ),
              ],
            );
          },
        ),
        meals.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(periodMealsProvider(range)),
            child: const Text('Thử tải số ngày ghi bữa'),
          ),
          data: (items) {
            final covered = items
                .map((m) => m.dateKey ?? localDateKey(m.consumedAt.toLocal()))
                .toSet()
                .length;
            return Text(
              'Có ghi bữa trong $covered/$days ngày; ngày thiếu không coi là ăn 0 kcal.',
            );
          },
        ),
        steps.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(stepHistoryProvider),
            child: const Text('Thử tải lịch sử bước'),
          ),
          data: (items) {
            final known = items
                .where(
                  (d) =>
                      d.day.compareTo(localDateKey(range.start)) >= 0 &&
                      d.day.compareTo(localDateKey(range.end)) < 0,
                )
                .toList();
            return Text(
              known.isEmpty
                  ? 'Chưa có bước chân đồng bộ trong khoảng.'
                  : 'Bước đã đồng bộ: ${known.fold(0, (s, d) => s + d.steps)} bước / ${known.length} ngày có dữ liệu (lịch sử bước tải tối đa30 ngày).',
            );
          },
        ),
        const Text(
          'Theo dõi xu hướng nhiều ngày; app không tự tăng mức cắt giảm ăn khi cân chưa thay đổi.',
        ),
      ],
    );
  }
}

Map<String, double> weeklyWeightAverages(List<BodyMetric> values) {
  final byDay = <String, List<double>>{};
  for (final m in values) {
    byDay
        .putIfAbsent(localDateKey(m.measuredAt.toLocal()), () => [])
        .add(m.weightKg);
  }
  final byWeek = <String, List<double>>{};
  for (final e in byDay.entries) {
    final d = DateTime.parse(e.key),
        monday = DateTime(d.year, d.month, d.day - d.weekday + 1);
    byWeek
        .putIfAbsent(localDateKey(monday), () => [])
        .add(e.value.reduce((a, b) => a + b) / e.value.length);
  }
  final keys = byWeek.keys.toList()..sort();
  return {
    for (final key in keys)
      key: byWeek[key]!.reduce((a, b) => a + b) / byWeek[key]!.length,
  };
}
