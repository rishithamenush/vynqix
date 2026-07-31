import 'package:flutter/material.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/token_styles.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';
import 'app_card.dart';
import 'common.dart';

/// The app's primary list row.
///
/// Renders every task state — pending, running, done, missed — from one
/// widget so a task looks the same on Home, Planner, Calendar and History.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onLongPress,
    this.use24h = false,
    this.showDate = false,
    this.dense = false,
    this.isCurrent = false,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;
  final bool use24h;

  /// Shows the scheduled day — used by search and history where rows span days.
  final bool showDate;

  final bool dense;

  /// Highlights the task that is happening right now.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = task.isDone;
    final isMissed = task.status == TaskStatus.missed;
    final accent = task.category.color;

    return PressableCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.lg - 2),
      color: isCurrent ? colors.primary.withValues(alpha: 0.06) : null,
      borderColor: isCurrent ? colors.primary.withValues(alpha: 0.4) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Leading(task: task, onToggle: onToggle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: isDone ? colors.muted : colors.foreground,
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colors.muted,
                        ),
                      ),
                    ),
                    if (task.priority == TaskPriority.high && !isDone) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        task.priority.icon,
                        size: 16,
                        color: task.priority.color,
                      ),
                    ],
                  ],
                ),
                if (task.description.isNotEmpty && !dense) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (task.isScheduled)
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${TimeOfDayX.format(task.startMinutes!, use24h: use24h)}'
                            ' · ${DurationX.formatMinutes(task.durationMinutes)}',
                        color: isCurrent ? colors.primary : colors.muted,
                      )
                    else
                      _MetaChip(
                        icon: Icons.inbox_rounded,
                        label: DurationX.formatMinutes(task.durationMinutes),
                        color: colors.muted,
                      ),
                    if (showDate)
                      _MetaChip(
                        icon: Icons.calendar_today_rounded,
                        label: DateX.relativeLabel(
                          DateX.parseKey(task.dayKey),
                        ),
                        color: colors.muted,
                      ),
                    if (task.hasSubtasks)
                      _MetaChip(
                        icon: Icons.checklist_rounded,
                        label:
                            '${task.completedSubtaskCount}/${task.subtasks.length}',
                        color: colors.muted,
                      ),
                    if (task.repeat.repeats)
                      _MetaChip(
                        icon: Icons.repeat_rounded,
                        label: task.repeat.label,
                        color: colors.muted,
                      ),
                    AppBadge(
                      label: task.category.label,
                      color: accent,
                      compact: true,
                    ),
                    if (isMissed)
                      AppBadge(
                        label: 'Missed',
                        color: colors.error,
                        compact: true,
                      ),
                    if (task.status == TaskStatus.inProgress)
                      AppBadge(
                        label: 'In progress',
                        color: colors.primary,
                        compact: true,
                        filled: true,
                      ),
                  ],
                ),
                if (task.hasSubtasks && !isDone && !dense) ...[
                  const SizedBox(height: AppSpacing.md - 2),
                  ProgressBarInline(progress: task.subtaskProgress, color: accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.task, this.onToggle});

  final Task task;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = task.isDone;
    final accent = task.category.color;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDone
              ? colors.success.withValues(alpha: 0.15)
              : accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDone
                ? colors.success.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: isDone
              ? Icon(Icons.check_rounded, size: 22, color: colors.success)
              : task.emoji != null
              ? Text(task.emoji!, style: const TextStyle(fontSize: 20))
              : Icon(task.category.icon, size: 20, color: accent),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: tint),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: tint),
        ),
      ],
    );
  }
}

/// Thin subtask progress bar embedded in a task row.
class ProgressBarInline extends StatelessWidget {
  const ProgressBarInline({super.key, required this.progress, this.color});

  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        minHeight: 4,
        backgroundColor: colors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation(color ?? colors.primary),
      ),
    );
  }
}

/// Wraps a [TaskCard] with swipe-to-complete and swipe-to-delete.
class DismissibleTask extends StatelessWidget {
  const DismissibleTask({
    super.key,
    required this.task,
    required this.child,
    required this.onComplete,
    required this.onDelete,
  });

  final Task task;
  final Widget child;
  final VoidCallback onComplete;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: _swipeBackground(
        colors.success,
        Icons.check_rounded,
        task.isDone ? 'Reopen' : 'Complete',
        Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        colors.error,
        Icons.delete_outline_rounded,
        'Delete',
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
          return false;
        }
        return onDelete();
      },
      child: child,
    );
  }

  Widget _swipeBackground(
    Color color,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
