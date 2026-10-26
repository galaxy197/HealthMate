import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../../auth/models/account_action_failure.dart';
import '../../auth/models/auth_failure.dart';
import '../../auth/presentation/account_security_dialogs.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/body_metric.dart';
import '../models/health_goal.dart';
import '../models/onboarding_draft.dart';
import '../models/profile_failure.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../providers/profile_providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final metricsState = ref.watch(bodyMetricsProvider);
    return Scaffold(
      body: SafeArea(
        child: profileState.when(
          loading: () => const _OnboardingStatus(
            title: 'Đang chuẩn bị hồ sơ',
            message: 'HealthMate đang tải thông tin của bạn.',
          ),
          error: (error, _) => _OnboardingStatus(
            title: 'Chưa thể tải hồ sơ',
            message: _messageFor(error),
            onRetry: () {
              ref.invalidate(profileBootstrapProvider);
              ref.invalidate(userProfileProvider);
            },
          ),
          data: (profile) {
            if (profile == null) {
              return _OnboardingStatus(
                title: 'Chưa thể tạo hồ sơ',
                message: 'Hãy thử lại để tiếp tục thiết lập HealthMate.',
                onRetry: () {
                  ref.invalidate(profileBootstrapProvider);
                  ref.invalidate(userProfileProvider);
                },
              );
            }
            return metricsState.when(
              loading: () => const _OnboardingStatus(
                title: 'Đang tải dữ liệu thể trạng',
                message: 'Quá trình này chỉ mất một chút thời gian.',
              ),
              error: (error, _) => _OnboardingStatus(
                title: 'Chưa thể tải cân nặng',
                message: _messageFor(error),
                onRetry: () => ref.invalidate(bodyMetricsProvider),
              ),
              data: (metrics) => _OnboardingForm(
                key: ValueKey('onboarding-${profile.uid}'),
                profile: profile,
                latestMetric: metrics.firstOrNull,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingForm extends ConsumerStatefulWidget {
  const _OnboardingForm({
    required this.profile,
    required this.latestMetric,
    super.key,
  });

  final UserProfile profile;
  final BodyMetric? latestMetric;

  @override
  ConsumerState<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<_OnboardingForm> {
  final _bodyFormKey = GlobalKey<FormState>();
  final _targetFormKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late DateTime? _birthDate;
  late HealthGoal? _goal;
  int _step = 0;
  String? _birthDateError;
  String? _goalError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _height = TextEditingController(
      text: widget.profile.heightCm?.toStringAsFixed(1) ?? '',
    );
    _weight = TextEditingController(
      text: widget.latestMetric?.weightKg.toStringAsFixed(1) ?? '',
    );
    _targetWeight = TextEditingController(
      text: widget.profile.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    _birthDate = widget.profile.birthDate;
    _goal = widget.profile.healthGoal;
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  bool _validateBody() {
    final birthDateError = ProfileValidation.birthDate(_birthDate);
    setState(() => _birthDateError = birthDateError);
    return _bodyFormKey.currentState!.validate() && birthDateError == null;
  }

  bool _validateGoal() {
    if (_goal != null) return true;
    setState(() => _goalError = 'Vui lòng chọn một mục tiêu.');
    return false;
  }

  bool _validateTarget() => _targetFormKey.currentState!.validate();

  void _next() {
    final valid = switch (_step) {
      0 => _validateBody(),
      1 => _validateGoal(),
      2 => _validateTarget(),
      _ => true,
    };
    if (valid) setState(() => _step++);
  }

  void _previous() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 120, now.month, now.day);
    final last = DateTime(now.year - 18, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 20);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last)
          ? last
          : initial.isBefore(first)
          ? first
          : initial,
      firstDate: first,
      lastDate: last,
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

  Future<void> _complete() async {
    final bodyError =
        ProfileValidation.displayName(_name.text) ??
        ProfileValidation.birthDate(_birthDate) ??
        ProfileValidation.requiredHeight(_height.text) ??
        ProfileValidation.weight(_weight.text);
    if (bodyError != null) {
      setState(() => _step = 0);
      return;
    }
    if (_goal == null) {
      setState(() => _step = 1);
      return;
    }
    if (ProfileValidation.targetWeight(_targetWeight.text, _goal) != null) {
      setState(() => _step = 2);
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(profileControllerProvider.notifier)
        .completeOnboarding(
          OnboardingDraft(
            displayName: _name.text.trim(),
            birthDate: _birthDate!,
            heightCm: ProfileValidation.parseDecimal(_height.text.trim())!,
            currentWeightKg: ProfileValidation.parseDecimal(
              _weight.text.trim(),
            )!,
            healthGoal: _goal!,
            targetWeightKg: _goal!.needsTargetWeight
                ? ProfileValidation.parseDecimal(_targetWeight.text.trim())
                : null,
          ),
        );
  }

  Future<void> _deleteAccount() async {
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final password = await showDeleteAccountDialog(
      context,
      requirePassword:
          ref.read(authSessionProvider).value?.hasPassword != false,
    );
    if (password == null || !mounted) return;
    await ref
        .read(accountSecurityControllerProvider.notifier)
        .deleteAccount(password);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(profileControllerProvider);
    final accountAction = ref.watch(accountSecurityControllerProvider);
    final busy = action.isLoading || accountAction.isLoading;
    return FeaturePage(
      title: 'Thiết lập sức khỏe ban đầu',
      subtitle:
          'Bản MVP dành cho người từ 18 tuổi. Chỉ cung cấp thông tin cần thiết; dữ liệu đã lưu được giữ nguyên.',
      children: [
        LinearProgressIndicator(
          key: const ValueKey('onboarding-progress'),
          value: (_step + 1) / 4,
          semanticsLabel: 'Bước ${_step + 1} trên 4',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bước ${_step + 1}/4 · ${_stepTitle(_step)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                0 => _BodyStep(
                  key: const ValueKey('onboarding-body-step'),
                  formKey: _bodyFormKey,
                  name: _name,
                  height: _height,
                  weight: _weight,
                  birthDate: _birthDate,
                  birthDateError: _birthDateError,
                  onPickBirthDate: _pickBirthDate,
                ),
                1 => _GoalStep(
                  key: const ValueKey('onboarding-goal-step'),
                  selected: _goal,
                  error: _goalError,
                  onSelected: (goal) => setState(() {
                    _goal = goal;
                    _goalError = null;
                  }),
                ),
                2 => _TargetStep(
                  key: const ValueKey('onboarding-target-step'),
                  formKey: _targetFormKey,
                  goal: _goal!,
                  targetWeight: _targetWeight,
                ),
                _ => _ReviewStep(
                  key: const ValueKey('onboarding-review-step'),
                  name: _name.text.trim(),
                  birthDate: _birthDate!,
                  heightCm: ProfileValidation.parseDecimal(_height.text)!,
                  weightKg: ProfileValidation.parseDecimal(_weight.text)!,
                  goal: _goal!,
                  targetWeightKg: _goal!.needsTargetWeight
                      ? ProfileValidation.parseDecimal(_targetWeight.text)
                      : null,
                ),
              },
            ),
          ),
        ),
        if (action.error case final Object error) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              _messageFor(error),
              key: const ValueKey('onboarding-save-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('onboarding-back'),
                  onPressed: action.isLoading ? null : _previous,
                  child: const Text('Quay lại'),
                ),
              ),
            if (_step > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                key: ValueKey(
                  _step == 3 ? 'onboarding-complete' : 'onboarding-next',
                ),
                onPressed: busy ? null : (_step == 3 ? _complete : _next),
                child: action.isLoading && _step == 3
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 3 ? 'Hoàn tất thiết lập' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: busy
              ? null
              : () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất và thiết lập sau'),
        ),
        TextButton.icon(
          key: const ValueKey('onboarding-delete-account'),
          onPressed: busy ? null : _deleteAccount,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Xóa tài khoản và dữ liệu'),
        ),
        if (accountAction.error case final Object error)
          Semantics(
            liveRegion: true,
            child: Text(
              switch (error) {
                AuthFailure failure => failure.message,
                AccountActionFailure failure => failure.message,
                _ => 'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
              },
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _BodyStep extends StatelessWidget {
  const _BodyStep({
    required this.formKey,
    required this.name,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.birthDateError,
    required this.onPickBirthDate,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController height;
  final TextEditingController weight;
  final DateTime? birthDate;
  final String? birthDateError;
  final VoidCallback onPickBirthDate;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thông tin cơ bản',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Các số liệu này giúp hiển thị chỉ số và mục tiêu phù hợp.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            key: const ValueKey('onboarding-name'),
            controller: name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: ProfileValidation.displayName,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const ValueKey('onboarding-birth-date'),
            onPressed: onPickBirthDate,
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              birthDate == null
                  ? 'Chọn ngày sinh'
                  : locale.formatMediumDate(birthDate!),
            ),
          ),
          if (birthDateError != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              birthDateError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('onboarding-height'),
            controller: height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Chiều cao (cm)',
              prefixIcon: Icon(Icons.height_rounded),
            ),
            validator: ProfileValidation.requiredHeight,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('onboarding-weight'),
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Cân nặng hiện tại (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            validator: ProfileValidation.weight,
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.error,
    required this.onSelected,
    super.key,
  });

  final HealthGoal? selected;
  final String? error;
  final ValueChanged<HealthGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mục tiêu của bạn', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('Bạn có thể thay đổi lựa chọn này trong trang Cá nhân.'),
        const SizedBox(height: AppSpacing.md),
        for (final goal in HealthGoal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ChoiceChip(
              key: ValueKey('onboarding-goal-${goal.value}'),
              label: SizedBox(width: double.infinity, child: Text(goal.label)),
              selected: selected == goal,
              onSelected: (_) => onSelected(goal),
              showCheckmark: true,
            ),
          ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _TargetStep extends StatelessWidget {
  const _TargetStep({
    required this.formKey,
    required this.goal,
    required this.targetWeight,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final HealthGoal goal;
  final TextEditingController targetWeight;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thông tin mục tiêu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (goal.needsTargetWeight) ...[
            Text(
              'Nhập cân nặng bạn muốn hướng tới cho mục tiêu “${goal.label}”.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const ValueKey('onboarding-target-weight'),
              controller: targetWeight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Cân nặng mục tiêu (kg)',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (value) => ProfileValidation.targetWeight(value, goal),
            ),
          ] else
            const Text(
              'Mục tiêu này chưa cần thêm số liệu. HealthMate sẽ dựa trên nhật ký bạn tự ghi nhận.',
            ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.name,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.targetWeightKg,
    super.key,
  });

  final String name;
  final DateTime birthDate;
  final double heightCm;
  final double weightKg;
  final HealthGoal goal;
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Xem lại thông tin',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _ReviewRow(label: 'Tên hiển thị', value: name),
        _ReviewRow(
          label: 'Ngày sinh',
          value: locale.formatMediumDate(birthDate),
        ),
        _ReviewRow(
          label: 'Chiều cao',
          value: '${heightCm.toStringAsFixed(1)} cm',
        ),
        _ReviewRow(
          label: 'Cân nặng hiện tại',
          value: '${weightKg.toStringAsFixed(1)} kg',
        ),
        _ReviewRow(label: 'Mục tiêu', value: goal.label),
        if (targetWeightKg != null)
          _ReviewRow(
            label: 'Cân nặng mục tiêu',
            value: '${targetWeightKg!.toStringAsFixed(1)} kg',
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Bạn có thể cập nhật các thông tin này sau trong trang Cá nhân.',
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStatus extends StatelessWidget {
  const _OnboardingStatus({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: title,
      subtitle: message,
      children: [
        if (onRetry == null)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
      ],
    );
  }
}

String _stepTitle(int step) => switch (step) {
  0 => 'Thể trạng',
  1 => 'Mục tiêu',
  2 => 'Cá nhân hóa',
  _ => 'Xác nhận',
};

String _messageFor(Object error) => switch (error) {
  ProfileFailure failure => failure.message,
  _ => 'Chưa thể tải dữ liệu. Vui lòng thử lại.',
};
