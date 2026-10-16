import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/tracking_goal.dart';

class GoalFormDialog extends StatefulWidget {
  const GoalFormDialog({
    required this.today,
    required this.onSave,
    this.goal,
    this.currentWeightKg,
    super.key,
  });
  final DateTime today;
  final Future<bool> Function(GoalDraft) onSave;
  final TrackingGoal? goal;
  final double? currentWeightKg;
  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  late GoalType _type;
  late GoalStatus _status;
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _target;
  late final TextEditingController _baseline;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.goal?.draft;
    _type = draft?.type ?? GoalType.meals;
    _status = draft?.status ?? GoalStatus.active;
    _start = draft?.startDate ?? widget.today;
    _end =
        draft?.endDate ??
        DateTime(widget.today.year, widget.today.month, widget.today.day + 30);
    _target = TextEditingController(text: draft?.targetValue.toString() ?? '');
    _baseline = TextEditingController(
      text:
          (draft?.baselineWeightKg ?? widget.currentWeightKg)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _target.dispose();
    _baseline.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final result = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(widget.today.year + 10),
    );
    if (result != null && mounted) {
      setState(() {
        if (start) {
          _start = result;
        } else {
          _end = result;
        }
      });
    }
  }

  Future<void> _submit() async {
    final draft = GoalDraft(
      type: _type,
      targetValue:
          double.tryParse(_target.text.trim().replaceAll(',', '.')) ??
          double.nan,
      startDate: localDateOnly(_start),
      endDate: localDateOnly(_end),
      status: _status,
      baselineWeightKg: _type == GoalType.weight
          ? double.tryParse(_baseline.text.trim().replaceAll(',', '.'))
          : null,
    );
    final error = draft.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(draft);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, draft);
      return;
    }
    setState(() {
      _saving = false;
      _error = 'Chưa thể lưu. Thông tin bạn nhập vẫn được giữ; hãy thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.goal == null ? 'Thêm mục tiêu' : 'Sửa mục tiêu'),
    content: SizedBox(
      width: 440,
      child: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<GoalType>(
                key: const ValueKey('goal-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Loại mục tiêu'),
                items: [
                  for (final type in GoalType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: widget.goal != null
                    ? null
                    : (type) => setState(() {
                        _type = type!;
                        _target.clear();
                        _error = null;
                      }),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _type == GoalType.weight
                    ? 'Theo dõi thay đổi từ cân nặng ban đầu. Bạn tự chọn mức và thời hạn phù hợp.'
                    : 'Mức bạn tự chọn cho mỗi ngày trong thời hạn. Không phải khuyến nghị sức khỏe cá nhân.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('goal-target'),
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Giá trị (${_type.unit})',
                  helperText:
                      '${_type.min.toInt()}–${_type.max.toInt()} ${_type.unit}',
                ),
              ),
              if (_type == GoalType.weight) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('goal-baseline'),
                  controller: _baseline,
                  enabled: widget.goal == null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cân nặng ban đầu (kg)',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => _pick(true),
                child: Text(
                  'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(_start)}',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => _pick(false),
                child: Text(
                  'Kết thúc: ${DateFormat('dd/MM/yyyy').format(_end)}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<GoalStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  for (final status in GoalStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const ValueKey('save-goal'),
        onPressed: _saving ? null : _submit,
        child: Text(_saving ? 'Đang lưu…' : 'Lưu mục tiêu'),
      ),
    ],
  );
}
