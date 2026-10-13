import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _heightController = TextEditingController(
      text: widget.profile.heightCm?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UserProfileDraft(
        displayName: _nameController.text.trim(),
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : ProfileValidation.parseDecimal(_heightController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      hintText: 'Có thể để trống',
                      prefixIcon: Icon(Icons.height_rounded),
                    ),
                    validator: ProfileValidation.height,
                    onFieldSubmitted: (_) => _submit(),
                  ),
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
