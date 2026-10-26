import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/period_report.dart';

Future<ReportRange?> chooseReportRange(
  BuildContext context, {
  required DateTime today,
  ReportRange? initial,
}) => showDialog<ReportRange>(
  context: context,
  builder: (_) => ReportRangeDialog(today: today, initial: initial),
);

class ReportRangeDialog extends StatefulWidget {
  const ReportRangeDialog({required this.today, this.initial, super.key});
  final DateTime today;
  final ReportRange? initial;
  @override
  State<ReportRangeDialog> createState() => _ReportRangeDialogState();
}

class _ReportRangeDialogState extends State<ReportRangeDialog> {
  late DateTime _start, _last;
  late final TextEditingController _days;
  bool _byDays = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final range =
        widget.initial ??
        ReportRange(
          DateTime(widget.today.year, widget.today.month, widget.today.day + 1),
          30,
        );
    _start = range.start;
    _last = range.lastDay;
    _days = TextEditingController(text: range.days.toString());
  }

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  Future<void> _pick(bool first) async {
    final date = await showDatePicker(
      context: context,
      initialDate: first ? _start : _last,
      firstDate: DateTime(1900),
      lastDate: localDateOnly(widget.today),
      helpText: first ? 'Ngày bắt đầu' : 'Ngày kết thúc (tính cả ngày này)',
    );
    if (date == null || !mounted) return;
    setState(() {
      if (first) {
        _start = date;
      } else {
        _last = date;
      }
      _error = null;
    });
  }

  void _apply() {
    try {
      final ReportRange range;
      if (_byDays) {
        final count = int.tryParse(_days.text.trim());
        if (count == null || count < 1 || count > maxReportDays) {
          throw const RangeReadFailure('Nhập số ngày nguyên từ 1 đến 366.');
        }
        range = ReportRange(
          DateTime(_last.year, _last.month, _last.day + 1),
          count,
        );
        range.validate();
      } else {
        range = ReportRange.inclusive(_start, _last);
      }
      if (range.lastDay.isAfter(localDateOnly(widget.today))) {
        throw const RangeReadFailure('Chỉ xem dữ liệu đến hết hôm nay.');
      }
      Navigator.pop(context, range);
    } on RangeReadFailure catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Chọn khoảng báo cáo')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tối đa 366 ngày mỗi lượt, tính cả ngày bắt đầu và kết thúc. Dữ liệu cũ không tự bị xóa sau khoảng này.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('range-mode-dates'),
                    label: const Text('Từ ngày – đến ngày'),
                    selected: !_byDays,
                    onSelected: (_) => setState(() {
                      _byDays = false;
                      _error = null;
                    }),
                  ),
                  ChoiceChip(
                    key: const ValueKey('range-mode-days'),
                    label: const Text('Nhập số ngày'),
                    selected: _byDays,
                    onSelected: (_) => setState(() {
                      _byDays = true;
                      _error = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_byDays)
                TextFormField(
                  key: const ValueKey('report-custom-days'),
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số ngày muốn xem (1–366)',
                  ),
                )
              else
                OutlinedButton(
                  key: const ValueKey('report-custom-start'),
                  onPressed: () => _pick(true),
                  child: Text('Từ ${date.format(_start)}'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('report-custom-end'),
                onPressed: () => _pick(false),
                child: Text('Đến hết ${date.format(_last)}'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    key: const ValueKey('report-custom-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('report-custom-apply'),
                onPressed: _apply,
                child: const Text('Áp dụng khoảng này'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy, giữ khoảng hiện tại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
