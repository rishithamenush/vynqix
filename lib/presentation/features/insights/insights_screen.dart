import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/stats.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// Plain-language analysis of the last 30 days.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screen),
          child: SkeletonList(count: 4),
        ),
        error: (e, _) => ErrorStateView(
          error: e,
          onRetry: () => ref.invalidate(insightsProvider),
        ),
        data: (insights) => PageBody(
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.accent.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Patterns found in your last 30 days. Computed on this '
                      'device — nothing is uploaded.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final insight in insights) ...[
              _InsightCard(insight: insight),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = switch (insight.tone) {
      InsightTone.positive => colors.success,
      InsightTone.warning => colors.warning,
      InsightTone.neutral => colors.primary,
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: tint.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  AppIcons.insight(insight.iconKey),
                  size: 18,
                  color: tint,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            insight.body,
            style: AppTypography.body.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
