import 'package:meta/meta.dart';

import '../entities/day_log.dart';
import '../entities/task.dart';

enum NudgeKind { reminder, overdue, planning, review, streak, celebration }

/// One row in the notification centre.
@immutable
class Nudge {
  const Nudge({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.taskId,
    this.dayKey,
    this.atMinutes,
  });

  final String id;
  final NudgeKind kind;
  final String title;
  final String body;
  final String? taskId;
  final String? dayKey;

  /// Time of day the nudge relates to, in minutes since midnight.
  final int? atMinutes;
}

/// Derives the notification centre's contents from live data.
///
/// The app does not schedule OS notifications; these are surfaced in-app so
/// the list is always accurate rather than a snapshot of what was scheduled
/// hours ago.
abstract final class NudgeService {
  static List<Nudge> build({
    required List<Task> todayTasks,
    required List<Task> tomorrowTasks,
    required DayLog? todayLog,
    required DateTime now,
    required int planReminderMinutes,
    required int reviewReminderMinutes,
    required int currentStreak,
  }) {
    final nudges = <Nudge>[];
    final nowMinutes = now.hour * 60 + now.minute;

    // Upcoming reminders for tasks that asked for one.
    for (final task in todayTasks) {
      final start = task.startMinutes;
      final lead = task.reminderMinutesBefore;
      if (start == null || lead == null || !task.status.isOpen) continue;
      final fireAt = start - lead;
      if (fireAt < nowMinutes - 120) continue;
      nudges.add(
        Nudge(
          id: 'reminder-${task.id}',
          kind: NudgeKind.reminder,
          title: task.title,
          body: fireAt <= nowMinutes
              ? 'Starting soon'
              : 'Reminder set $lead minutes before',
          taskId: task.id,
          dayKey: task.dayKey,
          atMinutes: fireAt,
        ),
      );
    }

    // Anything whose window has already passed.
    final overdue = todayTasks.where((t) => t.isOverdue(now)).toList();
    if (overdue.isNotEmpty) {
      nudges.add(
        Nudge(
          id: 'overdue',
          kind: NudgeKind.overdue,
          title:
              '${overdue.length} ${overdue.length == 1 ? 'task is' : 'tasks are'} past due',
          body: overdue.length == 1
              ? '“${overdue.first.title}” was scheduled earlier today.'
              : 'Reschedule them or mark what actually happened.',
          taskId: overdue.length == 1 ? overdue.first.id : null,
        ),
      );
    }

    // Plan tomorrow.
    if (nowMinutes >= planReminderMinutes && tomorrowTasks.isEmpty) {
      nudges.add(
        const Nudge(
          id: 'plan-tomorrow',
          kind: NudgeKind.planning,
          title: 'Tomorrow is empty',
          body:
              'Two minutes now saves an hour of deciding in the morning. '
              'Lay out tomorrow before you switch off.',
        ),
      );
    }

    // Daily review.
    final reviewed = todayLog != null && todayLog.isComplete;
    if (nowMinutes >= reviewReminderMinutes && !reviewed) {
      nudges.add(
        const Nudge(
          id: 'review',
          kind: NudgeKind.review,
          title: 'Close the day',
          body:
              'Rate the day and note one thing to change tomorrow. '
              'It takes under a minute.',
        ),
      );
    }

    // Streak protection.
    final doneToday = todayTasks.where((t) => t.isDone).length;
    if (currentStreak > 0 && doneToday == 0 && nowMinutes > 16 * 60) {
      nudges.add(
        Nudge(
          id: 'streak',
          kind: NudgeKind.streak,
          title: 'Your $currentStreak-day streak is at risk',
          body: 'Finish one task today — even a small one — to keep it alive.',
        ),
      );
    }

    // Celebrate a cleared day.
    if (todayTasks.isNotEmpty && doneToday == todayTasks.length) {
      nudges.add(
        Nudge(
          id: 'celebrate',
          kind: NudgeKind.celebration,
          title: 'Perfect day',
          body:
              'All $doneToday ${doneToday == 1 ? 'task' : 'tasks'} complete. '
              'Nothing left to carry into tomorrow.',
        ),
      );
    }

    nudges.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return nudges;
  }
}
