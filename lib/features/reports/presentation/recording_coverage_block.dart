import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/period_report.dart';
import '../providers/report_providers.dart';

class RecordingCoverageBlock extends ConsumerWidget {
  const RecordingCoverageBlock({
    required this.range,
    required this.today,
    required this.meals,
    super.key,
  });
  final ReportRange range;
  final DateTime today;
  final List<MealLog> meals;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dayReviewsProvider(range))
      .when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        skipError: false,
        loading: () => const Text(
          'Đang tải xác nhận ngày; chưa tính trung bình ngày đủ bữa.',
        ),
        error: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chưa tải được xác nhận ngày. Tổng đã ghi vẫn được giữ.',
            ),
            TextButton(
              onPressed: () => ref.invalidate(dayReviewsProvider(range)),
              child: const Text('Thử lại xác nhận ngày'),
            ),
          ],
        ),
        data: (reviews) {
          final c = RecordingCoverage(
            range: range,
            today: today,
            meals: meals,
            reviews: reviews,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${c.confirmedRecordedDays} ngày có bữa đã xác nhận · ${c.partialDays} ngày đang ghi · ${c.unrecordedDays} ngày chưa ghi bữa / ${c.dates.length} ngày đã tới.',
              ),
              Text(
                c.confirmedAverageKcal == null
                    ? 'Chưa có ngày có bữa đã xác nhận để tính trung bình.'
                    : 'Trung bình ${NumberFormat('0.#', 'vi').format(c.confirmedAverageKcal)} kcal / ${c.confirmedRecordedDays} ngày có bữa đã xác nhận. Không gồm ngày đang ghi.',
              ),
            ],
          );
        },
      );
}
