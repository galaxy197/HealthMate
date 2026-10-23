import '../../../core/widgets/tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../data_export/presentation/journal_export_dialog.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';
import '../../weekly_reflection/providers/weekly_reflection_providers.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';
import '../../reports/presentation/period_report_panel.dart';
import 'progress_overview.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _days = 7;
  int _tab = 0;
  int _offset = 0;
  bool _details = false;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final today = ref.watch(localClockProvider);
    final monday = weekStart(today);
    final start = DateTime(monday.year, monday.month, monday.day + _offset * 7);
    final end = DateTime(start.year, start.month, start.day + 6);
    final theme = Theme.of(context);
    final state = _days == 7 && !_details
        ? ref.watch(weeklyLogsProvider(start))
        : null;
    return TrackingPage(
      key: const ValueKey('progress-screen'),
      header: Row(
        children: [
          Expanded(
            child: Text(
              'Tiến độ',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('progress-export'),
            tooltip: 'Xuất nhật ký CSV',
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  const AccountBoundDialog(child: JournalExportDialog()),
            ),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 16),
        if (_days == 7)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in [
                  'Tổng quan',
                  'Năng lượng',
                  'Dưỡng chất',
                  'Macro',
                ].indexed)
                  InkWell(
                    key: ValueKey('progress-tab-${entry.$1}'),
                    onTap: () => setState(() {
                      _tab = entry.$1;
                      _details = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tab == entry.$1 && !_details
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        entry.$2,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: _tab == entry.$1
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final days in [7, 30, 90])
              ChoiceChip(
                key: ValueKey('report-window-$days'),
                selected: _days == days,
                label: Text(days == 7 ? 'Tuần' : '$days ngày'),
                onSelected: (_) => setState(() => _days = days),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_days != 7)
          PeriodReportPanel(days: _days, today: today)
        else if (_details)
          WeeklyReflectionCard(today: today, progressMode: true)
        else ...[
          Row(
            children: [
              IconButton(
                key: const ValueKey('previous-week'),
                tooltip: 'Tuần trước',
                onPressed: () => setState(() => _offset--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${DateFormat('dd/MM/yyyy').format(start)} – ${DateFormat('dd/MM/yyyy').format(end)}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const ValueKey('next-week'),
                tooltip: 'Tuần sau',
                onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          state!.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            skipError: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Column(
              children: [
                const Text(
                  'Chưa tải đủ dữ liệu tuần. Không tính tổng từ dữ liệu thiếu.',
                ),
                TextButton(
                  key: const ValueKey('retry-progress-overview'),
                  onPressed: () => ref.invalidate(weeklyLogsProvider(start)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
            data: (logs) => ProgressOverview(
              reflection: summarizeWeek(start, today, logs),
              tab: _tab,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_days == 7)
          OutlinedButton.icon(
            key: const ValueKey('progress-details'),
            onPressed: () => setState(() => _details = !_details),
            icon: Icon(_details ? Icons.bar_chart : Icons.table_rows_outlined),
            label: Text(
              _details ? 'Trở về biểu đồ' : 'Chi tiết từng ngày / Mục tiêu',
            ),
          ),
        const SizedBox(height: 24),
        const HealthDisclaimer(),
      ],
    );
  }
}
