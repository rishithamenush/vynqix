import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/date_x.dart';
import '../presentation/features/achievements/achievements_screen.dart';
import '../presentation/features/analytics/analytics_screen.dart';
import '../presentation/features/calendar/calendar_screen.dart';
import '../presentation/features/focus/focus_screen.dart';
import '../presentation/features/history/history_screen.dart';
import '../presentation/features/home/home_screen.dart';
import '../presentation/features/insights/insights_screen.dart';
import '../presentation/features/notifications/notifications_screen.dart';
import '../presentation/features/onboarding/lifestyle_screen.dart';
import '../presentation/features/onboarding/profile_setup_screen.dart';
import '../presentation/features/onboarding/welcome_screen.dart';
import '../presentation/features/planner/planner_screen.dart';
import '../presentation/features/premium/premium_screen.dart';
import '../presentation/features/profile/profile_screen.dart';
import '../presentation/features/review/review_screen.dart';
import '../presentation/features/settings/settings_screen.dart';
import '../presentation/features/task_editor/task_editor_screen.dart';
import '../presentation/providers/app_providers.dart';
import 'app_shell.dart';

/// Named route paths, referenced instead of raw strings at call sites.
abstract final class Routes {
  static const welcome = '/welcome';
  static const onboardingProfile = '/welcome/profile';
  static const onboardingLifestyle = '/welcome/lifestyle';

  static const home = '/home';
  static const planner = '/planner';
  static const analytics = '/analytics';
  static const calendar = '/calendar';
  static const profile = '/profile';

  static const taskNew = '/task/new';
  static String taskEdit(String id) => '/task/$id';

  static const focus = '/focus';
  static const review = '/review';
  static const history = '/history';
  static const notifications = '/notifications';
  static const insights = '/insights';
  static const achievements = '/achievements';
  static const premium = '/premium';
  static const settings = '/settings';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    redirect: (context, state) {
      // Everything is gated behind onboarding until a profile exists.
      final onboarded = ref.read(onboardingCompleteProvider);
      final goingToOnboarding = state.matchedLocation.startsWith(
        Routes.welcome,
      );
      if (!onboarded && !goingToOnboarding) return Routes.welcome;
      if (onboarded && goingToOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (_, _) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (_, _) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: 'lifestyle',
            builder: (_, _) => const LifestyleScreen(),
          ),
        ],
      ),

      // Bottom-tab shell. Each branch keeps its own navigation state.
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.planner,
                builder: (_, _) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.analytics,
                builder: (_, _) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (_, _) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: Routes.taskNew,
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _modalPage(
          state,
          TaskEditorScreen(dayKey: state.uri.queryParameters['day']),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _modalPage(
          state,
          TaskEditorScreen(taskId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: Routes.focus,
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _modalPage(
          state,
          FocusScreen(taskId: state.uri.queryParameters['taskId']),
          fullscreen: true,
        ),
      ),
      GoRoute(
        path: Routes.review,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ReviewScreen(
          dayKey: state.uri.queryParameters['day'] ?? DateX.todayKey,
        ),
      ),
      GoRoute(
        path: Routes.history,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.insights,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const InsightsScreen(),
      ),
      GoRoute(
        path: Routes.achievements,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AchievementsScreen(),
      ),
      GoRoute(
        path: Routes.premium,
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _modalPage(state, const PremiumScreen(), fullscreen: true),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

/// Sheet-style page used for the task editor, focus mode and paywall.
Page<void> _modalPage(
  GoRouterState state,
  Widget child, {
  bool fullscreen = false,
}) {
  return MaterialPage(
    key: state.pageKey,
    fullscreenDialog: fullscreen,
    child: child,
  );
}
