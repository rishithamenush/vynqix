import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/page_body.dart';

/// First-run screen: brand, promise, and the three things the app does.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _highlights = [
    (
      Icons.event_note_outlined,
      'Plan tomorrow tonight',
      'Lay out your day before it starts.',
    ),
    (
      Icons.timer_outlined,
      'Focus, then rest',
      'Run tasks inside timed blocks.',
    ),
    (
      Icons.insights_outlined,
      'See your patterns',
      'Streaks, peak hours, real completion rates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        // A fixed Column with Spacers overflows the moment the window gets
        // short (landscape, split-screen). This keeps the airy spacing when
        // there is room and scrolls instead of overflowing when there is not.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: PageBody(
                maxWidth: Breakpoints.readableContent,
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: context.isShort
                            ? AppSpacing.xl
                            : AppSpacing.huge,
                      ),

                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        AppConstants.appName,
                        style: AppTypography.display.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppConstants.tagline,
                        style: AppTypography.body.copyWith(color: colors.muted),
                      ),

                      SizedBox(
                        height: context.isShort
                            ? AppSpacing.xxl
                            : AppSpacing.huge,
                      ),

                      for (final (icon, title, body) in _highlights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: 22, color: colors.primary),
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

                      SizedBox(
                        height: context.isShort
                            ? AppSpacing.lg
                            : AppSpacing.xxl,
                      ),

                      FilledButton(
                        onPressed: () => context.push(Routes.onboardingProfile),
                        child: const Text('Get started'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          'Everything stays on this device. No account needed.',
                          style: AppTypography.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
