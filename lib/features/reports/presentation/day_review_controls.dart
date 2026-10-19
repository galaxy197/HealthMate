import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../models/period_report.dart';
import '../providers/report_providers.dart';

Future<void> openDayReview(BuildContext context, DateTime day) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AccountBoundDialog(child: DayReviewControls(day: day)),
    );

class DayReviewControls extends ConsumerStatefulWidget {
  const DayReviewControls({required this.day, super.key});
  final DateTime day;
  @override
  ConsumerState<DayReviewControls> createState() => _DayReviewControlsState();
}

class _DayReviewControlsState extends ConsumerState<DayReviewControls> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final range = ReportRange(
      DateTime(widget.day.year, widget.day.month, widget.day.day + 1),
      1,
    );
    final logs = ref.watch(mealLogsProvider(widget.day));
    final reviews = ref.watch(dayReviewsProvider(range));
    final ready =
        !logs.isLoading &&
        !logs.hasError &&
        !reviews.isLoading &&
        !reviews.hasError;
    final current = ready && reviews.value!.any((r) => r.matches(logs.value!));
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xác nhận nhật ký ${DateFormat('dd/MM/yyyy').format(widget.day)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Chỉ bạn biết đã ghi đủ bữa ăn và đồ uống có năng lượng hay chưa. Có một bữa không tự làm ngày hoàn tất. Xác nhận không làm chất dinh dưỡng còn thiếu trở thành đã biết; ngày trống vẫn không được coi là 0 kcal đã ăn.',
            ),
            if (!ready) ...[
              if (logs.isLoading || reviews.isLoading)
                const LinearProgressIndicator()
              else
                const Text(
                  'Chưa tải đủ nhật ký/trạng thái; chưa thể xác nhận.',
                ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        ref.invalidate(mealLogsProvider(widget.day));
                        ref.invalidate(dayReviewsProvider(range));
                      },
                child: const Text('Thử tải lại'),
              ),
            ],
            if (ready)
              Text(
                current
                    ? 'Bạn đã xác nhận đủ bữa ăn.'
                    : 'Chưa xác nhận hoặc nhật ký đã thay đổi; hãy kiểm tra lại.',
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              key: const ValueKey('confirm-day-review'),
              onPressed: !ready || _busy
                  ? null
                  : () async {
                      final uid = ref.read(authSessionProvider).value?.uid;
                      if (uid == null) return;
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        await ref
                            .read(dayReviewRepositoryProvider)
                            .save(
                              uid,
                              widget.day,
                              logs.value!,
                              complete: !current,
                            );
                        if (!context.mounted ||
                            ref.read(authSessionProvider).value?.uid != uid) {
                          return;
                        }
                        ref.invalidate(dayReviewsProvider);
                        Navigator.pop(context);
                      } catch (_) {
                        if (mounted &&
                            ref.read(authSessionProvider).value?.uid == uid) {
                          setState(
                            () => _error =
                                'Chưa lưu được xác nhận. Giữ nhật ký và thử lại khi có kết nối/quyền phù hợp.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(
                _busy
                    ? 'Đang chờ máy chủ…'
                    : current
                    ? 'Chuyển về đang ghi'
                    : 'Tôi đã ghi đủ bữa ăn trong ngày',
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    );
  }
}
