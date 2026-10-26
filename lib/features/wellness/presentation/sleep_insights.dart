import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../reports/models/period_report.dart';
import '../models/sleep_summary.dart';
import '../models/wellness_models.dart';
import '../providers/energy_providers.dart';
import '../providers/sleep_insight_providers.dart';
import '../providers/wellness_providers.dart';
import 'energy_panel.dart';

class SleepInsights extends ConsumerStatefulWidget {
  const SleepInsights({super.key});
  @override
  ConsumerState<SleepInsights> createState() => _SleepInsightsState();
}

class _SleepInsightsState extends ConsumerState<SleepInsights> {
  int days = 7;
  @override
  Widget build(BuildContext context) {
    final today = ref.watch(localClockProvider),
        range = ReportRange(
          DateTime(today.year, today.month, today.day + 1),
          days,
        );
    final data = ref.watch(sleepRangeProvider(range)),
        prefs = ref.watch(wellnessPreferencesProvider);
    return Card(
      key: const ValueKey('sleep-insights'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xu hướng giờ ngủ tự ghi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final n in [7, 30])
                  ChoiceChip(
                    key: ValueKey('sleep-window-$n'),
                    label: Text('$n ngày'),
                    selected: n == days,
                    onSelected: (_) => setState(() => days = n),
                  ),
              ],
            ),
            Text(
              '${DateFormat('dd/MM/yyyy').format(range.start)} – ${DateFormat('dd/MM/yyyy').format(today)}',
            ),
            if (prefs.isLoading) const LinearProgressIndicator(),
            if (prefs.hasError)
              TextButton(
                onPressed: () => ref.invalidate(wellnessPreferencesProvider),
                child: const Text('Chưa tải mục tiêu ngủ · Thử lại'),
              ),
            if (!prefs.isLoading && !prefs.hasError)
              TextButton(
                key: const ValueKey('configure-sleep-goal'),
                onPressed: () =>
                    openWellnessPreferences(context, ref, prefs.value!),
                child: const Text('Đặt mục tiêu giờ ngủ'),
              ),
            data.when(
              skipLoadingOnReload: false,
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                children: [
                  const Text('Chưa tải đủ giờ ngủ; chưa tính trung bình.'),
                  TextButton(
                    onPressed: () => ref.invalidate(sleepRangeProvider(range)),
                    child: const Text('Thử lại giờ ngủ'),
                  ),
                ],
              ),
              data: (logs) {
                final s = summarizeSleep(
                  logs,
                  range.start,
                  days,
                  goalMinutes: !prefs.isLoading && !prefs.hasError
                      ? prefs.value?.sleepGoalMinutes
                      : null,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Có ghi nhận ${s.recorded.length}/$days ngày · tính theo ngày thức dậy',
                    ),
                    if (s.inconsistentDays > 0)
                      Text(
                        '${s.inconsistentDays} ngày có khoảng ghi vượt 24 giờ; hãy sửa giờ. Những ngày này chưa được đưa vào trung bình.',
                      ),
                    Text(
                      s.averageMinutes == null
                          ? 'Chưa có dữ liệu để tính trung bình.'
                          : 'Trung bình ngày có ghi: ${energyNumber(s.averageMinutes! / 60)} giờ',
                    ),
                    if (s.goalMinutes != null)
                      Text(
                        'Mục tiêu tự đặt: ${energyNumber(s.goalMinutes! / 60)} giờ · đạt ở ${s.daysAtGoal}/${s.recorded.length} ngày có dữ liệu',
                      ),
                    Text(
                      s.bedtimeVariationMinutes == null
                          ? 'Cần ít nhất hai ngày có dữ liệu để xem độ đều giờ ngủ.'
                          : 'Lệch giờ đi ngủ trung bình: khoảng ${s.bedtimeVariationMinutes!.round()} phút so với giờ đi ngủ trung tâm.',
                    ),
                    if (s.recorded.isNotEmpty)
                      SizedBox(height: 180, child: _SleepChart(s)),
                    const Text(
                      'Ngày thiếu để trống, không tính là 0 giờ. Khoảng ghi chồng lắp được gộp; giấc ngắn cộng thời lượng, giấc chính dùng so giờ đi ngủ. Không đánh giá giai đoạn/chất lượng ngủ hoặc tự đổi calo.',
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(sleepRangeProvider(range)),
                      child: const Text('Cập nhật biểu đồ ngủ'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepChart extends StatelessWidget {
  const _SleepChart(this.summary);
  final SleepSummary summary;
  @override
  Widget build(BuildContext context) => BarChart(
    BarChartData(
      minY: 0,
      maxY: math.max(
        10,
        summary.recorded.fold(0.0, (s, d) => math.max(s, d.minutes! / 60)) + 1,
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, index, rod, rodIndex) {
            final d = summary.days[index];
            return BarTooltipItem(
              '${DateFormat('dd/MM').format(d.day)}\n${d.minutes == null ? 'Chưa ghi' : '${energyNumber(d.minutes! / 60)} giờ'}',
              TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          axisNameWidget: Text('Giờ'),
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              if (i < 0 ||
                  i >= summary.days.length ||
                  (summary.days.length > 7 && i % 5 != 0)) {
                return const SizedBox.shrink();
              }
              return Text(
                '${summary.days[i].day.day}',
                style: Theme.of(context).textTheme.labelSmall,
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (final e in summary.days.indexed)
          BarChartGroupData(
            x: e.$1,
            barRods: [
              BarChartRodData(
                toY: (e.$2.minutes ?? 0) / 60,
                width: summary.days.length > 7 ? 5 : 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
      ],
    ),
  );
}

class BedtimeReminderPanel extends ConsumerStatefulWidget {
  const BedtimeReminderPanel({super.key});
  @override
  ConsumerState<BedtimeReminderPanel> createState() =>
      _BedtimeReminderPanelState();
}

class _BedtimeReminderPanelState extends ConsumerState<BedtimeReminderPanel> {
  bool busy = false;
  String? message;
  Future<void> save(SleepReminder value) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ref.read(localWellnessProvider.notifier).saveSleepReminder(value);
    } catch (_) {
      if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
        setState(
          () => message =
              'Chưa lưu được lời nhắc. Kiểm tra quyền thông báo và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localWellnessProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: state.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(localWellnessProvider),
            child: const Text('Thử tải lời nhắc ngủ'),
          ),
          data: (s) {
            if (!s.available) {
              return const Text('Nhắc giờ ngủ hỗ trợ trên Android.');
            }
            final r = s.sleepReminder,
                time = TimeOfDay(
                  hour: s.sleepReminder.minute ~/ 60,
                  minute: s.sleepReminder.minute % 60,
                );
            return Column(
              children: [
                SwitchListTile(
                  key: const ValueKey('bedtime-enabled'),
                  title: const Text('Nhắc giờ ngủ trên máy này'),
                  subtitle: Text(time.format(context)),
                  value: r.enabled,
                  onChanged: busy
                      ? null
                      : (v) =>
                            save(SleepReminder(enabled: v, minute: r.minute)),
                ),
                TextButton(
                  key: const ValueKey('bedtime-time'),
                  onPressed: busy
                      ? null
                      : () async {
                          final uid = ref.read(authSessionProvider).value?.uid;
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: time,
                            builder: (_, child) =>
                                AccountBoundDialog(child: child!),
                          );
                          if (selected != null &&
                              mounted &&
                              uid != null &&
                              ref.read(authSessionProvider).value?.uid == uid) {
                            await save(
                              SleepReminder(
                                enabled: r.enabled,
                                minute: selected.hour * 60 + selected.minute,
                              ),
                            );
                          }
                        },
                  child: const Text('Chọn giờ nhắc ngủ'),
                ),
                if (r.enabled)
                  TextButton(
                    key: const ValueKey('test-bedtime'),
                    onPressed: busy
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(wellnessDeviceProvider)
                                  .testSleepReminder(s.uid!);
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => message =
                                      'Chưa hiển thị được thông báo. Kiểm tra quyền Android.',
                                );
                              }
                            }
                          },
                    child: const Text('Thử thông báo giờ ngủ'),
                  ),
                const Text(
                  'Thông báo cục bộ có thể trễ do tiết kiệm pin; đây không phải báo thức. Bạn tự chọn giờ và có thể tắt bất cứ lúc nào.',
                ),
                if (busy) const LinearProgressIndicator(),
                if (message != null) Text(message!),
              ],
            );
          },
        ),
      ),
    );
  }
}
