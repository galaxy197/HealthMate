import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/theme/reference_palette.dart';
import '../../profile/presentation/weight_chart.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';

typedef TrendPoint = ({DateTime date, double? value});

/// Displays only recorded values; an absent observation stays distinct from zero.
class ProgressOverview extends StatelessWidget {
  const ProgressOverview({
    required this.reflection,
    required this.tab,
    this.controls,
    this.confirmedDays,
    super.key,
  });
  final WeeklyReflection reflection;
  final int tab;
  final Widget? controls;
  final int? confirmedDays;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blue = Theme.of(context).colorScheme.primary;
    const carbs = ReferencePalette.carb;
    const fat = ReferencePalette.fat;
    const protein = ReferencePalette.protein;
    Widget trend(
      String label,
      String unit,
      Color color,
      double? Function(DayReflection) get,
      String id,
    ) => RecordedTrendCard(
      key: ValueKey('progress-trend-$id'),
      title: label,
      unit: unit,
      color: color,
      points: [
        for (final d in reflection.days)
          (date: d.date, value: d.isFuture ? null : get(d)),
      ],
      controls:
          id == 'kcal' ||
              (tab == 2 && id == 'water') ||
              (tab == 3 && id == 'carbs')
          ? controls
          : null,
      referenceHero: id == 'kcal',
    );
    final macroWidgets = [
      trend(
        'Tinh bột',
        'g',
        carbs,
        (d) => d.mealCount > 0 && d.nutrition.carbsKnown
            ? d.nutrition.carbsG
            : null,
        'carbs',
      ),
      trend(
        'Béo',
        'g',
        fat,
        (d) =>
            d.mealCount > 0 && d.nutrition.fatKnown ? d.nutrition.fatG : null,
        'fat',
      ),
      trend(
        'Đạm',
        'g',
        protein,
        (d) => d.mealCount > 0 && d.nutrition.proteinKnown
            ? d.nutrition.proteinG
            : null,
        'protein',
      ),
    ];
    final cards = <Widget>[
      if (tab == 0 || tab == 1)
        trend(
          'Năng lượng',
          'kcal',
          blue,
          (d) => d.mealCount > 0 ? d.nutrition.kcal : null,
          'kcal',
        ),
      if (tab == 0)
        AppCard(
          key: const ValueKey('progress-weight-overview'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cân nặng', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (reflection.metrics.isEmpty)
                const Text('Chưa có lần cân trong tuần này.')
              else ...[
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _WeightLabel('Đầu kỳ', reflection.metrics.first.weightKg),
                    _WeightLabel('Gần nhất', reflection.metrics.last.weightKg),
                    if (reflection.weightChange != null)
                      _WeightLabel('Thay đổi', reflection.weightChange!),
                  ],
                ),
                const SizedBox(height: 20),
                WeightChart(metrics: reflection.metrics.reversed.toList()),
                if (reflection.metrics.length == 1)
                  const Text('Một lần đo chưa đủ để mô tả xu hướng.'),
              ],
            ],
          ),
        ),
      if (tab == 0 || tab == 3) ...macroWidgets,
      if (tab == 2) ...[
        trend(
          'Nước',
          'ml',
          blue,
          (d) => d.waterCount > 0 ? d.waterMl.toDouble() : null,
          'water',
        ),
        trend(
          'Vận động',
          'phút',
          dark ? const Color(0xFF78D5A2) : const Color(0xFF17683C),
          (d) => d.activityCount > 0 ? d.activityMinutes.toDouble() : null,
          'activity',
        ),
        trend(
          'Chất xơ',
          'g',
          carbs,
          (d) => d.mealCount > 0 && d.nutrition.fiberKnown
              ? d.nutrition.fiberG
              : null,
          'fiber',
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!reflection.hasLogs && tab != 0 && tab != 1)
          const Text(
            'Chưa có nhật ký bữa ăn, nước hoặc vận động trong tuần này.',
          ),
        if (tab != 0 && tab != 1)
          Text(
            'Chỉ tổng hợp nhật ký đã ghi. Ngày trống không được tính là 0 khi lấy trung bình.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final card in cards.indexed) ...[
          card.$2,
          const SizedBox(height: 16),
          if (card.$1 == 0 && tab == 0) ...[
            Text(
              'Tổng kết trong tuần',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final columns = MediaQuery.textScalerOf(context).scale(1) > 1.4
                    ? 1
                    : 2;
                final entries = [
                  (
                    '${reflection.days.where((d) => d.hasLogs).length} / ${reflection.eligibleDays}',
                    'Ngày đã ghi nhật ký',
                  ),
                  (
                    '${confirmedDays ?? '—'} / ${reflection.eligibleDays}',
                    'Ngày xác nhận đủ bữa',
                  ),
                ];
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final e in entries)
                      SizedBox(
                        width: (c.maxWidth - 12 * (columns - 1)) / columns,
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.$1,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 28,
                                    ),
                              ),
                              const SizedBox(height: 45),
                              Text(
                                e.$2,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (!reflection.hasLogs)
              const Text(
                'Chưa có nhật ký bữa ăn, nước hoặc vận động trong tuần này.',
              ),
            const Text(
              'Chỉ tổng hợp nhật ký đã ghi. Ngày trống không được tính là 0 khi lấy trung bình.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _WeightLabel extends StatelessWidget {
  const _WeightLabel(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      Text(
        '${NumberFormat('0.#', 'vi').format(value)} kg',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}

class RecordedTrendCard extends StatelessWidget {
  const RecordedTrendCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.points,
    this.controls,
    this.referenceHero = false,
    super.key,
  });
  final String title, unit;
  final Color color;
  final List<TrendPoint> points;
  final Widget? controls;
  final bool referenceHero;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = points.where((p) => p.value != null).toList();
    final average = recorded.isEmpty
        ? null
        : recorded.fold(0.0, (v, p) => v + p.value!) / recorded.length;
    final maximum =
        recorded.fold(1.0, (v, p) => p.value! > v ? p.value! : v) * 1.1;
    final number = NumberFormat('#,##0.#', 'vi');
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!referenceHero)
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          if (!referenceHero) const SizedBox(height: 16),
          if (referenceHero)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              children: [
                Text(
                  average == null ? '—' : number.format(average),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'kcal / ngày đã ghi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          if (!referenceHero)
            Text(
              average == null
                  ? 'Chưa có dữ liệu đã ghi'
                  : '${number.format(average)} $unit',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (!referenceHero) const SizedBox(height: 6),
          if (!referenceHero)
            Text(
              'Trung bình ${recorded.length} ngày có dữ liệu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          ?controls,
          Semantics(
            label:
                '$title. ${points.map((p) => '${DateFormat('dd/MM').format(p.date)}: ${p.value == null ? 'chưa ghi' : '${number.format(p.value)} $unit'}').join('. ')}',
            child: ExcludeSemantics(
              child: SizedBox(
                height:
                    (referenceHero ? 150 : 170) +
                    MediaQuery.textScalerOf(context).scale(24),
                child: LineChart(
                  key: title == 'Năng lượng'
                      ? const ValueKey('weekly-chart')
                      : null,
                  LineChartData(
                    minX: 0,
                    maxX: points.length <= 1
                        ? 1
                        : (points.length - 1).toDouble(),
                    minY: 0,
                    maxY: maximum,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize:
                              MediaQuery.textScalerOf(context).scale(26) + 10,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 ||
                                i >= points.length ||
                                value != i.toDouble()) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd').format(points[i].date),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => theme.colorScheme.surface,
                        getTooltipItems: (spots) => spots.map((spot) {
                          final p = points[spot.x.round()];
                          return LineTooltipItem(
                            '${DateFormat('dd/MM').format(p.date)}\n${number.format(p.value)} $unit',
                            TextStyle(color: theme.colorScheme.onSurface),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (final entry in points.indexed)
                            entry.$2.value == null
                                ? FlSpot.nullSpot
                                : FlSpot(entry.$1.toDouble(), entry.$2.value!),
                        ],
                        color: color,
                        barWidth: 2.5,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: .22),
                              color.withValues(alpha: .01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
