import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class JournalDateSelector extends StatelessWidget {
  const JournalDateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    super.key,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('journal-previous-day'),
              onPressed: onPrevious,
              tooltip: 'Ngày trước',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('journal-pick-date'),
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  locale.formatFullDate(date),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('journal-next-day'),
              onPressed: onNext,
              tooltip: 'Ngày sau',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
