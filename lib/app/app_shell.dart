import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/context_x.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive.dart';
import 'router.dart';

/// Navigation chrome shared by the five primary destinations.
///
/// Below 600dp this is a Material 3 [NavigationBar] at the bottom; at or
/// above it, a [NavigationRail] down the side. That is the standard adaptive
/// pattern — a bottom bar on a wide screen wastes the height that landscape
/// is already short on, and puts targets far from where hands rest.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = <_Destination>[
    _Destination(
      'Tasks',
      Icons.check_circle_outline_rounded,
      Icons.check_circle_rounded,
    ),
    _Destination(
      'Planner',
      Icons.event_note_outlined,
      Icons.event_note_rounded,
    ),
    _Destination('Stats', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _Destination(
      'Calendar',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    _Destination('You', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  bool get _showFab => shell.currentIndex == 0 || shell.currentIndex == 1;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return context.useSideNav ? _buildWide(context) : _buildCompact(context);
  }

  Widget _buildCompact(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: shell,
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () => context.pushOnce(Routes.taskNew),
              tooltip: 'Add task',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final colors = context.colors;
    // Only show rail labels once there is room; at 600–839dp the icons alone
    // keep the rail narrow enough to leave the content usable.
    final showLabels = context.isExpanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            backgroundColor: colors.surface,
            labelType: showLabels
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            extended: showLabels,
            minWidth: 72,
            minExtendedWidth: 190,
            indicatorColor: colors.primarySoft,
            selectedIconTheme: IconThemeData(color: colors.primary, size: 23),
            unselectedIconTheme: IconThemeData(color: colors.muted, size: 23),
            selectedLabelTextStyle: AppTypography.bodySmall.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: AppTypography.bodySmall.copyWith(
              color: colors.muted,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: _showFab
                  ? FloatingActionButton(
                      onPressed: () => context.pushOnce(Routes.taskNew),
                      tooltip: 'Add task',
                      elevation: 0,
                      child: const Icon(Icons.add_rounded, size: 26),
                    )
                  : const SizedBox(height: 56),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: Text(d.label),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
            ],
          ),
          VerticalDivider(width: 1, thickness: 1, color: colors.border),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
