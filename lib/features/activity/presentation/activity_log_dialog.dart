import 'package:flutter/material.dart';

import '../models/activity_log.dart';

class ActivityLogDialog extends StatefulWidget {
  const ActivityLogDialog({required this.selectedDate, this.log, super.key});

  final DateTime selectedDate;
  final ActivityLog? log;

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _duration;
  late final TextEditingController _note;
  late ActivityType _type;
  late DateTime _performedAt;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _duration = TextEditingController(
      text: widget.log?.durationMinutes.toString() ?? '30',
    );
    _note = TextEditingController(text: widget.log?.note ?? '');
    _type = widget.log?.type ?? ActivityType.walking;
    final now = DateTime.now();
    _performedAt =
        widget.log?.performedAt ??
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          now.hour,
          now.minute,
        );
  }

  @override
  void dispose() {
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAt),
      helpText: 'Giờ vận động',
    );
    if (value == null || !mounted) return;
    setState(() {
      _performedAt = DateTime(
        _performedAt.year,
        _performedAt.month,
        _performedAt.day,
        value.hour,
        value.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final timeError = ActivityValidation.performedAt(_performedAt);
    if (timeError != null) {
      setState(() => _timeError = timeError);
      return;
    }
    Navigator.pop(
      context,
      ActivityLogDraft(
        type: _type,
        durationMinutes: int.parse(_duration.text.trim()),
        performedAt: _performedAt,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.log == null ? 'Thêm vận động' : 'Sửa vận động'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ActivityType>(
                key: const ValueKey('activity-type'),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Loại hoạt động'),
                items: [
                  for (final type in ActivityType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('activity-duration'),
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Thời lượng',
                  suffixText: 'phút',
                ),
                validator: ActivityValidation.duration,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  locale.formatTimeOfDay(TimeOfDay.fromDateTime(_performedAt)),
                ),
              ),
              if (_timeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _timeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('activity-note'),
                controller: _note,
                maxLength: ActivityValidation.maxNoteLength,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
                validator: ActivityValidation.note,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-activity'),
          onPressed: _submit,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
