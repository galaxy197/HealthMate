import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../auth/models/auth_failure.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/body_metric.dart';
import '../models/profile_failure.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../providers/profile_providers.dart';
import 'body_metric_form_dialog.dart';
import 'profile_form_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMode = ref.watch(themeModeProvider);
    final user = ref.watch(authSessionProvider).value;
    final authAction = ref.watch(authControllerProvider);
    final profileAction = ref.watch(profileControllerProvider);
    final profileState = ref.watch(userProfileProvider);
    final metricState = ref.watch(bodyMetricsProvider);
    final profile = profileState.value;
    final metrics = metricState.value ?? const <BodyMetric>[];

    return FeaturePage(
      title: 'Không gian cá nhân',
      subtitle: 'Hồ sơ và lịch sử thể trạng chỉ thuộc về tài khoản của bạn.',
      children: [
        if (profileAction.isLoading) const LinearProgressIndicator(),
        if (profileAction.error case final ProfileFailure error) ...[
          _InlineError(
            message: error.message,
            onDismiss: () =>
                ref.read(profileControllerProvider.notifier).clearError(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _AccountCard(
          email: user?.email,
          action: authAction,
          onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileCard(
          state: profileState,
          profile: profile,
          onEdit: profile == null
              ? null
              : () => _editProfile(context, ref, profile),
          onRetry: () => _retryProfile(ref),
        ),
        const SizedBox(height: AppSpacing.md),
        if (profile != null && metrics.isNotEmpty)
          _BmiCard(profile: profile, latestMetric: metrics.first),
        if (profile != null && metrics.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        _MetricsCard(
          state: metricState,
          metrics: metrics,
          onAdd: profile == null ? null : () => _editMetric(context, ref),
          onEdit: (metric) => _editMetric(context, ref, metric: metric),
          onDelete: (metric) => _deleteMetric(context, ref, metric),
          onRetry: () => ref.invalidate(bodyMetricsProvider),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Giao diện', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                const Text('Chọn cách hiển thị cho lần mở ứng dụng này.'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in const [
                      (
                        mode: ThemeMode.system,
                        label: 'Thiết bị',
                        icon: Icons.phone_android,
                      ),
                      (
                        mode: ThemeMode.light,
                        label: 'Sáng',
                        icon: Icons.light_mode_outlined,
                      ),
                      (
                        mode: ThemeMode.dark,
                        label: 'Tối',
                        icon: Icons.dark_mode_outlined,
                      ),
                    ])
                      ChoiceChip(
                        avatar: Icon(option.icon, size: 18),
                        label: Text(option.label),
                        selected: selectedMode == option.mode,
                        onSelected: (_) => ref
                            .read(themeModeProvider.notifier)
                            .setMode(option.mode),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final draft = await showDialog<UserProfileDraft>(
      context: context,
      builder: (context) => ProfileFormDialog(profile: profile),
    );
    if (draft == null || !context.mounted) return;
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(draft);
    if (saved && context.mounted) _showSaved(context, 'Đã cập nhật hồ sơ.');
  }

  Future<void> _editMetric(
    BuildContext context,
    WidgetRef ref, {
    BodyMetric? metric,
  }) async {
    final draft = await showDialog<BodyMetricDraft>(
      context: context,
      builder: (context) => BodyMetricFormDialog(metric: metric),
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(profileControllerProvider.notifier);
    final saved = metric == null
        ? await controller.addBodyMetric(draft)
        : await controller.updateBodyMetric(metricId: metric.id, draft: draft);
    if (saved && context.mounted) {
      _showSaved(
        context,
        metric == null ? 'Đã thêm lần đo.' : 'Đã cập nhật lần đo.',
      );
    }
  }

  Future<void> _deleteMetric(
    BuildContext context,
    WidgetRef ref,
    BodyMetric metric,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lần đo?'),
        content: Text(
          'Lần đo ${metric.weightKg.toStringAsFixed(1)} kg sẽ bị xóa khỏi lịch sử.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-metric'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(profileControllerProvider.notifier)
        .deleteBodyMetric(metric.id);
    if (deleted && context.mounted) _showSaved(context, 'Đã xóa lần đo.');
  }

  void _retryProfile(WidgetRef ref) {
    ref.invalidate(profileBootstrapProvider);
    ref.invalidate(userProfileProvider);
  }

  void _showSaved(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.action,
    required this.onSignOut,
  });

  final String? email;
  final AsyncValue<void> action;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tài khoản của bạn', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(email ?? 'Tài khoản đã đăng nhập'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey('sign-out'),
              onPressed: action.isLoading ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: Text(action.isLoading ? 'Đang đăng xuất…' : 'Đăng xuất'),
            ),
            if (action.error case final AuthFailure error) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  error.message,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.state,
    required this.profile,
    required this.onEdit,
    required this.onRetry,
  });

  final AsyncValue<UserProfile?> state;
  final UserProfile? profile;
  final VoidCallback? onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Hồ sơ', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  key: const ValueKey('edit-profile'),
                  onPressed: onEdit,
                  tooltip: 'Chỉnh sửa hồ sơ',
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            state.when(
              loading: () => const _LoadingLine(),
              error: (error, _) =>
                  _LoadError(message: _messageFor(error), onRetry: onRetry),
              data: (_) => profile == null
                  ? _LoadError(
                      message: 'Chưa thể tạo hồ sơ cho tài khoản này.',
                      onRetry: onRetry,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile!.displayName.isEmpty
                              ? 'Chưa đặt tên hiển thị'
                              : profile!.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(profile!.email),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile!.heightCm == null
                              ? 'Chưa nhập chiều cao'
                              : 'Chiều cao: ${profile!.heightCm!.toStringAsFixed(1)} cm',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.profile, required this.latestMetric});

  final UserProfile profile;
  final BodyMetric latestMetric;

  @override
  Widget build(BuildContext context) {
    final bmi = ProfileValidation.bmi(
      heightCm: profile.heightCm,
      weightKg: latestMetric.weightKg,
    );
    if (bmi == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI tham khảo: ${bmi.toStringAsFixed(1)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tính từ chiều cao và lần đo cân nặng mới nhất. Chỉ số này chỉ để tham khảo, không phải chẩn đoán y khoa.',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.state,
    required this.metrics,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  final AsyncValue<List<BodyMetric>> state;
  final List<BodyMetric> metrics;
  final VoidCallback? onAdd;
  final ValueChanged<BodyMetric> onEdit;
  final ValueChanged<BodyMetric> onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lịch sử cân nặng',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('add-metric'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            state.when(
              loading: () => const _LoadingLine(),
              error: (error, _) =>
                  _LoadError(message: _messageFor(error), onRetry: onRetry),
              data: (_) => metrics.isEmpty
                  ? const Text(
                      'Chưa có lần đo nào. Thêm cân nặng để bắt đầu theo dõi lịch sử.',
                    )
                  : Column(
                      children: [
                        for (final metric in metrics)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.monitor_weight_outlined),
                            ),
                            title: Text(
                              '${metric.weightKg.toStringAsFixed(1)} kg',
                            ),
                            subtitle: Text(
                              [
                                locale.formatMediumDate(metric.measuredAt),
                                if (metric.note.isNotEmpty) metric.note,
                              ].join(' · '),
                            ),
                            trailing: Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                IconButton(
                                  key: ValueKey('edit-metric-${metric.id}'),
                                  onPressed: () => onEdit(metric),
                                  tooltip: 'Sửa lần đo',
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: ValueKey('delete-metric-${metric.id}'),
                                  onPressed: () => onDelete(metric),
                                  tooltip: 'Xóa lần đo',
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('Đang tải dữ liệu…')),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Đóng thông báo',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageFor(Object error) => switch (error) {
  ProfileFailure failure => failure.message,
  _ => 'Chưa thể tải dữ liệu. Vui lòng thử lại.',
};
