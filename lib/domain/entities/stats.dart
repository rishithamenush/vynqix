import 'package:meta/meta.dart';

import '../enums/task_enums.dart';

/// Aggregated numbers for one day.
@immutable
class DayStats {
  const DayStats({
    required this.dayKey,
    required this.total,
    required this.completed,
    required this.missed,
    required this.plannedMinutes,
    required this.focusMinutes,
  });

  final String dayKey;
  final int total;
  final int completed;
  final int missed;

  /// Sum of the estimated durations scheduled for the day.
  final int plannedMinutes;

  /// Focus minutes actually logged.
  final int focusMinutes;

  double get completionRate => total == 0 ? 0 : completed / total;

  /// A day is "perfect" when it had tasks and every one of them was done.
  bool get isPerfect => total > 0 && completed == total;

  bool get isProductive => completed > 0;

  static const empty = DayStats(
    dayKey: '',
    total: 0,
    completed: 0,
    missed: 0,
    plannedMinutes: 0,
    focusMinutes: 0,
  );
}

/// Aggregated numbers across a date range, plus the per-day breakdown that
/// charts consume.
@immutable
class RangeStats {
  const RangeStats({
    required this.days,
    required this.byCategory,
    required this.byPriority,
    required this.byHour,
    required this.moodScores,
  });

  final List<DayStats> days;

  /// Completed task counts per category.
  final Map<TaskCategory, int> byCategory;

  /// Completed task counts per priority.
  final Map<TaskPriority, int> byPriority;

  /// Completed task counts bucketed by scheduled start hour (0–23).
  final Map<int, int> byHour;

  /// Mood score (1–5) per day key, for days that were reviewed.
  final Map<String, int> moodScores;

  int get totalTasks => days.fold(0, (s, d) => s + d.total);

  int get totalCompleted => days.fold(0, (s, d) => s + d.completed);

  int get totalMissed => days.fold(0, (s, d) => s + d.missed);

  int get totalFocusMinutes => days.fold(0, (s, d) => s + d.focusMinutes);

  int get perfectDays => days.where((d) => d.isPerfect).length;

  int get activeDays => days.where((d) => d.total > 0).length;

  double get completionRate => totalTasks == 0 ? 0 : totalCompleted / totalTasks;

  double get avgTasksPerActiveDay =>
      activeDays == 0 ? 0 : totalCompleted / activeDays;

  double get avgFocusMinutesPerActiveDay =>
      activeDays == 0 ? 0 : totalFocusMinutes / activeDays;

  double get avgMood {
    if (moodScores.isEmpty) return 0;
    final sum = moodScores.values.fold(0, (a, b) => a + b);
    return sum / moodScores.length;
  }

  /// The hour of day with the most completions, or `null` when there is no
  /// signal yet.
  int? get peakHour {
    if (byHour.isEmpty) return null;
    var best = byHour.entries.first;
    for (final e in byHour.entries) {
      if (e.value > best.value) best = e;
    }
    return best.value == 0 ? null : best.key;
  }

  TaskCategory? get topCategory {
    if (byCategory.isEmpty) return null;
    var best = byCategory.entries.first;
    for (final e in byCategory.entries) {
      if (e.value > best.value) best = e;
    }
    return best.value == 0 ? null : best.key;
  }

  static const empty = RangeStats(
    days: [],
    byCategory: {},
    byPriority: {},
    byHour: {},
    moodScores: {},
  );
}

/// Streak information derived from the day-by-day history.
@immutable
class StreakInfo {
  const StreakInfo({required this.current, required this.longest});

  final int current;
  final int longest;

  static const zero = StreakInfo(current: 0, longest: 0);
}

/// A single natural-language observation shown on the Insights screen.
@immutable
class Insight {
  const Insight({
    required this.id,
    required this.title,
    required this.body,
    required this.iconKey,
    this.tone = InsightTone.neutral,
  });

  final String id;
  final String title;
  final String body;
  /// Key into `AppIcons.insight`.
  final String iconKey;
  final InsightTone tone;
}

enum InsightTone { positive, neutral, warning }
