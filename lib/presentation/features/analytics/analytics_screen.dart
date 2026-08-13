import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/token_styles.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/stats.dart';
import '../../../domain/enums/task_enums.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// Productivity charts over a selectable window.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final statsAsync = ref.watch(rangeStatsProvider);
    final streak = ref.watch(streakProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Insights',
            onPressed: () => context.pushOnce(Routes.insights),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screen),
          child: SkeletonList(count: 3),
        ),
        error: (e, _) => ErrorStateView(
          error: e,
          onRetry: () => ref.invalidate(rangeStatsProvider),
        ),
        data: (stats) {
          if (stats.totalTasks == 0) {
            return const EmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'No data yet',
              message:
                  'Complete a few tasks and your completion rate, peak hours '
                  'and category split will appear here.',
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.md,
              context.gutter,
              120,
            ),
            children: [
              PageBody(
                applyGutter: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedSelector<int>(
                      values: const [7, 30, 90],
                      selected: range,
                      labelOf: (d) => '$d days',
                      onChanged: (d) =>
                          ref.read(analyticsRangeProvider.notifier).state = d,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Two tiles on a phone, more as the window widens, so the cards
                    // never stretch into letterboxes.
                    StatGrid(
                      children: [
                        StatTile(
                          value: '${stats.totalCompleted}',
                          label: 'Tasks completed',
                          icon: Icons.check_circle_outline_rounded,
                          color: context.colors.success,
                        ),
                        StatTile(
                          value: '${(stats.completionRate * 100).round()}%',
                          label: 'Completion rate',
                          icon: Icons.percent_rounded,
                        ),
                        StatTile(
                          value: DurationX.formatMinutes(
                            stats.totalFocusMinutes,
                          ),
                          label: 'Time focused',
                          icon: Icons.timer_outlined,
                          color: context.colors.accent,
                        ),
                        StatTile(
                          value: '${streak?.current ?? 0}',
                          label: 'Day streak · best ${streak?.longest ?? 0}',
                          icon: Icons.local_fire_department_outlined,
                          color: context.colors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    _ChartCard(
                      title: 'Tasks completed',
                      subtitle: 'Last $range days',
                      child: _CompletionBarChart(stats: stats),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _ChartCard(
                      title: 'When you get things done',
                      subtitle: 'Completions by hour of day',
                      child: _HourChart(stats: stats),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _ChartCard(
                      title: 'Where your time goes',
                      subtitle: 'Completed tasks by category',
                      child: _CategoryChart(stats: stats),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (stats.moodScores.isNotEmpty)
                      _ChartCard(
                        title: 'Mood trend',
                        subtitle: 'From your daily reviews',
                        child: _MoodChart(stats: stats),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.subtitle.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(height: context.isShort ? 150 : 180, child: child),
        ],
      ),
    );
  }
}

class _CompletionBarChart extends StatelessWidget {
  const _CompletionBarChart({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // With long ranges the bars get too thin to read, so sample down.
    final days = stats.days.length > 30
        ? stats.days.sublist(stats.days.length - 30)
        : stats.days;
    final maxY = days
        .map((d) => d.total)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY + 1,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (maxY / 2).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (days.length / 6).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    DateX.shortLabel(DateX.parseKey(days[i].dayKey)),
                    style: AppTypography.caption.copyWith(
                      color: colors.muted,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].completed.toDouble(),
                  width: days.length > 14 ? 6 : 12,
                  borderRadius: BorderRadius.circular(3),
                  color: colors.primary,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: days[i].total.toDouble(),
                    color: colors.surfaceAlt,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HourChart extends StatelessWidget {
  const _HourChart({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (stats.byHour.isEmpty) {
      return Center(
        child: Text(
          'Schedule tasks with a start time to see this.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: colors.muted),
        ),
      );
    }

    final maxCount = stats.byHour.values.fold<int>(1, (a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: maxCount.toDouble() + 1,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              reservedSize: 24,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  TimeOfDayX.format(value.toInt() * 60),
                  style: AppTypography.caption.copyWith(
                    color: colors.muted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 3,
            color: colors.accent,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.accent.withValues(alpha: 0.3),
                  colors.accent.withValues(alpha: 0),
                ],
              ),
            ),
            spots: [
              for (var h = 0; h < 24; h++)
                FlSpot(h.toDouble(), (stats.byHour[h] ?? 0).toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = stats.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No completed tasks yet.',
          style: AppTypography.bodySmall.copyWith(color: colors.muted),
        ),
      );
    }

    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: entries
                  .map(
                    (e) => PieChartSectionData(
                      value: e.value.toDouble(),
                      color: e.key.color,
                      radius: 22,
                      showTitle: false,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: entries.take(6).map((e) {
              final pct = ((e.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.key.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        e.key.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppTypography.caption.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = <FlSpot>[];
    for (var i = 0; i < stats.days.length; i++) {
      final score = stats.moodScores[stats.days[i].dayKey];
      if (score != null) points.add(FlSpot(i.toDouble(), score.toDouble()));
    }

    if (points.length < 2) {
      return Center(
        child: Text(
          'Log a few daily reviews to see your mood trend.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: colors.muted),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 5,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final mood = Mood.values.firstWhere(
                  (m) => m.score == value.toInt(),
                  orElse: () => Mood.okay,
                );
                return Icon(AppIcons.mood(mood), size: 15, color: mood.color);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            curveSmoothness: 0.25,
            barWidth: 3,
            color: colors.primary,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: colors.primary,
                strokeWidth: 2,
                strokeColor: colors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
