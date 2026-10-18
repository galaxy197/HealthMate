import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the week selector's state across tabs; its card releases remote reads
    // while hidden. This clock is local and does not open Firebase listeners.
    final today = ref.watch(localClockProvider);
    return FeaturePage(
      key: const ValueKey('progress-screen'),
      title: 'Tiến độ',
      subtitle:
          'Nhìn lại số liệu đã ghi theo tuần. Giờ thiết bị: ${today.timeZoneName}.',
      children: [WeeklyReflectionCard(today: today, progressMode: true)],
    );
  }
}
