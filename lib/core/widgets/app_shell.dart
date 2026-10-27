import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../theme/reference_palette.dart';
import 'design_illustration.dart';
import '../../features/journal/providers/journal_date_provider.dart';
import '../../features/journal/providers/journal_quick_action_provider.dart';
import '../theme/app_spacing.dart';
import 'confirmed_save.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/profile/presentation/body_metric_form_dialog.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/weekly_reflection/providers/weekly_reflection_providers.dart';

import '../config/app_feature_flags.dart';

enum _ExtraAction { weight, quests, chat, steps, sleep }

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _visibleDestinations = [
    (
      branch: 0,
      label: 'Hôm nay',
      icon: Icons.home_outlined,
      selected: Icons.home_outlined,
      key: ValueKey('nav-dashboard'),
    ),
    (
      branch: 1,
      label: 'Nhật ký',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book_outlined,
      key: ValueKey('nav-journal'),
    ),
    (
      branch: 5,
      label: 'Tiến độ',
      icon: Icons.bar_chart_outlined,
      selected: Icons.bar_chart_outlined,
      key: ValueKey('nav-progress'),
    ),
    (
      branch: 6,
      label: 'Thói quen',
      icon: Icons.grid_view_outlined,
      selected: Icons.grid_view_outlined,
      key: ValueKey('nav-wellness'),
    ),
  ];

  void _selectBranch(int branch) {
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  Future<void> _showQuickActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<Object>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _QuickActionSheet(),
    );
    if (action == null || !context.mounted) return;
    if (action == _ExtraAction.steps || action == _ExtraAction.sleep) {
      context.push(
        '${AppRoutes.wellness}?tab=${action == _ExtraAction.steps ? 2 : 3}',
      );
      return;
    }
    if (action == _ExtraAction.quests || action == _ExtraAction.chat) {
      _selectBranch(action == _ExtraAction.quests ? 2 : 3);
      return;
    }
    if (action == _ExtraAction.weight) {
      final uid = ref.read(authSessionProvider).value?.uid;
      if (uid == null) return;
      final repository = ref.read(healthProfileRepositoryProvider);
      final saved = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountBoundDialog(
          child: BodyMetricFormDialog(
            onSave: (draft) async {
              if (ref.read(authSessionProvider).value?.uid != uid) return false;
              await repository.addBodyMetric(uid: uid, draft: draft);
              if (!context.mounted ||
                  ref.read(authSessionProvider).value?.uid != uid) {
                return false;
              }
              ref.invalidate(weeklyLogsProvider);
              return true;
            },
          ),
        ),
      );
      if (saved != null &&
          context.mounted &&
          ref.read(authSessionProvider).value?.uid == uid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm lần đo.')));
      }
      return;
    }
    if (action is! JournalQuickAction) return;
    ref.read(journalDateProvider.notifier).select(DateTime.now());
    navigationShell.goBranch(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(journalQuickActionProvider.notifier).request(action);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= AppSpacing.railBreakpoint;
        final currentBranch = navigationShell.currentIndex;
        final visibleIndex = _visibleDestinations.indexWhere(
          (destination) => destination.branch == currentBranch,
        );
        return Scaffold(
          body: SafeArea(
            bottom: showRail,
            child: Row(
              children: [
                if (showRail) ...[
                  NavigationRail(
                    selectedIndex: visibleIndex < 0 ? null : visibleIndex,
                    onDestinationSelected: (index) =>
                        _selectBranch(_visibleDestinations[index].branch),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.spa_rounded, size: 32),
                          const SizedBox(height: AppSpacing.lg),
                          FloatingActionButton.small(
                            key: const ValueKey('quick-add-menu'),
                            heroTag: 'quick-add-rail',
                            tooltip: 'Thêm ghi nhận',
                            onPressed: () => _showQuickActions(context, ref),
                            child: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    destinations: [
                      for (final destination in _visibleDestinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selected),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: navigationShell),
              ],
            ),
          ),
          bottomNavigationBar: showRail
              ? null
              : _FloatingNavigationBar(
                  currentBranch: currentBranch,
                  destinations: _visibleDestinations,
                  onSelect: _selectBranch,
                  onQuickAdd: () => _showQuickActions(context, ref),
                ),
        );
      },
    );
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.currentBranch,
    required this.destinations,
    required this.onSelect,
    required this.onQuickAdd,
  });

  final int currentBranch;
  final List<
    ({
      int branch,
      String label,
      IconData icon,
      IconData selected,
      ValueKey<String> key,
    })
  >
  destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final style = Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400);
            var height = 68.0;
            for (final label in [
              ...destinations.map((d) => d.label),
              'Ghi nhanh',
            ]) {
              final painter =
                  TextPainter(
                    text: TextSpan(text: label, style: style),
                    maxLines: 2,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(
                    maxWidth:
                        (constraints.maxWidth / (destinations.length + 1) - 4)
                            .clamp(1, double.infinity),
                  );
              final needed = painter.height + 45;
              if (needed > height) height = needed;
              painter.dispose();
            }
            return SizedBox(
              height: height,
              child: Row(
                children: [
                  for (final destination in destinations.take(2))
                    Expanded(
                      child: _NavigationButton(
                        key: destination.key,
                        label: destination.label,
                        icon: currentBranch == destination.branch
                            ? destination.selected
                            : destination.icon,
                        selected: currentBranch == destination.branch,
                        onTap: () => onSelect(destination.branch),
                      ),
                    ),
                  Expanded(
                    child: _NavigationButton(
                      key: const ValueKey('quick-add-menu'),
                      label: 'Ghi nhanh',
                      icon: Icons.add_rounded,
                      selected: false,
                      actionColor: scheme.primary,
                      onTap: onQuickAdd,
                    ),
                  ),
                  for (final destination in destinations.skip(2))
                    Expanded(
                      child: _NavigationButton(
                        key: destination.key,
                        label: destination.label,
                        icon: currentBranch == destination.branch
                            ? destination.selected
                            : destination.icon,
                        selected: currentBranch == destination.branch,
                        onTap: () => onSelect(destination.branch),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.actionColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        actionColor ??
        (selected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ReferencePalette.blue.withValues(alpha: .12),
                      Colors.transparent,
                    ],
                  )
                : null,
            border: selected
                ? Border(top: BorderSide(color: color, width: 2))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24, applyTextScaling: false),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionSheet extends ConsumerWidget {
  const _QuickActionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Thêm ghi nhận', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chọn nội dung bạn muốn thêm cho hôm nay.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ref.watch(appFeatureFlagsProvider).foodScannerEnabled) ...[
            FilledButton.icon(
              key: const ValueKey('quick-action-scan'),
              onPressed: () =>
                  Navigator.pop(context, JournalQuickAction.scanFood),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét món'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _SheetAction(
            key: const ValueKey('quick-action-meal'),
            icon: Icons.restaurant_menu_rounded,
            label: 'Thêm bữa ăn',
            onTap: () => Navigator.pop(context, JournalQuickAction.addMeal),
          ),
          _SheetAction(
            key: const ValueKey('quick-action-water'),
            icon: Icons.water_drop_outlined,
            label: 'Thêm nước',
            onTap: () => Navigator.pop(context, JournalQuickAction.addWater),
          ),
          _SheetAction(
            key: const ValueKey('quick-action-activity'),
            icon: Icons.directions_run_rounded,
            label: 'Thêm vận động',
            onTap: () => Navigator.pop(context, JournalQuickAction.addActivity),
          ),
          _SheetAction(
            key: const ValueKey('quick-action-weight'),
            icon: Icons.monitor_weight_outlined,
            label: 'Thêm cân nặng',
            onTap: () => Navigator.pop(context, _ExtraAction.weight),
          ),
          _SheetAction(
            key: const ValueKey('quick-action-steps'),
            icon: Icons.directions_walk,
            label: 'Bước chân',
            onTap: () => Navigator.pop(context, _ExtraAction.steps),
          ),
          _SheetAction(
            key: const ValueKey('quick-action-sleep'),
            icon: Icons.bedtime_outlined,
            label: 'Giấc ngủ',
            onTap: () => Navigator.pop(context, _ExtraAction.sleep),
          ),
          const Divider(),
          _SheetAction(
            key: const ValueKey('quick-action-quests'),
            icon: Icons.flag_outlined,
            label: 'Mục tiêu và nhiệm vụ',
            onTap: () => Navigator.pop(context, _ExtraAction.quests),
          ),
          if (ref.watch(appFeatureFlagsProvider).chatbotEnabled)
            _SheetAction(
              key: const ValueKey('quick-action-chat'),
              icon: Icons.forum_outlined,
              label: 'Trò chuyện cùng HealthMate',
              onTap: () => Navigator.pop(context, _ExtraAction.chat),
            ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    leading: DesignIllustration(switch (label) {
      'Thêm bữa ăn' => 'food',
      'Thêm nước' => 'water',
      'Thêm vận động' => 'activity',
      'Thêm cân nặng' => 'weight',
      'Bước chân' => 'steps',
      'Giấc ngủ' => 'moon',
      'Mục tiêu và nhiệm vụ' => 'flag',
      _ => 'chat',
    }),
    title: Text(label),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    ),
  );
}
