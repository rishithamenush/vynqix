import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../domain/services/nudge_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/review_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';

/// Live nudges derived from the current plan.
final nudgesProvider = FutureProvider<List<Nudge>>((ref) async {
  final now = ref.watch(nowProvider);
  final settings = ref.watch(settingsValueProvider);

  final today = await ref.watch(tasksForDayProvider(now.dayKey).future);
  final tomorrow = await ref.watch(
    tasksForDayProvider(DateX.tomorrowKey).future,
  );
  final log = await ref.watch(dayLogProvider(now.dayKey).future);
  final streak = await ref.watch(streakProvider.future);

  return NudgeService.build(
    todayTasks: today,
    tomorrowTasks: tomorrow,
    todayLog: log,
    now: now,
    planReminderMinutes: settings.dailyPlanReminderMinutes,
    reviewReminderMinutes: settings.reviewReminderMinutes,
    currentStreak: streak.current,
  );
});

/// Reminders and smart suggestions, computed from the live plan rather than
/// stored as stale scheduled messages.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(nudgesProvider);
    final settings = ref.watch(settingsValueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Reminder settings',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screen),
          child: SkeletonList(count: 3),
        ),
        error: (e, _) => ErrorStateView(error: e),
        data: (nudges) {
          if (nudges.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing needs you',
              message:
                  'Reminders, overdue tasks and end-of-day nudges show up '
                  'here as they become relevant.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              AppSpacing.huge,
            ),
            itemCount: nudges.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) => _NudgeCard(
              nudge: nudges[i],
              use24h: settings.use24HourClock,
            ),
          );
        },
      ),
      backgroundColor: colors.background,
    );
  }
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.nudge, required this.use24h});

  final Nudge nudge;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, tint) = switch (nudge.kind) {
      NudgeKind.reminder => (Icons.alarm_rounded, colors.primary),
      NudgeKind.overdue => (Icons.error_outline_rounded, colors.error),
      NudgeKind.planning => (Icons.event_note_rounded, colors.accent),
      NudgeKind.review => (Icons.nights_stay_outlined, colors.secondary),
      NudgeKind.streak => (
        Icons.local_fire_department_rounded,
        colors.warning,
      ),
      NudgeKind.celebration => (
        Icons.celebration_rounded,
        colors.success,
      ),
    };

    return AppCard(
      onTap: () => _open(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md - 2),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nudge.title,
                        style: AppTypography.subtitle.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    if (nudge.atMinutes != null)
                      Text(
                        TimeOfDayX.format(nudge.atMinutes!, use24h: use24h),
                        style: AppTypography.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  nudge.body,
                  style: AppTypography.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    final taskId = nudge.taskId;
    switch (nudge.kind) {
      case NudgeKind.reminder:
      case NudgeKind.overdue:
        if (taskId != null) {
          context.push(Routes.taskEdit(taskId));
        } else {
          context.go(Routes.home);
        }
      case NudgeKind.planning:
        context.go(Routes.planner);
      case NudgeKind.review:
        context.push('${Routes.review}?day=${DateX.todayKey}');
      case NudgeKind.streak:
        context.go(Routes.home);
      case NudgeKind.celebration:
        context.push(Routes.achievements);
    }
  }
}
