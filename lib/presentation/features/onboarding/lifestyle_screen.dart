import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/time_field.dart';

/// Step 2 of onboarding: the daily rhythm the planner schedules around.
class LifestyleScreen extends ConsumerStatefulWidget {
  const LifestyleScreen({super.key});

  @override
  ConsumerState<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends ConsumerState<LifestyleScreen> {
  int _wake = 7 * 60;
  int _sleep = 23 * 60;
  int _workStart = 9 * 60;
  int _workEnd = 17 * 60;
  int _target = 5;

  Future<void> _finish() async {
    final notifier = ref.read(profileProvider.notifier);
    await notifier.edit(
      (p) => p.copyWith(
        wakeMinutes: _wake,
        sleepMinutes: _sleep,
        workStartMinutes: _workStart,
        workEndMinutes: _workEnd,
        dailyTaskTarget: _target,
      ),
    );
    await notifier.completeOnboarding();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final awake = _sleep > _wake ? _sleep - _wake : (_sleep - _wake) + 24 * 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Your rhythm')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'When does your day happen?',
              style: AppTypography.titleLarge.copyWith(
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The planner only suggests slots inside your waking hours, and '
              'warns you when a day is over-booked.',
              style: AppTypography.bodySmall.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppCard(
              child: Column(
                children: [
                  TimeField(
                    label: 'I wake up at',
                    icon: Icons.wb_sunny_outlined,
                    minutes: _wake,
                    onChanged: (v) => setState(() => _wake = v),
                  ),
                  Divider(color: colors.border, height: 1),
                  TimeField(
                    label: 'I go to sleep at',
                    icon: Icons.nightlight_outlined,
                    minutes: _sleep,
                    onChanged: (v) => setState(() => _sleep = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Column(
                children: [
                  TimeField(
                    label: 'Work / study starts',
                    icon: Icons.work_outline_rounded,
                    minutes: _workStart,
                    onChanged: (v) => setState(() => _workStart = v),
                  ),
                  Divider(color: colors.border, height: 1),
                  TimeField(
                    label: 'Work / study ends',
                    icon: Icons.logout_rounded,
                    minutes: _workEnd,
                    onChanged: (v) => setState(() => _workEnd = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily task goal',
                    style: AppTypography.subtitle.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'A day counts as a win at $_target completed '
                    '${_target == 1 ? 'task' : 'tasks'}.',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  Slider(
                    value: _target.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$_target',
                    onChanged: (v) => setState(() => _target = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'That gives you ${DurationX.formatMinutes(awake)} '
                      'of waking time each day.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: FilledButton(
            onPressed: _finish,
            child: const Text('Start planning'),
          ),
        ),
      ),
    );
  }
}
