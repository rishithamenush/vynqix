import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/token_styles.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';

/// The app's primary list row.
///
/// Standard to-do layout: a round checkbox on the left, the title, and one
/// quiet meta line underneath. Colour is used only where it carries meaning —
/// the category dot and the priority flag — so a long list stays scannable.
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

  /// Marks the task that is happening right now with a tinted background.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = task.isDone;
    final isMissed = task.status == TaskStatus.missed;

    return Material(
      color: isCurrent
          ? colors.primary.withValues(alpha: 0.06)
          : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: dense ? AppSpacing.md - 2 : AppSpacing.md + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Checkbox(
                isDone: isDone,
                color: task.priority == TaskPriority.high
                    ? task.priority.color
                    : colors.muted,
                onTap: onToggle,
              ),
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
                              color: isDone
                                  ? colors.muted
                                  : colors.foreground,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.muted,
                            ),
                          ),
                        ),
                        if (task.priority == TaskPriority.high && !isDone)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: Icon(
                              Icons.flag_rounded,
                              size: 15,
                              color: task.priority.color,
                            ),
                          ),
                      ],
                    ),
                    if (!isDone) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _MetaLine(
                        task: task,
                        use24h: use24h,
                        showDate: showDate,
                        isMissed: isMissed,
                        isCurrent: isCurrent,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single line of secondary information under a task title.
///
/// Kept to one line on purpose: multiple wrapped rows of chips is what made
/// the previous design feel heavy.
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.task,
    required this.use24h,
    required this.showDate,
    required this.isMissed,
    required this.isCurrent,
  });

  final Task task;
  final bool use24h;
  final bool showDate;
  final bool isMissed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = <String>[];

    if (showDate) {
      parts.add(DateX.relativeLabel(DateX.parseKey(task.dayKey)));
    }
    if (task.isScheduled) {
      parts.add(TimeOfDayX.format(task.startMinutes!, use24h: use24h));
    }
    parts.add(DurationX.formatMinutes(task.durationMinutes));
    if (task.hasSubtasks) {
      parts.add('${task.completedSubtaskCount}/${task.subtasks.length}');
    }

    final timeColor = isMissed
        ? colors.error
        : isCurrent
        ? colors.primary
        : colors.muted;

    return Row(
      children: [
        if (task.repeat.repeats) ...[
          Icon(Icons.repeat_rounded, size: 12, color: colors.muted),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: timeColor,
              fontWeight: isMissed || isCurrent
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: task.category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 1),
        Text(
          task.category.label,
          style: AppTypography.caption.copyWith(color: colors.muted),
        ),
        if (isMissed) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Overdue',
            style: AppTypography.caption.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Round checkbox, the visual anchor of every row.
class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  final bool isDone;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Expands the tap target without moving the visual circle.
        padding: const EdgeInsets.only(top: 1, right: 2, bottom: 4),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? colors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? colors.primary : color,
              width: 1.8,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : null,
        ),
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
      background: _background(
        context,
        colors.success,
        Icons.check_rounded,
        task.isDone ? 'Reopen' : 'Complete',
        Alignment.centerLeft,
      ),
      secondaryBackground: _background(
        context,
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

  Widget _background(
    BuildContext context,
    Color color,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
