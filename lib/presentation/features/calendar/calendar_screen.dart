import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/task_card.dart';

/// Month grid with an agenda for the selected day.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // The planner defaults the shared selection to tomorrow, which is right
    // for planning but wrong here — a calendar should open on today.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selected = ref.read(selectedDayProvider);
      if (!selected.isSameDay(DateX.today)) {
        ref.read(selectedDayProvider.notifier).state = DateX.today;
        ref.read(calendarMonthProvider.notifier).state = DateTime(
          DateX.today.year,
          DateX.today.month,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = ref.watch(calendarMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final marked = ref.watch(daysWithTasksProvider).valueOrNull ?? {};
    final tasksAsync = ref.watch(tasksForDayProvider(selected.dayKey));
    final settings = ref.watch(settingsValueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.pushOnce(Routes.history),
          ),
        ],
      ),
      body: Column(
        children: [
          PageBody(
            applyGutter: false,
            child: Column(
              children: [
                _MonthHeader(month: month),
                _WeekdayLabels(),
                _MonthGrid(
                  month: month,
                  selected: selected,
                  marked: marked,
                  onSelect: (d) =>
                      ref.read(selectedDayProvider.notifier).state = d,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.border, height: 1),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.screen),
                child: SkeletonList(count: 2),
              ),
              error: (e, _) => ErrorStateView(error: e),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyState(
                    compact: true,
                    icon: Icons.event_available_outlined,
                    title: 'Nothing on ${DateX.relativeLabel(selected)}',
                    message: 'Tap the date and add something to do.',
                    actionLabel: 'Add task',
                    onAction: () => context.pushOnce(
                      '${Routes.taskNew}?day=${selected.dayKey}',
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    context.gutter,
                    AppSpacing.lg,
                    context.gutter,
                    120,
                  ),
                  itemCount: tasks.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          DateX.fullLabel(selected).toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    }
                    final task = tasks[i - 1];
                    return TaskCard(
                      task: task,
                      use24h: settings.use24HourClock,
                      onTap: () => context.pushOnce(Routes.taskEdit(task.id)),
                      onToggle: () =>
                          ref.read(taskControllerProvider).toggleComplete(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateX.monthLabel(month),
              style: AppTypography.title.copyWith(color: colors.foreground),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(calendarMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(calendarMonthProvider.notifier).state = DateTime(
                now.year,
                now.month,
              );
              ref.read(selectedDayProvider.notifier).state = DateX.today;
            },
            child: const Text('Today'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => ref.read(calendarMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      child: Row(
        children: labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: AppTypography.caption.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.marked,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Set<String> marked;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = DateX.monthGrid(month);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.gutter,
        vertical: AppSpacing.sm,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: days.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          // A square cell is too tall when the window is short, so the grid
          // flattens rather than pushing the agenda off screen.
          childAspectRatio: context.isShort ? 1.5 : 1,
        ),
        itemBuilder: (context, i) {
          final day = days[i];
          final inMonth = day.month == month.month;
          final isSelected = day.isSameDay(selected);
          final isToday = day.isToday;
          final hasTasks = marked.contains(day.dayKey);

          return GestureDetector(
            onTap: () => onSelect(day),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary.withValues(alpha: 0.5))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : inMonth
                          ? colors.foreground
                          : colors.muted.withValues(alpha: 0.4),
                      fontWeight: isToday || isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasTasks
                          ? (isSelected ? Colors.white : colors.accent)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
