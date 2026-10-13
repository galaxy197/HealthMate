import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      label: 'Tổng quan',
      icon: Icons.grid_view_outlined,
      selected: Icons.grid_view,
    ),
    (
      label: 'Nhật ký',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book,
    ),
    (label: 'Quest', icon: Icons.eco_outlined, selected: Icons.eco),
    (label: 'AI / Chat', icon: Icons.forum_outlined, selected: Icons.forum),
    (label: 'Cá nhân', icon: Icons.person_outline, selected: Icons.person),
  ];

  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= AppSpacing.railBreakpoint;
        return Scaffold(
          body: SafeArea(
            bottom: showRail,
            child: Row(
              children: [
                if (showRail) ...[
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _selectBranch,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Icon(Icons.spa_rounded, size: 32),
                    ),
                    destinations: [
                      for (final destination in _destinations)
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
              : NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _selectBranch,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selected),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
