import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// First-run screen: brand, promise, and the three things the app does.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _highlights = [
    (
      Icons.event_note_rounded,
      'Plan tomorrow tonight',
      'Lay out your day on a timeline before it starts.',
    ),
    (
      Icons.timer_outlined,
      'Focus, then rest',
      'Run tasks inside timed blocks and log real effort.',
    ),
    (
      Icons.insights_rounded,
      'See your patterns',
      'Streaks, peak hours and honest completion rates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.14),
              colors.background,
              colors.accent.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.accent],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  AppConstants.appName,
                  style: AppTypography.display.copyWith(
                    color: colors.foreground,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppConstants.tagline,
                  style: AppTypography.subtitle.copyWith(color: colors.muted),
                ),
                const Spacer(),
                for (final (icon, title, body) in _highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md - 2),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(icon, size: 20, color: colors.primary),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.subtitle.copyWith(
                                  color: colors.foreground,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                body,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.push(Routes.onboardingProfile),
                  child: const Text('Get started'),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'Everything stays on this device. No account needed.',
                    style: AppTypography.caption.copyWith(color: colors.muted),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
