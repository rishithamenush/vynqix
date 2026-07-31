import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/token_styles.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';

/// The app's primary list row: a floating, near-pill card.
///
/// Flat fills only — no gradients anywhere, deliberately. Every surface is a
/// single solid colour, and depth comes from the shadow and the hairline
/// border instead.
///
/// Layout is a standard to-do row: round checkbox, category glyph, title,
/// one quiet meta line, and the start time as a trailing pill. Colour is used
/// only where it carries meaning, so a long list stays scannable.
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

  /// Near-pill: at a row height of roughly 64–76dp this reads as a capsule
  /// without the ends collapsing into semicircles when a title wraps.
  static BorderRadius _radius(bool dense) =>
      BorderRadius.circular(dense ? AppRadius.xxl - 4 : AppRadius.xxl);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = task.isDone;
    final isMissed = task.status == TaskStatus.missed;
    final tint = isCurrent
        ? colors.primary
        : isMissed
        ? colors.error
        : task.category.color;
    final radius = _radius(dense);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCurrent ? colors.primarySoft : colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: isCurrent
              ? colors.primary.withValues(alpha: 0.35)
              : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: isDone ? 0.02 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              dense ? AppSpacing.xs : AppSpacing.sm,
              AppSpacing.md + 2,
              dense ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: _Content(
              task: task,
              isDone: isDone,
              isMissed: isMissed,
              isCurrent: isCurrent,
              tint: tint,
              use24h: use24h,
              showDate: showDate,
              onToggle: onToggle,
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.task,
    required this.isDone,
    required this.isMissed,
    required this.isCurrent,
    required this.tint,
    required this.use24h,
    required this.showDate,
    required this.onToggle,
  });

  final Task task;
  final bool isDone;
  final bool isMissed;
  final bool isCurrent;
  final Color tint;
  final bool use24h;
  final bool showDate;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Checkbox(
            isDone: isDone,
            color: task.priority == TaskPriority.high
                ? task.priority.color
                : colors.faint,
            onTap: onToggle,
          ),
          if (!isDone) ...[
            // The glyph gets its own tinted disc so the leading edge of the row
            // is two clean circles rather than a circle and a loose icon.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.category.color.withValues(alpha: 0.14),
              ),
              child: Icon(
                AppIcons.taskIcon(task.iconKey) ?? task.category.icon,
                size: 17,
                color: task.category.color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
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
                  _MetaLine(task: task, showDate: showDate, isMissed: isMissed),
                ],
              ],
            ),
          ),
          if (!isDone && task.isScheduled) ...[
            const SizedBox(width: AppSpacing.sm),
            // The pill is laid out at its natural width, so without a cap a
            // long time string at a large text scale takes the row and leaves
            // the title nothing. A third of the row is plenty for a clock.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 3),
              child: _TimePill(
                label: TimeOfDayX.format(task.startMinutes!, use24h: use24h),
                tint: isMissed || isCurrent ? tint : colors.muted,
                emphasised: isMissed || isCurrent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Start time, pulled out of the meta line and right-aligned so a list of
/// scheduled tasks reads down a single column of times.
class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.tint,
    required this.emphasised,
  });

  final String label;
  final Color tint;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: emphasised ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: tint,
          fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
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
    required this.showDate,
    required this.isMissed,
  });

  final Task task;
  final bool showDate;
  final bool isMissed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = <String>[
      if (showDate) DateX.relativeLabel(DateX.parseKey(task.dayKey)),
      task.category.label,
      DurationX.formatMinutes(task.durationMinutes),
      if (task.hasSubtasks)
        '${task.completedSubtaskCount}/${task.subtasks.length}',
    ];

    return Row(
      children: [
        if (task.repeat.repeats) ...[
          Icon(Icons.repeat_rounded, size: 12, color: colors.muted),
          const SizedBox(width: AppSpacing.xs),
        ],
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: task.category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
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
      child: SizedBox(
        // A 22dp circle is far below the 44dp minimum touch target, so the
        // visual stays small while the tappable area is padded out to 44.
        width: 44,
        height: 44,
        child: Center(
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
        borderRadius: BorderRadius.circular(AppRadius.xxl),
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
