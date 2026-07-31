import 'package:flutter/material.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_x.dart';

/// Horizontal week-at-a-glance date picker used above the planner.
class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.daysBefore = 3,
    this.daysAfter = 17,
    this.markedDays = const {},
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int daysBefore;
  final int daysAfter;

  /// Day keys that should show a dot because they have tasks.
  final Set<String> markedDays;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  /// Width of a chip plus its separator, used to centre the initial scroll.
  static const _itemExtent = 56.0 + AppSpacing.sm;

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _offsetFor(widget.selected),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> get _days {
    final start = DateX.today.subtract(Duration(days: widget.daysBefore));
    return List.generate(
      widget.daysBefore + widget.daysAfter + 1,
      (i) => start.add(Duration(days: i)),
    );
  }

  double _offsetFor(DateTime date) {
    final index = _days.indexWhere((d) => d.isSameDay(date));
    if (index <= 1) return 0;
    return (index - 1) * _itemExtent;
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;

    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => _DayChip(
          date: days[i],
          isSelected: days[i].isSameDay(widget.selected),
          hasTasks: widget.markedDays.contains(days[i].dayKey),
          onTap: () => widget.onSelected(days[i]),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.hasTasks,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool hasTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isToday = date.isToday;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 56,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : isToday
                ? colors.primary.withValues(alpha: 0.45)
                : colors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateX.weekdayInitial(date).toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white70 : colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${date.day}',
              style: AppTypography.subtitle.copyWith(
                color: isSelected ? Colors.white : colors.foreground,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTasks
                    ? (isSelected ? Colors.white : colors.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
