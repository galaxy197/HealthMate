import 'package:flutter/material.dart';

import '../models/health_goal.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';

class ProfileFormDialog extends StatefulWidget {
  const ProfileFormDialog({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _targetWeightController;
  late DateTime? _birthDate;
  late HealthGoal? _goal;
  String? _birthDateError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _heightController = TextEditingController(
      text: widget.profile.heightCm?.toStringAsFixed(1) ?? '',
    );
    _targetWeightController = TextEditingController(
      text: widget.profile.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    _birthDate = widget.profile.birthDate;
    _goal = widget.profile.healthGoal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _submit() {
    final birthDateError = ProfileValidation.birthDate(_birthDate);
    setState(() => _birthDateError = birthDateError);
    if (!_formKey.currentState!.validate() || birthDateError != null) return;
    Navigator.of(context).pop(
      UserProfileDraft(
        displayName: _nameController.text.trim(),
        heightCm: ProfileValidation.parseDecimal(
          _heightController.text.trim(),
        )!,
        birthDate: _birthDate!,
        healthGoal: _goal!,
        targetWeightKg: _goal!.needsTargetWeight
            ? ProfileValidation.parseDecimal(
                _targetWeightController.text.trim(),
              )
            : null,
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 120, now.month, now.day),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) {
      setState(() {
        _birthDate = selected;
        _birthDateError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return AlertDialog(
      title: const Text('Chỉnh sửa hồ sơ'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('profile-name'),
                    controller: _nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: ProfileValidation.displayName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile-height'),
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Chiều cao (cm)',
                      prefixIcon: Icon(Icons.height_rounded),
                    ),
                    validator: ProfileValidation.requiredHeight,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('profile-birth-date'),
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                      _birthDate == null
                          ? 'Chọn ngày sinh'
                          : locale.formatMediumDate(_birthDate!),
                    ),
                  ),
                  if (_birthDateError != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _birthDateError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<HealthGoal>(
                    key: const ValueKey('profile-health-goal'),
                    initialValue: _goal,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu sức khỏe',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      for (final goal in HealthGoal.values)
                        DropdownMenuItem(value: goal, child: Text(goal.label)),
                    ],
                    onChanged: (value) => setState(() => _goal = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn một mục tiêu.' : null,
                  ),
                  if (_goal?.needsTargetWeight == true) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('profile-target-weight'),
                      controller: _targetWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng mục tiêu (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      validator: (value) =>
                          ProfileValidation.targetWeight(value, _goal),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                ],
              ),
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
          key: const ValueKey('save-profile'),
          onPressed: _submit,
          child: const Text('Lưu hồ sơ'),
        ),
      ],
    );
  }
}
