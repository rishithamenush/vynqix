import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/task.dart';
import '../../providers/app_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/task_card.dart';

/// Today's dashboard: progress, what is happening now, and the day's list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final todayKey = now.dayKey;
    final tasksAsync = ref.watch(tasksForDayProvider(todayKey));
    final settings = ref.watch(settingsValueProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksForDayProvider(todayKey));
          ref.invalidate(dayStatsProvider(todayKey));
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _TodayProgressCard()),
            const SliverToBoxAdapter(child: _NowNextSection()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Today',
                subtitle: DateX.fullLabel(now),
                actionLabel: 'Plan tomorrow',
                onAction: () {
                  ref.read(selectedDayProvider.notifier).state = DateX.tomorrow;
                  context.go(Routes.planner);
                },
              ),
            ),
            tasksAsync.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                sliver: SliverToBoxAdapter(child: SkeletonList()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorStateView(
                  error: e,
                  onRetry: () => ref.invalidate(tasksForDayProvider(todayKey)),
                ),
              ),
              data: (tasks) {
                final visible = settings.showCompletedTasks
                    ? tasks
                    : tasks.where((t) => !t.isDone).toList();

                if (visible.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.wb_sunny_outlined,
                      title: tasks.isEmpty
                          ? 'Nothing scheduled today'
                          : 'All done for today',
                      message: tasks.isEmpty
                          ? 'Add a task, or plan tomorrow tonight so you wake '
                                'up to a ready-made day.'
                          : 'Every task is complete. Take the rest of the day '
                                'back.',
                      actionLabel: tasks.isEmpty ? 'Add a task' : null,
                      onAction: () =>
                          context.push('${Routes.taskNew}?day=$todayKey'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    120,
                  ),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final task = visible[i];
                      return _TaskRow(task: task, now: now);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider);
    final settings = ref.watch(settingsValueProvider);
    final current = ref.watch(currentTaskProvider);

    return DismissibleTask(
      task: task,
      onComplete: () => _complete(context, ref, controller, task),
      onDelete: () async {
        final ok = await confirmDialog(
          context,
          title: 'Delete task?',
          message: '“${task.title}” will be removed permanently.',
        );
        if (ok) await controller.delete(task);
        return ok;
      },
      child: TaskCard(
        task: task,
        use24h: settings.use24HourClock,
        isCurrent: current?.id == task.id,
        onTap: () => context.push(Routes.taskEdit(task.id)),
        onToggle: () => _complete(context, ref, controller, task),
        onLongPress: () => _showActions(context, ref, task),
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    TaskController controller,
    Task task,
  ) async {
    final unlocked = await controller.toggleComplete(task);
    if (context.mounted && unlocked.isNotEmpty) {
      showAchievementSnack(context, unlocked.first);
    }
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final controller = ref.read(taskControllerProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Start focus session'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('${Routes.focus}?taskId=${task.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.east_rounded),
              title: const Text('Move to tomorrow'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await controller.reschedule(task, dayKey: DateX.tomorrowKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Duplicate to tomorrow'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await controller.duplicateTo(task, DateX.tomorrowKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded),
              title: const Text('Skip today'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await controller.skip(task);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileValueProvider);
    final now = ref.watch(nowProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateX.greeting(now),
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    profile.name.isEmpty
                        ? 'Ready to plan?'
                        : '${profile.name.split(' ').first} 👋',
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push(Routes.notifications),
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Reminders',
            ),
            GestureDetector(
              onTap: () => context.go(Routes.profile),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.avatarEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayProgressCard extends ConsumerWidget {
  const _TodayProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final todayKey = ref.watch(nowProvider).dayKey;
    final stats = ref.watch(dayStatsProvider(todayKey)).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    final profile = ref.watch(profileValueProvider);

    final completed = stats?.completed ?? 0;
    final total = stats?.total ?? 0;
    final progress = stats?.completionRate ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        0,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                ProgressRing(
                  progress: progress,
                  size: 96,
                  strokeWidth: 9,
                  center: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: AppTypography.title.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                        Text(
                          'done',
                          style: AppTypography.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == 0
                            ? 'No tasks yet'
                            : '$completed of $total complete',
                        style: AppTypography.subtitle.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _encouragement(completed, total, profile.dailyTaskTarget),
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          AppBadge(
                            label: '🔥 ${streak?.current ?? 0} day streak',
                            color: colors.warning,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppBadge(
                            label: 'Lv ${profile.level}',
                            color: colors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.timer_outlined,
                    label: 'Focus',
                    onTap: () => context.push(Routes.focus),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.nights_stay_outlined,
                    label: 'Review',
                    onTap: () => context.push('${Routes.review}?day=$todayKey'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Insights',
                    onTap: () => context.push(Routes.insights),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _encouragement(int done, int total, int target) {
    if (total == 0) return AppConstants.quotes.first;
    if (done == total) return 'Perfect day. Everything you planned is done.';
    if (done >= target) return 'You have hit your daily goal already.';
    if (done == 0) return 'Start with the smallest one — momentum follows.';
    return '${total - done} left. Keep the streak alive.';
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(height: AppSpacing.xs + 1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Right now" and "Up next" — the two tasks that matter at this moment.
class _NowNextSection extends ConsumerWidget {
  const _NowNextSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final current = ref.watch(currentTaskProvider);
    final next = ref.watch(nextTaskProvider);
    final settings = ref.watch(settingsValueProvider);

    if (current == null && next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xxl,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'RIGHT NOW',
                  style: AppTypography.caption.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              borderColor: colors.primary.withValues(alpha: 0.35),
              color: colors.primary.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        current.emoji ?? '🎯',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          current.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.subtitle.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (current.isScheduled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${TimeOfDayX.format(current.startMinutes!, use24h: settings.use24HourClock)}'
                      ' – ${TimeOfDayX.format(current.endMinutes!, use24h: settings.use24HourClock)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push(
                            '${Routes.focus}?taskId=${current.id}',
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Focus'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final unlocked = await ref
                                .read(taskControllerProvider)
                                .toggleComplete(current);
                            if (context.mounted && unlocked.isNotEmpty) {
                              showAchievementSnack(context, unlocked.first);
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('Done'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'UP NEXT',
              style: AppTypography.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TaskCard(
              task: next,
              dense: true,
              use24h: settings.use24HourClock,
              onTap: () => context.push(Routes.taskEdit(next.id)),
              onToggle: () =>
                  ref.read(taskControllerProvider).toggleComplete(next),
            ),
          ],
        ],
      ),
    );
  }
}

/// Celebration shown when a task completion unlocks something.
void showAchievementSnack(BuildContext context, AchievementDefinition def) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.accent,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement unlocked',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${def.title}  ·  +${def.xpReward} XP',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
