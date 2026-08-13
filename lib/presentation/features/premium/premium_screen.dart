import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/async_guard.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/page_body.dart';

/// Free vs Premium comparison.
///
/// No billing SDK is wired up — the toggle flips a local flag so the premium
/// surfaces can be built and demoed. Swap `_activate` for a real purchase
/// flow when you add a store integration.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  static const _features = <(String, String, bool, bool)>[
    ('Unlimited tasks', 'Plan as far ahead as you like', true, true),
    ('Focus timer', 'Pomodoro blocks with session history', true, true),
    ('Daily review', 'Mood, energy and reflection', true, true),
    ('Analytics', 'Last 7 days', true, true),
    ('Extended analytics', '30 and 90 day windows', false, true),
    ('Insights', 'Pattern analysis across your history', false, true),
    ('Achievements', 'Full badge catalogue and XP', false, true),
    ('Data export', 'Take everything with you', false, true),
    ('Themes', 'Additional colour schemes', false, true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileValueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Premium'),
      ),
      body: PageBody(
        maxWidth: Breakpoints.readableContent,
        applyGutter: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            AppSpacing.sm,
            context.gutter,
            AppSpacing.huge,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    profile.isPremium
                        ? 'Premium is active'
                        : 'Get the full picture',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    profile.isPremium
                        ? 'Every feature is unlocked. Thank you.'
                        : 'Deeper analytics, pattern insights and the full '
                              'achievement catalogue.',
                    style: AppTypography.body.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          width: 56,
                          child: Text(
                            'Free',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 66,
                          child: Text(
                            'Premium',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final (title, subtitle, free, premium) in _features) ...[
                    Divider(color: colors.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colors.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: AppTypography.caption.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Icon(
                              free ? Icons.check_rounded : Icons.remove_rounded,
                              size: 18,
                              color: free ? colors.success : colors.border,
                            ),
                          ),
                          SizedBox(
                            width: 66,
                            child: Icon(
                              premium
                                  ? Icons.check_rounded
                                  : Icons.remove_rounded,
                              size: 18,
                              color: premium ? colors.accent : colors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (profile.isPremium)
              OutlinedButton(
                onPressed: () => ref
                    .read(profileProvider.notifier)
                    .edit((p) => p.copyWith(isPremium: false)),
                child: const Text('Turn off premium'),
              )
            else
              FilledButton(
                onPressed: () => _activate(context, ref),
                child: const Text('Unlock Premium'),
              ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'No billing is connected in this build.',
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) {
    return OneShot.run('premium.activate', () async {
      await ref
          .read(profileProvider.notifier)
          .edit((p) => p.copyWith(isPremium: true));
      if (!context.mounted) return;
      // Awaited: `showMessage` pushes a dialog, so popping straight after it
      // takes the dialog down instead of this screen.
      await context.showMessage('Premium features unlocked.');
      if (context.mounted) context.popIfCurrent();
    });
  }
}
