import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/progress_ring.dart';

/// Identity, level progress, lifetime stats and the entry point to every
/// secondary screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileValueProvider);
    final stats = ref.watch(lifetimeStatsProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    final achievements = ref.watch(achievementsProvider).valueOrNull ?? [];
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: context.gutter,
        title: const Text('You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushOnce(Routes.settings),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: PageBody(
        applyGutter: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            AppSpacing.sm,
            context.gutter,
            120,
          ),
          children: [
            // Identity row: avatar, name, level and XP progress.
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.avatarIcon(profile.avatarIconKey),
                          size: 26,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name.isEmpty
                                  ? 'Your profile'
                                  : profile.name,
                              style: AppTypography.subtitle.copyWith(
                                color: colors.foreground,
                              ),
                            ),
                            if (profile.occupation.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                profile.occupation,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppBadge(
                        label: 'Level ${profile.level}',
                        color: colors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text(
                        '${profile.xpIntoLevel} / ${profile.xpForNextLevel} XP',
                        style: AppTypography.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${profile.xp} total',
                        style: AppTypography.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressBar(progress: profile.levelProgress, height: 6),
                ],
              ),
            ),

            if (profile.goal.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                color: colors.primary.withValues(alpha: 0.06),
                borderColor: colors.primary.withValues(alpha: 0.25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORKING TOWARDS',
                            style: AppTypography.caption.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            profile.goal,
                            style: AppTypography.body.copyWith(
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
            Text(
              'LIFETIME',
              style: AppTypography.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StatGrid(
              children: [
                StatTile(
                  value: '${stats?.totalCompleted ?? 0}',
                  label: 'Tasks completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: colors.success,
                ),
                StatTile(
                  value: '${streak?.longest ?? 0}',
                  label: 'Longest streak',
                  icon: Icons.local_fire_department_outlined,
                  color: colors.warning,
                ),
                StatTile(
                  value: DurationX.formatMinutes(stats?.totalFocusMinutes ?? 0),
                  label: 'Time focused',
                  icon: Icons.timer_outlined,
                  color: colors.accent,
                ),
                StatTile(
                  value: '${stats?.perfectDays ?? 0}',
                  label: 'Perfect days',
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  trailing: '$unlockedCount / ${achievements.length}',
                  onTap: () => context.pushOnce(Routes.achievements),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Insights',
                  onTap: () => context.pushOnce(Routes.insights),
                ),
                _MenuItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => context.pushOnce(Routes.history),
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Reminders',
                  onTap: () => context.pushOnce(Routes.notifications),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.workspace_premium_outlined,
                  label: profile.isPremium ? 'Premium active' : 'Go Premium',
                  color: colors.accent,
                  onTap: () => context.pushOnce(Routes.premium),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.pushOnce(Routes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(color: colors.border, height: 1, indent: AppSpacing.huge),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = color ?? colors.foreground;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg - 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: tint),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
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
