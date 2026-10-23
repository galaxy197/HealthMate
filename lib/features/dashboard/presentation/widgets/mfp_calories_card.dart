import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';

class MfpCaloriesCard extends StatelessWidget {
  const MfpCaloriesCard({
    required this.consumed,
    this.target,
    this.onEditTarget,
    this.targetStatus,
    this.editKey,
    super.key,
  });
  final double? consumed;
  final double? target;
  final VoidCallback? onEditTarget;
  final String? targetStatus;
  final Key? editKey;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0', 'vi');
    final validTarget = target != null && target!.isFinite && target! > 0;
    final remaining = validTarget && consumed != null
        ? target! - consumed!
        : null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Năng lượng', style: theme.textTheme.titleMedium),
              ),
              if (onEditTarget != null)
                IconButton(
                  key: editKey,
                  tooltip: 'Mục tiêu dinh dưỡng',
                  onPressed: onEditTarget,
                  icon: const Icon(Icons.tune_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                '${consumed == null ? '—' : number.format(consumed)} kcal đã ghi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (remaining != null)
                Text(
                  '${remaining >= 0 ? 'Còn lại' : 'Đã vượt'} ${number.format(remaining.abs())} kcal',
                  style: theme.textTheme.titleSmall,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (validTarget) ...[
            Text(
              'Mục tiêu ${number.format(target)} kcal',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: consumed == null
                  ? ColoredBox(
                      color: theme.scaffoldBackgroundColor,
                      child: const SizedBox(height: 10),
                    )
                  : LinearProgressIndicator(
                      value: (consumed! / target!).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
            ),
          ] else
            Text(
              targetStatus ?? 'Chưa đặt mục tiêu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (consumed == null) const Text('Chưa có tổng nhật ký'),
        ],
      ),
    );
  }
}
