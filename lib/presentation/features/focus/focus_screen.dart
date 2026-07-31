import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/enums/task_enums.dart';
import '../../providers/focus_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/progress_ring.dart';

/// Minimal fullscreen Pomodoro timer.
///
/// Everything except the countdown is intentionally quiet — this screen is
/// meant to be looked at once and then ignored.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    // Bind the timer to the incoming task once the first frame is scheduled,
    // so we are not mutating providers during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(focusControllerProvider.notifier);
      final state = ref.read(focusControllerProvider);
      if (!state.isActive) {
        controller.configure(taskId: widget.taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(focusControllerProvider);
    final controller = ref.read(focusControllerProvider.notifier);
    final taskId = state.taskId ?? widget.taskId;
    final task = taskId == null
        ? null
        : ref.watch(taskByIdProvider(taskId)).valueOrNull;

    final isBreak = state.phase != FocusSessionType.focus;
    final accent = isBreak ? colors.success : colors.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(state.phase.label),
        actions: [
          if (!state.isActive)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Session length',
              onPressed: () => _pickDuration(controller),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            if (task != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    Text(
                      'WORKING ON',
                      style: AppTypography.caption.copyWith(
                        color: colors.muted,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      task.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: context.isShort ? AppSpacing.lg : AppSpacing.huge),

            ProgressRing(
              progress: state.progress,
              // Scale to the smaller viewport dimension so the ring fits in
              // landscape and on small phones without clipping.
              size: (context.screenWidth * 0.62).clamp(
                180.0,
                context.isShort ? 200.0 : 264.0,
              ),
              strokeWidth: 14,
              color: accent,
              gradient: !isBreak,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DurationX.formatClock(state.remaining),
                    style: AppTypography.timer.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.status == TimerStatus.finished
                        ? 'Complete'
                        : '${state.totalSeconds ~/ 60} minute '
                              '${isBreak ? 'break' : 'block'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Pomodoro tally.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AppConstants.pomodorosPerLongBreak, (i) {
                final done =
                    i <
                    (state.completedFocusBlocks %
                                AppConstants.pomodorosPerLongBreak ==
                            0
                        ? (state.completedFocusBlocks == 0
                              ? 0
                              : AppConstants.pomodorosPerLongBreak)
                        : state.completedFocusBlocks %
                              AppConstants.pomodorosPerLongBreak);
                return Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? accent : colors.border,
                  ),
                );
              }),
            ),

            const Spacer(),

            _Controls(state: state, controller: controller, accent: accent),

            const SizedBox(height: AppSpacing.xl),

            if (task != null && !state.isActive)
              TextButton.icon(
                onPressed: () async {
                  final unlocked = await ref
                      .read(taskControllerProvider)
                      .toggleComplete(task);
                  if (!context.mounted) return;
                  if (unlocked.isNotEmpty) {
                    context.showMessage('${unlocked.first.title} unlocked');
                  }
                  context.pop();
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark task complete'),
              ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDuration(FocusController controller) async {
    final picked = await showOptionsSheet<int>(
      context,
      title: 'Focus length',
      options: [
        for (final m in AppConstants.focusDurations)
          SheetOption(
            value: m,
            label: '$m minutes',
            icon: Icons.timer_outlined,
          ),
      ],
    );
    if (picked != null) {
      controller.configure(minutes: picked, taskId: widget.taskId);
    }
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.controller,
    required this.accent,
  });

  final FocusState state;
  final FocusController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (state.status == TimerStatus.finished) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          children: [
            Text(
              state.phase == FocusSessionType.focus
                  ? 'Block complete. Take a breath.'
                  : 'Break over. Ready for another block?',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () {
                controller.nextFocusBlock();
                controller.start();
              },
              style: FilledButton.styleFrom(backgroundColor: colors.primary),
              child: const Text('Start next block'),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.replay_rounded,
          onTap: state.isActive ? controller.stop : null,
          tooltip: 'Reset',
        ),
        const SizedBox(width: AppSpacing.xxl),
        GestureDetector(
          onTap: () {
            if (state.status == TimerStatus.running) {
              controller.pause();
            } else if (state.status == TimerStatus.paused) {
              controller.resume();
            } else {
              controller.start();
            }
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              state.status == TimerStatus.running
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        _CircleButton(
          icon: Icons.add_rounded,
          onTap: () => controller.addMinutes(5),
          tooltip: 'Add 5 minutes',
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? colors.foreground : colors.border,
          ),
        ),
      ),
    );
  }
}
