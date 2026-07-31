import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/context_x.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'router.dart';

/// Bottom-tab chrome shared by the five primary destinations.
///
/// The FAB is only offered on the two screens where creating a task makes
/// sense, matching the navigation spec in `design.md`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.home_outlined, Icons.home_rounded),
    _Destination(
      'Planner',
      Icons.event_note_outlined,
      Icons.event_note_rounded,
    ),
    _Destination(
      'Stats',
      Icons.bar_chart_outlined,
      Icons.bar_chart_rounded,
    ),
    _Destination(
      'Calendar',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    _Destination('You', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  bool get _showFab => shell.currentIndex == 0 || shell.currentIndex == 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: shell,
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () => context.push(Routes.taskNew),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      selected: shell.currentIndex == i,
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: AppDurations.fast,
            child: Icon(
              selected ? destination.activeIcon : destination.icon,
              size: 23,
              color: tint,
            ),
          ),
          const SizedBox(height: AppSpacing.xs - 1),
          Text(
            destination.label,
            style: AppTypography.caption.copyWith(
              color: tint,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
