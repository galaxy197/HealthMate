import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/body_metric.dart';
import '../models/profile_validation.dart';

class BodyMetricFormDialog extends StatefulWidget {
  const BodyMetricFormDialog({this.metric, this.onSave, super.key});
  final Future<bool> Function(BodyMetricDraft)? onSave;

  final BodyMetric? metric;

  @override
  State<BodyMetricFormDialog> createState() => _BodyMetricFormDialogState();
}

class _BodyMetricFormDialogState extends State<BodyMetricFormDialog>
    with ConfirmedSave<BodyMetricDraft, BodyMetricFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _measuredAt;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.metric?.weightKg.toStringAsFixed(1) ?? '',
    );
    _noteController = TextEditingController(text: widget.metric?.note ?? '');
    final initial = widget.metric?.measuredAt ?? DateTime.now();
    // Preserve an edited reading's timestamp; a new reading keeps the current
    // time so it can become the latest reading even after onboarding today.
    _measuredAt = initial;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Ngày đo',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) {
      final candidate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _measuredAt.hour,
        _measuredAt.minute,
        _measuredAt.second,
        _measuredAt.millisecond,
        _measuredAt.microsecond,
      );
      setState(() => _measuredAt = candidate.isAfter(now) ? now : candidate);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    saveDraft(
      BodyMetricDraft(
        weightKg: ProfileValidation.parseDecimal(
          _weightController.text.trim(),
        )!,
        measuredAt: _measuredAt,
        note: _noteController.text.trim(),
      ),
      widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return guardSave(
      AlertDialog(
        title: Text(widget.metric == null ? 'Thêm cân nặng' : 'Sửa cân nặng'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  saveFeedback(),
                  TextFormField(
                    key: const ValueKey('metric-weight'),
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: ProfileValidation.weight,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('metric-date'),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(locale.formatMediumDate(_measuredAt)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('metric-note'),
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: ProfileValidation.note,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const ValueKey('save-metric'),
            onPressed: _submit,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
