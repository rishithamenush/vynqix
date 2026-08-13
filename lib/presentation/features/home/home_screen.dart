import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/async_guard.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/task.dart';
import '../../providers/app_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/task_card.dart';

/// Today's list: a compact progress header, then the day's tasks split into
/// outstanding and completed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final todayKey = now.dayKey;
    final tasksAsync = ref.watch(tasksForDayProvider(todayKey));
    final settings = ref.watch(settingsValueProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: context.gutter,
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => context.pushOnce(Routes.history),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Reminders',
            onPressed: () => context.pushOnce(Routes.notifications),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) => switch (value) {
              'review' => context.pushOnce('${Routes.review}?day=$todayKey'),
              'focus' => context.pushOnce(Routes.focus),
              'insights' => context.pushOnce(Routes.insights),
              _ => context.pushOnce(Routes.settings),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'focus',
                child: _MenuRow(Icons.timer_outlined, 'Focus timer'),
              ),
              PopupMenuItem(
                value: 'review',
                child: _MenuRow(Icons.rate_review_outlined, 'Daily review'),
              ),
              PopupMenuItem(
                value: 'insights',
                child: _MenuRow(Icons.auto_awesome_outlined, 'Insights'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: _MenuRow(Icons.settings_outlined, 'Settings'),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksForDayProvider(todayKey));
          ref.invalidate(dayStatsProvider(todayKey));
        },
        child: tasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: SkeletonList(),
          ),
          error: (e, _) => ErrorStateView(
            error: e,
            onRetry: () => ref.invalidate(tasksForDayProvider(todayKey)),
          ),
          data: (tasks) {
            final open = tasks.where((t) => !t.isDone).toList();
            final done = tasks.where((t) => t.isDone).toList();
            final showDone = settings.showCompletedTasks && done.isNotEmpty;

            return CustomScrollView(
              slivers: [
                SliverPageBody(
                  sliver: SliverToBoxAdapter(
                    child: _ProgressHeader(dayKey: todayKey),
                  ),
                ),

                if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No tasks today',
                      message:
                          'Add a task, or plan tomorrow tonight so you wake '
                          'up to a ready-made day.',
                      actionLabel: 'Add task',
                      onAction: () =>
                          context.pushOnce('${Routes.taskNew}?day=$todayKey'),
                    ),
                  )
                else ...[
                  if (open.isEmpty)
                    SliverPageBody(
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.gutter,
                            vertical: AppSpacing.xxl,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration_outlined,
                                size: 18,
                                color: colors.success,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'All done for today.',
                                  style: AppTypography.body.copyWith(
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _TaskSliver(tasks: open),

                  if (showDone) ...[
                    SliverPageBody(
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.gutter,
                            AppSpacing.xl,
                            context.gutter,
                            AppSpacing.sm,
                          ),
                          child: Text(
                            'Completed · ${done.length}',
                            style: AppTypography.caption.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _TaskSliver(tasks: done),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A run of task cards. They carry their own edges and shadow, so they are
/// spaced apart rather than divided by hairlines.
class _TaskSliver extends ConsumerWidget {
  const _TaskSliver({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPageBody(
      sliver: SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: context.gutter),
        sliver: SliverList.separated(
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _TaskRow(task: tasks[i]),
        ),
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider);
    final settings = ref.watch(settingsValueProvider);
    final current = ref.watch(currentTaskProvider);

    return DismissibleTask(
      task: task,
      onComplete: () => _complete(context, controller, task),
      onDelete: () async {
        // Swiping is easy to do by accident, so this deletes immediately and
        // offers an undo rather than interrupting with a confirm dialog.
        final removed = await controller.delete(task);
        if (context.mounted) _showUndoDelete(context, controller, removed);
        return true;
      },
      child: TaskCard(
        task: task,
        use24h: settings.use24HourClock,
        isCurrent: current?.id == task.id,
        onTap: () => context.pushOnce(Routes.taskEdit(task.id)),
        onToggle: () => _complete(context, controller, task),
        onLongPress: () => _showActions(context, ref, task),
      ),
    );
  }

  void _showUndoDelete(
    BuildContext context,
    TaskController controller,
    List<Task> removed,
  ) {
    if (removed.isEmpty) return;
    context.showMessage(
      removed.length == 1
          ? 'Deleted “${removed.first.title}”'
          : 'Deleted ${removed.length} tasks',
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Undo',
      onAction: () => controller.restore(removed),
    );
  }

  Future<void> _complete(
    BuildContext context,
    TaskController controller,
    Task task,
  ) {
    // Keyed by task: completing one row must not block completing another,
    // but completing the same row twice would award its XP twice.
    return OneShot.run('task.complete.${task.id}', () async {
      final unlocked = await controller.toggleComplete(task);
      if (context.mounted && unlocked.isNotEmpty) {
        showAchievementSnack(context, unlocked.first);
      }
    });
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) => OneShot.run('task.actions.${task.id}', () async {
    final action = await showOptionsSheet<_TaskAction>(
      context,
      title: task.title,
      subtitle: 'Quick actions',
      options: const [
        SheetOption(
          value: _TaskAction.focus,
          label: 'Start focus session',
          icon: Icons.play_arrow_rounded,
        ),
        SheetOption(
          value: _TaskAction.moveToTomorrow,
          label: 'Move to tomorrow',
          subtitle: 'Reschedules this task',
          icon: Icons.east_rounded,
        ),
        SheetOption(
          value: _TaskAction.duplicateToTomorrow,
          label: 'Duplicate to tomorrow',
          subtitle: 'Keeps today’s copy',
          icon: Icons.copy_rounded,
        ),
        SheetOption(
          value: _TaskAction.skip,
          label: 'Skip today',
          icon: Icons.remove_circle_outline_rounded,
        ),
      ],
    );
    if (action == null || !context.mounted) return;

    final controller = ref.read(taskControllerProvider);
    switch (action) {
      case _TaskAction.focus:
        context.pushOnce('${Routes.focus}?taskId=${task.id}');
      case _TaskAction.moveToTomorrow:
        await controller.reschedule(task, dayKey: DateX.tomorrowKey);
      case _TaskAction.duplicateToTomorrow:
        await controller.duplicateTo(task, DateX.tomorrowKey);
      case _TaskAction.skip:
        await controller.skip(task);
    }
  });
}

/// The long-press menu on a task row.
enum _TaskAction { focus, moveToTomorrow, duplicateToTomorrow, skip }

/// Icon + label, so the overflow menu matches the option rows in every sheet.
class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: context.colors.muted),
      const SizedBox(width: AppSpacing.md),
      Text(
        label,
        style: AppTypography.body.copyWith(color: context.colors.foreground),
      ),
    ],
  );
}

/// Date, completion count and a thin progress bar — the whole header.
class _ProgressHeader extends ConsumerWidget {
  const _ProgressHeader({required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(dayStatsProvider(dayKey)).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;

    final completed = stats?.completed ?? 0;
    final total = stats?.total ?? 0;
    final progress = stats?.completionRate ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.xs,
        context.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? DateX.fullLabel(DateX.parseKey(dayKey))
                      : '${DateX.fullLabel(DateX.parseKey(dayKey))} · '
                            '$completed of $total done',
                  style: AppTypography.bodySmall.copyWith(color: colors.muted),
                ),
              ),
              if ((streak?.current ?? 0) > 0) ...[
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 15,
                  color: colors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${streak!.current}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: AppDurations.medium,
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: colors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                    value >= 1 ? colors.success : colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Plain confirmation that an achievement was unlocked.
void showAchievementSnack(BuildContext context, AchievementDefinition def) {
  context.showMessage(
    '${def.title} unlocked · +${def.xpReward} XP',
    icon: AppIcons.badge(def.iconKey),
    isSuccess: true,
    actionLabel: 'View',
    onAction: () => context.pushOnce(Routes.achievements),
  );
}
