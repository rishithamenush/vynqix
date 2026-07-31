import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/context_x.dart';
import 'router.dart';

/// Bottom-tab chrome shared by the five primary destinations.
///
/// A standard Material 3 [NavigationBar] rather than a custom control — it
/// gives the platform's own selection indicator, ripple and accessibility
/// behaviour for free, and is what users of any to-do app already expect.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline_rounded),
      selectedIcon: Icon(Icons.check_circle_rounded),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note_rounded),
      label: 'Planner',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label: 'Stats',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'You',
    ),
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
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: _destinations,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
