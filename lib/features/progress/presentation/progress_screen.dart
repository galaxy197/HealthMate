import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';
import '../../reports/presentation/period_report_panel.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _days = 7;
  @override
  Widget build(BuildContext context) {
    // Keep the week selector's state across tabs; its card releases remote reads
    // while hidden. This clock is local and does not open Firebase listeners.
    final today = ref.watch(localClockProvider);
    return FeaturePage(
      key: const ValueKey('progress-screen'),
      title: 'Tiến độ',
      subtitle: '',
      compactHeader: true,
      children: [
        Wrap(
          spacing: 8,
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
        if (_days == 7)
          WeeklyReflectionCard(today: today, progressMode: true)
        else
          PeriodReportPanel(days: _days, today: today),
      ],
    );
  }
}
