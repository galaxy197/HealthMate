import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/weight_chart.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';

typedef TrendPoint = ({DateTime date, double? value});

/// Displays only recorded values; an absent observation stays distinct from zero.
class ProgressOverview extends StatelessWidget {
  const ProgressOverview({
    required this.reflection,
    required this.tab,
    super.key,
  });
  final WeeklyReflection reflection;
  final int tab;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blue = Theme.of(context).colorScheme.primary;
    final carbs = dark ? const Color(0xFF7BD1CF) : const Color(0xFF176B6A);
    final fat = dark ? const Color(0xFFCC9BE8) : const Color(0xFF763C98);
    final protein = dark ? const Color(0xFFFFCB7C) : const Color(0xFF8A510A);
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
        if (!reflection.hasLogs)
          const Text(
            'Chưa có nhật ký bữa ăn, nước hoặc vận động trong tuần này.',
          ),
        Text(
          'Chỉ tổng hợp nhật ký đã ghi. Ngày trống không được tính là 0 khi lấy trung bình.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final card in cards) ...[card, const SizedBox(height: 16)],
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
    super.key,
  });
  final String title, unit;
  final Color color;
  final List<TrendPoint> points;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = points.where((p) => p.value != null).toList();
    final average = recorded.isEmpty
        ? null
        : recorded.fold(0.0, (v, p) => v + p.value!) / recorded.length;
    final maximum =
        recorded.fold(1.0, (v, p) => p.value! > v ? p.value! : v) * 1.1;
    final number = NumberFormat('0.#', 'vi');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            average == null
                ? 'Chưa có dữ liệu đã ghi'
                : '${number.format(average)} $unit',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Trung bình ${recorded.length} ngày có dữ liệu',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label:
                '$title. ${points.map((p) => '${DateFormat('dd/MM').format(p.date)}: ${p.value == null ? 'chưa ghi' : '${number.format(p.value)} $unit'}').join('. ')}',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 170 + MediaQuery.textScalerOf(context).scale(24),
                child: BarChart(
                  key: title == 'Năng lượng'
                      ? const ValueKey('weekly-chart')
                      : null,
                  BarChartData(
                    maxY: maximum,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
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
                          reservedSize:
                              MediaQuery.textScalerOf(context).scale(26) + 10,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) {
                              return const SizedBox.shrink();
                            }
                            final weekday = points[i].date.weekday;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weekday == 7 ? 'CN' : 'T${weekday + 1}',
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final p = points[group.x];
                          return BarTooltipItem(
                            '${DateFormat('dd/MM').format(p.date)}\n${p.value == null ? 'Chưa ghi' : '${number.format(p.value)} $unit'}',
                            TextStyle(color: theme.colorScheme.onSurface),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (final entry in points.indexed)
                        BarChartGroupData(
                          x: entry.$1,
                          barRods: [
                            BarChartRodData(
                              toY: entry.$2.value ?? 0,
                              width: 18,
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maximum,
                                color: theme.scaffoldBackgroundColor,
                              ),
                            ),
                          ],
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
