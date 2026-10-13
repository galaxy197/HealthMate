import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/body_metric.dart';

class WeightChart extends StatelessWidget {
  const WeightChart({required this.metrics, super.key});

  final List<BodyMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final ordered = metrics.take(12).toList(growable: false).reversed.toList();
    final weights = ordered.map((metric) => metric.weightKg);
    final minimum = weights.reduce(math.min);
    final maximum = weights.reduce(math.max);
    final minY = math.max(0, (minimum - 2).floorToDouble()).toDouble();
    final maxY = math.max(minY + 4, (maximum + 2).ceilToDouble()).toDouble();
    final number = NumberFormat('0.#', 'vi_VN');
    final date = DateFormat('d/M');
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Biểu đồ cân nặng từ ${number.format(ordered.first.weightKg)} đến ${number.format(ordered.last.weightKg)} kilogram',
      child: SizedBox(
        key: const ValueKey('weight-chart'),
        height: 220,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, ordered.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: math.max(1, (maxY - minY) / 4),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      number.format(value),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: ordered.length <= 5
                      ? 1
                      : (ordered.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= ordered.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        date.format(ordered[index].measuredAt),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final entry in ordered.indexed)
                    FlSpot(entry.$1.toDouble(), entry.$2.weightKg),
                ],
                isCurved: ordered.length > 2,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
