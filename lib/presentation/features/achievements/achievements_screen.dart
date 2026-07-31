import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/achievement.dart';
import '../../providers/app_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/progress_ring.dart';

/// Badges, level and XP progress.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(achievementsProvider);
    final profile = ref.watch(profileValueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screen),
          child: SkeletonList(count: 5),
        ),
        error: (e, _) => ErrorStateView(
          error: e,
          onRetry: () => ref.invalidate(achievementsProvider),
        ),
        data: (achievements) {
          final unlocked = achievements.where((a) => a.isUnlocked).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              AppSpacing.huge,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: achievements.isEmpty
                          ? 0
                          : unlocked / achievements.length,
                      size: 84,
                      strokeWidth: 8,
                      center: FittedBox(
                        child: Text(
                          '$unlocked',
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlocked of ${achievements.length} unlocked',
                            style: AppTypography.subtitle.copyWith(
                              color: colors.foreground,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Level ${profile.level} · ${profile.xp} XP total',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ProgressBar(progress: profile.levelProgress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (final achievement in achievements) ...[
                _AchievementTile(achievement: achievement),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final def = achievement.definition;
    final unlocked = achievement.isUnlocked;

    return AppCard(
      color: unlocked ? colors.warning.withValues(alpha: 0.07) : null,
      borderColor: unlocked ? colors.warning.withValues(alpha: 0.35) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked
                  ? colors.warning.withValues(alpha: 0.16)
                  : colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              AppIcons.badge(def.iconKey),
              size: 24,
              color: unlocked ? colors.warning : colors.faint,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.title,
                        style: AppTypography.subtitle.copyWith(
                          color: unlocked ? colors.foreground : colors.muted,
                        ),
                      ),
                    ),
                    if (unlocked)
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: colors.warning,
                      )
                    else
                      AppBadge(
                        label: '+${def.xpReward} XP',
                        color: colors.muted,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  def.description,
                  style: AppTypography.bodySmall.copyWith(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.md),
                if (unlocked)
                  Text(
                    'Unlocked ${DateFormat('d MMM y').format(achievement.unlockedAt!)}',
                    style: AppTypography.caption.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else ...[
                  ProgressBar(
                    progress: achievement.ratio,
                    height: 5,
                    color: colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${achievement.progress} / ${def.threshold}'
                    '${achievement.remaining > 0 ? ' · ${achievement.remaining} to go' : ''}',
                    style: AppTypography.caption.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
