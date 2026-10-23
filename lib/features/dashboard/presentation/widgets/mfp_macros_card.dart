import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';
import '../../../nutrition/models/nutrition_models.dart';

class MfpMacrosCard extends StatefulWidget {
  const MfpMacrosCard({required this.totals, super.key});
  final NutritionTotals? totals;
  @override
  State<MfpMacrosCard> createState() => _MfpMacrosCardState();
}

class _MfpMacrosCardState extends State<MfpMacrosCard> {
  bool _percent = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final totals = widget.totals;
    final energy = totals == null
        ? 0.0
        : totals.carbsG * 4 + totals.fatG * 9 + totals.proteinG * 4;
    final complete = totals?.hasCompleteMacros ?? false;
    final rows = [
      (
        'Tinh bột',
        totals?.carbsG,
        totals?.carbsKnown ?? false,
        4,
        dark ? const Color(0xFF7BD1CF) : const Color(0xFF176B6A),
      ),
      (
        'Béo',
        totals?.fatG,
        totals?.fatKnown ?? false,
        9,
        dark ? const Color(0xFFCC9BE8) : const Color(0xFF763C98),
      ),
      (
        'Đạm',
        totals?.proteinG,
        totals?.proteinKnown ?? false,
        4,
        dark ? const Color(0xFFFFCB7C) : const Color(0xFF8A510A),
      ),
    ];
    Widget column(int i) {
      final r = rows[i];
      final known = totals != null && r.$3;
      final canPercent = complete && energy > 0;
      final value = !known || (_percent && !canPercent)
          ? '—'
          : _percent
          ? '${NumberFormat('0', 'vi').format(r.$2! * r.$4 / energy * 100)}%'
          : '${NumberFormat('0.#', 'vi').format(r.$2)} g';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.$1, style: theme.textTheme.bodyMedium?.copyWith(color: r.$5)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Dinh dưỡng', style: theme.textTheme.titleSmall),
              ),
              const InformationButton(
                title: 'Cách đọc dinh dưỡng',
                message:
                    'Số gram lấy từ các món đã ghi. Thanh màu thể hiện tỷ lệ năng lượng từ tinh bột, béo và đạm. Bấm nút đổi đơn vị để xem gram hoặc phần trăm. Dấu — là chưa đủ dữ liệu, không phải 0.',
              ),
              IconButton(
                key: const ValueKey('toggle-macro-unit'),
                tooltip: _percent
                    ? 'Hiển thị gram'
                    : 'Hiển thị tỷ lệ năng lượng',
                onPressed: () => setState(() => _percent = !_percent),
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, c) {
              final stacked =
                  c.maxWidth < 250 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(
                      width: stacked ? c.maxWidth : (c.maxWidth - 24) / 3,
                      child: column(i),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: complete && energy > 0
                    ? [
                        for (final r in rows)
                          if (r.$2! > 0)
                            Expanded(
                              flex: (r.$2! * r.$4 / energy * 10000)
                                  .round()
                                  .clamp(1, 10000),
                              child: ColoredBox(
                                color: r.$5,
                                child: const SizedBox.expand(),
                              ),
                            ),
                      ]
                    : [
                        Expanded(
                          child: ColoredBox(
                            color: theme.scaffoldBackgroundColor,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
              ),
            ),
          ),
          if (!complete || (_percent && energy == 0)) ...[
            const SizedBox(height: 10),
            Text(
              !complete ? 'Chưa đủ số liệu' : 'Chưa tính được tỷ lệ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
