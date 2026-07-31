import '../entities/day_log.dart';
import '../entities/focus_session.dart';
import '../entities/stats.dart';
import '../entities/task.dart';
import '../enums/task_enums.dart';

/// Pure aggregation of raw entities into the numbers the UI renders.
///
/// Deliberately stateless and side-effect free so it can be unit tested
/// without a database.
abstract final class StatsService {
  static DayStats dayStats({
    required String dayKey,
    required List<Task> tasks,
    required List<FocusSession> sessions,
  }) {
    final dayTasks = tasks.where((t) => t.dayKey == dayKey).toList();
    final focus = sessions.where(
      (s) => s.dayKey == dayKey && s.isFocus && s.wasCompleted,
    );
    return DayStats(
      dayKey: dayKey,
      total: dayTasks.length,
      completed: dayTasks.where((t) => t.status == TaskStatus.completed).length,
      missed: dayTasks.where((t) => t.status == TaskStatus.missed).length,
      plannedMinutes: dayTasks.fold(0, (s, t) => s + t.durationMinutes),
      focusMinutes: focus.fold(0, (s, f) => s + f.elapsedMinutes),
    );
  }

  /// Builds a [RangeStats] over [dayKeys], which must already be ordered.
  static RangeStats rangeStats({
    required List<String> dayKeys,
    required List<Task> tasks,
    required List<FocusSession> sessions,
    required List<DayLog> logs,
  }) {
    final tasksByDay = <String, List<Task>>{};
    for (final t in tasks) {
      (tasksByDay[t.dayKey] ??= []).add(t);
    }
    final sessionsByDay = <String, List<FocusSession>>{};
    for (final s in sessions) {
      (sessionsByDay[s.dayKey] ??= []).add(s);
    }

    final days = <DayStats>[];
    for (final key in dayKeys) {
      days.add(
        dayStats(
          dayKey: key,
          tasks: tasksByDay[key] ?? const [],
          sessions: sessionsByDay[key] ?? const [],
        ),
      );
    }

    final byCategory = <TaskCategory, int>{};
    final byPriority = <TaskPriority, int>{};
    final byHour = <int, int>{};
    for (final t in tasks) {
      if (t.status != TaskStatus.completed) continue;
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
      byPriority[t.priority] = (byPriority[t.priority] ?? 0) + 1;
      final start = t.startMinutes;
      if (start != null) {
        final hour = (start ~/ 60) % 24;
        byHour[hour] = (byHour[hour] ?? 0) + 1;
      }
    }

    final moodScores = <String, int>{};
    for (final log in logs) {
      final mood = log.mood;
      if (mood != null) moodScores[log.dayKey] = mood.score;
    }

    return RangeStats(
      days: days,
      byCategory: byCategory,
      byPriority: byPriority,
      byHour: byHour,
      moodScores: moodScores,
    );
  }
}
