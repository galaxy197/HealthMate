import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/journal/providers/journal_date_provider.dart';
import '../../features/journal/providers/journal_quick_action_provider.dart';
import '../theme/app_spacing.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _visibleDestinations = [
    (
      branch: 0,
      label: 'Tổng quan',
      icon: Icons.home_outlined,
      selected: Icons.home_rounded,
      key: ValueKey('nav-dashboard'),
    ),
    (
      branch: 1,
      label: 'Nhật ký',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book_rounded,
      key: ValueKey('nav-journal'),
    ),
    (
      branch: 4,
      label: 'Cá nhân',
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
      key: ValueKey('nav-profile'),
    ),
  ];

  void _selectBranch(int branch) {
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  Future<void> _showQuickActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<JournalQuickAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _QuickActionSheet(),
    );
    if (action == null || !context.mounted) return;
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
        final visibleIndex = _visibleDestinations.indexWhere(
          (destination) => destination.branch == navigationShell.currentIndex,
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
                  currentBranch: navigationShell.currentIndex,
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
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        color: scheme.surfaceContainerLowest,
        elevation: 3,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.navigationRadius),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 76,
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
                child: Center(
                  child: FloatingActionButton(
                    key: const ValueKey('quick-add-menu'),
                    heroTag: 'quick-add-bottom',
                    tooltip: 'Thêm ghi nhận',
                    onPressed: onQuickAdd,
                    child: const Icon(Icons.add_rounded, size: 30),
                  ),
                ),
              ),
              Expanded(
                child: _NavigationButton(
                  key: destinations.last.key,
                  label: destinations.last.label,
                  icon: currentBranch == destinations.last.branch
                      ? destinations.last.selected
                      : destinations.last.icon,
                  selected: currentBranch == destinations.last.branch,
                  onTap: () => onSelect(destinations.last.branch),
                ),
              ),
            ],
          ),
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
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet();

  @override
  Widget build(BuildContext context) {
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
          FilledButton.icon(
            key: const ValueKey('quick-action-scan'),
            onPressed: () =>
                Navigator.pop(context, JournalQuickAction.scanFood),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Quét món'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SheetAction(
            key: const ValueKey('quick-action-meal'),
            icon: Icons.restaurant_menu_rounded,
            label: 'Thêm bữa ăn thủ công',
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
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(label),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    ),
  );
}
