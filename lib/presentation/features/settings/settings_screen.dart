import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/time_field.dart';

/// Appearance, focus defaults, reminders, profile and data management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsValueProvider);
    final profile = ref.watch(profileValueProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        maxWidth: Breakpoints.readableContent,
        applyGutter: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            AppSpacing.md,
            context.gutter,
            AppSpacing.huge,
          ),
          children: [
            _Group(
              title: 'Appearance',
              children: [
                _SwitchRow(
                  icon: Icons.schedule_rounded,
                  label: '24-hour clock',
                  value: settings.use24HourClock,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(use24HourClock: v)),
                ),
                _SwitchRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Show completed tasks',
                  subtitle: 'Keep finished tasks visible on Home',
                  value: settings.showCompletedTasks,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(showCompletedTasks: v)),
                ),
              ],
            ),

            _Group(
              title: 'Focus',
              children: [
                _StepperRow(
                  icon: Icons.timer_outlined,
                  label: 'Focus block',
                  value: settings.focusMinutes,
                  options: AppConstants.focusDurations,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(focusMinutes: v)),
                ),
                _StepperRow(
                  icon: Icons.coffee_outlined,
                  label: 'Short break',
                  value: settings.shortBreakMinutes,
                  options: AppConstants.breakDurations,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(shortBreakMinutes: v)),
                ),
                _StepperRow(
                  icon: Icons.self_improvement_rounded,
                  label: 'Long break',
                  value: settings.longBreakMinutes,
                  options: const [15, 20, 25, 30],
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(longBreakMinutes: v)),
                ),
                _SwitchRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Auto-start breaks',
                  value: settings.autoStartBreaks,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(autoStartBreaks: v)),
                ),
              ],
            ),

            _Group(
              title: 'Reminders',
              children: [
                _SwitchRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Nudges',
                  subtitle: 'Show suggestions in the reminders screen',
                  value: settings.notificationsEnabled,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(notificationsEnabled: v)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TimeField(
                    label: 'Plan tomorrow at',
                    icon: Icons.event_note_outlined,
                    minutes: settings.dailyPlanReminderMinutes,
                    use24h: settings.use24HourClock,
                    onChanged: (v) => notifier.edit(
                      (s) => s.copyWith(dailyPlanReminderMinutes: v),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TimeField(
                    label: 'Daily review at',
                    icon: Icons.nights_stay_outlined,
                    minutes: settings.reviewReminderMinutes,
                    use24h: settings.use24HourClock,
                    onChanged: (v) => notifier.edit(
                      (s) => s.copyWith(reviewReminderMinutes: v),
                    ),
                  ),
                ),
              ],
            ),

            _Group(
              title: 'Planning',
              children: [
                _SwitchRow(
                  icon: Icons.east_rounded,
                  label: 'Carry over unfinished tasks',
                  subtitle: settings.rolloverUnfinished
                      ? 'Yesterday’s leftovers move to today'
                      : 'Leftovers are marked as missed',
                  value: settings.rolloverUnfinished,
                  onChanged: (v) =>
                      notifier.edit((s) => s.copyWith(rolloverUnfinished: v)),
                ),
              ],
            ),

            _Group(
              title: 'Your day',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      TimeField(
                        label: 'Wake up',
                        icon: Icons.wb_sunny_outlined,
                        minutes: profile.wakeMinutes,
                        use24h: settings.use24HourClock,
                        onChanged: (v) => ref
                            .read(profileProvider.notifier)
                            .edit((p) => p.copyWith(wakeMinutes: v)),
                      ),
                      TimeField(
                        label: 'Sleep',
                        icon: Icons.nightlight_outlined,
                        minutes: profile.sleepMinutes,
                        use24h: settings.use24HourClock,
                        onChanged: (v) => ref
                            .read(profileProvider.notifier)
                            .edit((p) => p.copyWith(sleepMinutes: v)),
                      ),
                    ],
                  ),
                ),
                _InfoRow(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'Waking hours',
                  value: DurationX.formatMinutes(profile.wakingMinutes),
                ),
                _NavRow(
                  icon: Icons.flag_outlined,
                  label: 'Daily task goal',
                  value: '${profile.dailyTaskTarget} tasks',
                  onTap: () =>
                      _pickTarget(context, ref, profile.dailyTaskTarget),
                ),
              ],
            ),

            _Group(
              title: 'Data',
              children: [
                _NavRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Premium',
                  value: profile.isPremium ? 'Active' : 'Free',
                  onTap: () => context.push(Routes.premium),
                ),
                _NavRow(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Load sample data',
                  value: 'Demo',
                  onTap: () => _loadSampleData(context, ref),
                ),
                _NavRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Reset all data',
                  destructive: true,
                  onTap: () => _reset(context, ref),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                '${AppConstants.appName} · ${AppConstants.tagline}',
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTarget(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showOptionsSheet<int>(
      context,
      title: 'Daily target',
      subtitle: 'How many tasks count as a full day.',
      selected: current,
      options: [
        for (var i = 1; i <= 12; i++)
          SheetOption(value: i, label: '$i ${i == 1 ? 'task' : 'tasks'} a day'),
      ],
    );
    if (picked != null) {
      await ref
          .read(profileProvider.notifier)
          .edit((p) => p.copyWith(dailyTaskTarget: picked));
    }
  }

  /// Replaces the database with a year of generated history, so the app can be
  /// explored — or demoed — without spending months filling it in by hand.
  Future<void> _loadSampleData(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Load sample data?',
      message:
          'Replaces everything with an example software engineer’s year: ten '
          'months of finished and missed work, today already underway, and the '
          'next two months planned. Your current data is deleted.',
      confirmLabel: 'Replace with sample data',
    );
    if (!ok || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final database = ref.read(databaseProvider);
    final seeder = ref.read(demoDataSeederProvider);
    final rewards = ref.read(rewardsUseCaseProvider);

    await database.clearAll();
    ref.read(profileRepositoryProvider).invalidateCache();
    ref.read(settingsRepositoryProvider).invalidateCache();

    final data = await seeder.seed();

    // Backfill the badges the generated history has already earned, rather
    // than dripping them out the next time the user completes something.
    ref.read(profileRepositoryProvider).invalidateCache();
    await rewards.grant(0);

    ref.invalidate(profileProvider);
    ref.invalidate(settingsProvider);
    await ref.read(profileProvider.future);

    navigator.pop();

    if (context.mounted) {
      context.showMessage(
        '${data.tasks.length} tasks, ${data.dayLogs.length} daily reviews and '
        '${data.focusSessions.length} focus sessions loaded.',
        isSuccess: true,
        icon: Icons.auto_awesome_outlined,
      );
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Reset everything?',
      message:
          'All tasks, reviews, focus sessions, achievements and your profile '
          'will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Delete everything',
    );
    if (!ok) return;

    await ref.read(databaseProvider).clearAll();

    // Drop the memoised singletons before re-reading, or the deleted profile
    // and settings would come straight back out of the caches.
    ref.read(profileRepositoryProvider).invalidateCache();
    ref.read(settingsRepositoryProvider).invalidateCache();
    ref.invalidate(profileProvider);
    ref.invalidate(settingsProvider);

    // Wait for the fresh (default) profile so the router's onboarding
    // redirect sees the reset state rather than the stale one.
    await ref.read(profileProvider.future);

    if (context.mounted) {
      context.showMessage('All data deleted.');
      context.go(Routes.welcome);
    }
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(color: colors.border, height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(color: colors.foreground),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(color: colors.muted),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.foreground),
            ),
          ),
          DropdownButton<int>(
            value: options.contains(value) ? value : options.first,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: options
                .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg - 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.foreground),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = destructive ? colors.error : colors.foreground;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg - 2,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: destructive ? colors.error : colors.muted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: tint),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTypography.bodySmall.copyWith(color: colors.muted),
              ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }
}
