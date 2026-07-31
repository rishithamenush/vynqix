import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/services/schedule_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/day_strip.dart';
import '../../widgets/page_body.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/task_card.dart';

/// Plan any day: pick a date, see the timeline, reorder, and check capacity.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final dayKey = selected.dayKey;
    final tasksAsync = ref.watch(tasksForDayProvider(dayKey));
    final markedDays = ref.watch(daysWithTasksProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          IconButton(
            tooltip: 'Copy today’s tasks here',
            onPressed: () => _copyFromToday(context, ref, dayKey),
            icon: const Icon(Icons.copy_all_rounded),
          ),
          IconButton(
            tooltip: 'Auto-schedule unscheduled tasks',
            onPressed: () => _autoSchedule(context, ref, dayKey),
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          DayStrip(
            selected: selected,
            markedDays: markedDays,
            onSelected: (d) =>
                ref.read(selectedDayProvider.notifier).state = d,
          ),
          const SizedBox(height: AppSpacing.md),
          PageBody(applyGutter: false, child: _CapacityBar(dayKey: dayKey)),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.screen),
                child: SkeletonList(),
              ),
              error: (e, _) => ErrorStateView(
                error: e,
                onRetry: () => ref.invalidate(tasksForDayProvider(dayKey)),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'Nothing planned for '
                        '${DateX.relativeLabel(selected).toLowerCase()}',
                    message: 'Build the day now and start it already decided.',
                    actionLabel: 'Add a task',
                    onAction: () =>
                        context.push('${Routes.taskNew}?day=$dayKey'),
                  );
                }
                return PageBody(
                  applyGutter: false,
                  child: _PlannerList(tasks: tasks, dayKey: dayKey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyFromToday(
    BuildContext context,
    WidgetRef ref,
    String targetKey,
  ) async {
    if (targetKey == DateX.todayKey) {
      context.showSnack('Pick a different day to copy today into.');
      return;
    }
    final today = await ref.read(
      tasksForDayProvider(DateX.todayKey).future,
    );
    if (today.isEmpty) {
      if (context.mounted) context.showSnack('Today has no tasks to copy.');
      return;
    }
    final controller = ref.read(taskControllerProvider);
    for (final task in today) {
      await controller.duplicateTo(task, targetKey);
    }
    if (context.mounted) {
      context.showSnack('Copied ${today.length} tasks.');
    }
  }

  Future<void> _autoSchedule(
    BuildContext context,
    WidgetRef ref,
    String dayKey,
  ) async {
    final tasks = await ref.read(tasksForDayProvider(dayKey).future);
    final profile = ref.read(profileValueProvider);
    final controller = ref.read(taskControllerProvider);

    final unscheduled = tasks.where((t) => !t.isScheduled).toList();
    if (unscheduled.isEmpty) {
      if (context.mounted) {
        context.showSnack('Everything already has a time.');
      }
      return;
    }

    var placed = [...tasks.where((t) => t.isScheduled)];
    var count = 0;
    for (final task in unscheduled) {
      final start = ScheduleService.suggestStart(
        dayTasks: placed,
        profile: profile,
        durationMinutes: task.durationMinutes,
      );
      if (start == null) break;
      final scheduled = task.copyWith(startMinutes: start);
      await controller.reschedule(task, startMinutes: start);
      placed = [...placed, scheduled];
      count++;
    }

    if (context.mounted) {
      context.showSnack(
        count == 0
            ? 'No room left in the day.'
            : 'Scheduled $count ${count == 1 ? 'task' : 'tasks'}.',
      );
    }
  }
}

/// Reorderable list, split into timed and untimed sections.
class _PlannerList extends ConsumerWidget {
  const _PlannerList({required this.tasks, required this.dayKey});

  final List<Task> tasks;
  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsValueProvider);
    final controller = ref.read(taskControllerProvider);
    final scheduled = tasks.where((t) => t.isScheduled).toList();
    final backlog = tasks.where((t) => !t.isScheduled).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.sm,
        context.gutter,
        120,
      ),
      children: [
        if (scheduled.isNotEmpty) ...[
          _MiniHeader(
            label: 'TIMELINE',
            trailing: '${scheduled.length} scheduled',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final task in scheduled) ...[
            _TimelineRow(
              task: task,
              use24h: settings.use24HourClock,
              conflicts: ScheduleService.conflictsFor(task, scheduled),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (backlog.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MiniHeader(
            label: 'UNSCHEDULED',
            trailing: 'drag to reorder',
          ),
          const SizedBox(height: AppSpacing.md),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: backlog.length,
            onReorder: (oldIndex, newIndex) {
              final reordered = [...backlog];
              if (newIndex > oldIndex) newIndex -= 1;
              reordered.insert(newIndex, reordered.removeAt(oldIndex));
              controller.reorder(reordered);
            },
            itemBuilder: (context, i) {
              final task = backlog[i];
              return Padding(
                key: ValueKey(task.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: context.colors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TaskCard(
                        task: task,
                        dense: true,
                        use24h: settings.use24HourClock,
                        onTap: () => context.push(Routes.taskEdit(task.id)),
                        onToggle: () => controller.toggleComplete(task),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
    required this.task,
    required this.use24h,
    required this.conflicts,
  });

  final Task task;
  final bool use24h;
  final List<Task> conflicts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final controller = ref.read(taskControllerProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  TimeOfDayX.format(task.startMinutes!, use24h: use24h),
                  textAlign: TextAlign.end,
                  style: AppTypography.caption.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  TimeOfDayX.format(task.endMinutes!, use24h: use24h),
                  textAlign: TextAlign.end,
                  style: AppTypography.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskCard(
                task: task,
                use24h: use24h,
                onTap: () => context.push(Routes.taskEdit(task.id)),
                onToggle: () => controller.toggleComplete(task),
              ),
              if (conflicts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: colors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Overlaps ${conflicts.first.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows how much of the waking day is already committed.
class _CapacityBar extends ConsumerWidget {
  const _CapacityBar({required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(dayStatsProvider(dayKey)).valueOrNull;
    final profile = ref.watch(profileValueProvider);

    final planned = stats?.plannedMinutes ?? 0;
    final capacity = profile.wakingMinutes;
    final ratio = capacity == 0 ? 0.0 : planned / capacity;
    final overloaded = ratio > 0.7;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overloaded
                      ? Icons.warning_amber_rounded
                      : Icons.battery_charging_full_rounded,
                  size: 16,
                  color: overloaded ? colors.warning : colors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    overloaded
                        ? 'This day is heavily booked'
                        : 'Day capacity',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${DurationX.formatMinutes(planned)} / '
                  '${DurationX.formatMinutes(capacity)}',
                  style: AppTypography.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ProgressBar(
              progress: ratio.clamp(0, 1),
              color: overloaded ? colors.warning : colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
      ],
    );
  }
}
