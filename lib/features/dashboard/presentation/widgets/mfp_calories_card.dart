import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';
import '../../../../core/widgets/design_illustration.dart';
import '../../../../core/theme/reference_palette.dart';

class MfpCaloriesCard extends StatelessWidget {
  const MfpCaloriesCard({
    required this.consumed,
    this.target,
    this.onEditTarget,
    this.targetStatus,
    this.editKey,
    this.budgetNote,
    this.onPersonalize,
    this.macros,
    super.key,
  });
  final double? consumed, target;
  final VoidCallback? onEditTarget, onPersonalize;
  final String? targetStatus, budgetNote;
  final Key? editKey;
  final Widget? macros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0', 'vi');
    final validTarget = target != null && target!.isFinite && target! > 0;
    final remaining = validTarget && consumed != null
        ? target! - consumed!
        : null;
    final muted = theme.colorScheme.onSurfaceVariant;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              const Center(child: DesignIllustration('flame', size: 96)),
              const SizedBox(height: 30),
              Text(
                consumed == null ? '—' : number.format(consumed),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 35,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                  color: theme.brightness == Brightness.light
                      ? ReferencePalette.blue
                      : theme.colorScheme.primary,
                ),
              ),
              Text(
                validTarget
                    ? 'kcal đã ghi / ${number.format(target)} kcal'
                    : 'kcal đã ghi',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: validTarget && consumed != null
                        ? (consumed! / target!).clamp(0, 1)
                        : 0,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (onPersonalize != null)
                TextButton(
                  key: const ValueKey('open-personal-nutrition'),
                  onPressed: onPersonalize,
                  child: const Text('Chưa đặt mục tiêu'),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    remaining != null
                        ? '${remaining >= 0 ? 'Còn lại' : 'Đã vượt'} ${number.format(remaining.abs())} kcal'
                        : targetStatus ??
                              (consumed == null
                                  ? 'Chưa có tổng nhật ký'
                                  : 'Chưa đặt mục tiêu'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (budgetNote != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Text(budgetNote!, style: theme.textTheme.bodySmall),
                ),
              if (macros != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: macros!,
                ),
              ],
            ],
          ),
          if (macros != null)
            const Positioned(
              left: 4,
              top: 4,
              child: InformationButton(
                title: 'Cách đọc dinh dưỡng',
                message:
                    'Vòng màu thể hiện tiến độ theo mục tiêu gram của bạn. Chạm vào các vòng để đổi gram/phần trăm năng lượng. Dấu — là chưa đủ dữ liệu, không phải 0.',
              ),
            ),
          if (onEditTarget != null)
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                key: editKey,
                tooltip: 'Mục tiêu dinh dưỡng',
                onPressed: onEditTarget,
                icon: const Icon(Icons.tune_rounded, size: 19),
              ),
            ),
        ],
      ),
    );
  }
}
