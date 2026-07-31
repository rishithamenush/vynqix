import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/token_styles.dart';
import '../../../core/utils/date_x.dart';
import '../../providers/app_providers.dart';
import '../../providers/review_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/task_card.dart';

/// Past days, plus full-text search across every task ever created.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();

  /// Debounce so a query runs once the user pauses, not once per keystroke.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    // Clearing should feel instant; typing waits for a pause.
    if (value.isEmpty) {
      ref.read(taskSearchQueryProvider.notifier).state = '';
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(taskSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = ref.watch(taskSearchQueryProvider);
    final isSearching = query.trim().length >= 2;
    final hasText = _search.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search tasks, tags and notes',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: !hasText
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                _onQueryChanged(v);
                // Repaint so the clear button appears/disappears immediately.
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: isSearching ? const _SearchResults() : const _DayHistory(),
          ),
        ],
      ),
      backgroundColor: colors.background,
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskSearchResultsProvider);
    final settings = ref.watch(settingsValueProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.screen),
        child: SkeletonList(count: 3),
      ),
      error: (e, _) => ErrorStateView(error: e),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'Try a different word, or search by tag.',
            compact: true,
          );
        }
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.huge,
          ),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => TaskCard(
            task: tasks[i],
            showDate: true,
            dense: true,
            use24h: settings.use24HourClock,
            onTap: () => context.push(Routes.taskEdit(tasks[i].id)),
            onToggle: () =>
                ref.read(taskControllerProvider).toggleComplete(tasks[i]),
          ),
        );
      },
    );
  }
}

class _DayHistory extends ConsumerWidget {
  const _DayHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final statsAsync = ref.watch(statsForLastDaysProvider(60));
    final logs = ref.watch(allDayLogsProvider).valueOrNull ?? [];
    final logsByDay = {for (final l in logs) l.dayKey: l};

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.screen),
        child: SkeletonList(count: 4),
      ),
      error: (e, _) => ErrorStateView(error: e),
      data: (stats) {
        // Newest first, and only days that actually had something on them.
        final days = stats.days.reversed
            .where((d) => d.total > 0 || logsByDay.containsKey(d.dayKey))
            .toList();

        if (days.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No history yet',
            message:
                'Once you have completed tasks and written reviews, your past '
                'days appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.huge,
          ),
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final day = days[i];
            final date = DateX.parseKey(day.dayKey);
            final log = logsByDay[day.dayKey];

            return AppCard(
              onTap: () => context.push('${Routes.review}?day=${day.dayKey}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateX.relativeLabel(date),
                          style: AppTypography.subtitle.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      if (log?.mood != null)
                        Icon(
                          AppIcons.mood(log!.mood!),
                          size: 19,
                          color: log.mood!.color,
                        ),
                      if (day.isPerfect) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(
                          label: 'Perfect',
                          color: colors.success,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _Meta(
                        icon: Icons.check_circle_outline_rounded,
                        label: '${day.completed}/${day.total} tasks',
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      if (day.focusMinutes > 0)
                        _Meta(
                          icon: Icons.timer_outlined,
                          label: DurationX.formatMinutes(day.focusMinutes),
                        ),
                      const Spacer(),
                      Text(
                        '${(day.completionRate * 100).round()}%',
                        style: AppTypography.bodySmall.copyWith(
                          color: day.isPerfect ? colors.success : colors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (log != null && log.highlight.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        log.highlight,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.muted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
