import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../journal/presentation/daily_log_section_card.dart';
import '../models/activity_log.dart';

class ActivityLogSection extends StatelessWidget {
  const ActivityLogSection({
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
    super.key,
  });

  final AsyncValue<List<ActivityLog>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final ValueChanged<ActivityLog> onEdit;
  final ValueChanged<ActivityLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final logs = state.value ?? const <ActivityLog>[];
    final total = totalActivityMinutes(logs);
    final number = NumberFormat.decimalPattern('vi_VN');
    return DailyLogSectionCard<ActivityLog>(
      icon: Icons.directions_walk_outlined,
      title: 'Vận động',
      summary: '${number.format(total)} phút',
      description:
          'Do bạn nhập; ứng dụng chưa đo bước chân hoặc tự tính calories tiêu hao.',
      addKey: const ValueKey('add-activity'),
      addLabel: 'Ghi hoạt động',
      state: state,
      action: action,
      onAdd: onAdd,
      onRetry: onRetry,
      onDismissError: onDismissError,
      emptyText: 'Chưa có hoạt động nào trong ngày này.',
      children: [
        for (final log in logs)
          ListTile(
            key: ValueKey('activity-log-${log.id}'),
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.directions_walk_outlined),
            ),
            title: Text(
              '${log.type.label} · ${number.format(log.durationMinutes)} phút',
            ),
            subtitle: Text(
              '${DateFormat('HH:mm').format(log.performedAt)}'
              '${log.note.isEmpty ? '' : '\n${log.note}'}',
            ),
            trailing: DailyLogEntryMenu(
              onEdit: () => onEdit(log),
              onDelete: () => onDelete(log),
            ),
          ),
      ],
    );
  }
}
