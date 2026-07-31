import '../entities/task.dart';
import '../entities/user_profile.dart';
import '../enums/task_enums.dart';

/// A free window on a day's timeline.
class FreeSlot {
  const FreeSlot(this.startMinutes, this.endMinutes);

  final int startMinutes;
  final int endMinutes;

  int get lengthMinutes => endMinutes - startMinutes;
}

/// Timeline arithmetic: ordering, overlap detection and slot finding.
abstract final class ScheduleService {
  /// Day order used everywhere: timed tasks by start time, then untimed
  /// tasks by manual sort index, with priority breaking ties.
  static List<Task> sortForDay(List<Task> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      final aStart = a.startMinutes;
      final bStart = b.startMinutes;
      if (aStart != null && bStart != null && aStart != bStart) {
        return aStart.compareTo(bStart);
      }
      if (aStart != null && bStart == null) return -1;
      if (aStart == null && bStart != null) return 1;
      if (a.sortIndex != b.sortIndex) return a.sortIndex.compareTo(b.sortIndex);
      if (a.priority != b.priority) {
        return a.priority.sortOrder.compareTo(b.priority.sortOrder);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  /// Tasks that overlap [task] on the timeline, ignoring itself.
  static List<Task> conflictsFor(Task task, List<Task> dayTasks) {
    final start = task.startMinutes;
    if (start == null) return const [];
    final end = task.endMinutes!;
    return dayTasks.where((other) {
      if (other.id == task.id || other.startMinutes == null) return false;
      if (other.status == TaskStatus.completed) return false;
      return start < other.endMinutes! && other.startMinutes! < end;
    }).toList();
  }

  /// Gaps in the day between the profile's wake and sleep times.
  static List<FreeSlot> freeSlots({
    required List<Task> dayTasks,
    required UserProfile profile,
    int minimumMinutes = 15,
  }) {
    final busy =
        dayTasks
            .where((t) => t.startMinutes != null && t.status.isOpen)
            .map((t) => FreeSlot(t.startMinutes!, t.endMinutes!))
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final dayEnd = profile.sleepMinutes > profile.wakeMinutes
        ? profile.sleepMinutes
        : 24 * 60;

    final slots = <FreeSlot>[];
    var cursor = profile.wakeMinutes;
    for (final block in busy) {
      if (block.startMinutes > cursor) {
        final end = block.startMinutes < dayEnd ? block.startMinutes : dayEnd;
        if (end - cursor >= minimumMinutes) slots.add(FreeSlot(cursor, end));
      }
      if (block.endMinutes > cursor) cursor = block.endMinutes;
    }
    if (dayEnd - cursor >= minimumMinutes) slots.add(FreeSlot(cursor, dayEnd));
    return slots;
  }

  /// The earliest start time that fits [durationMinutes], or `null` when the
  /// day is full.
  static int? suggestStart({
    required List<Task> dayTasks,
    required UserProfile profile,
    required int durationMinutes,
    int? notBefore,
  }) {
    final floor = notBefore ?? profile.wakeMinutes;
    for (final slot in freeSlots(
      dayTasks: dayTasks,
      profile: profile,
      minimumMinutes: durationMinutes,
    )) {
      final start = slot.startMinutes < floor ? floor : slot.startMinutes;
      if (slot.endMinutes - start >= durationMinutes) return start;
    }
    return null;
  }

  /// The task currently in progress, or the one whose window contains [now].
  static Task? currentTask(List<Task> dayTasks, DateTime now) {
    for (final t in dayTasks) {
      if (t.status == TaskStatus.inProgress) return t;
    }
    for (final t in sortForDay(dayTasks)) {
      if (t.status.isOpen && t.isActiveAt(now)) return t;
    }
    return null;
  }

  /// The next upcoming task after [now].
  static Task? nextTask(List<Task> dayTasks, DateTime now) {
    final mins = now.hour * 60 + now.minute;
    for (final t in sortForDay(dayTasks)) {
      if (!t.status.isOpen) continue;
      final start = t.startMinutes;
      if (start == null) continue;
      if (start > mins) return t;
    }
    // Fall back to the first untimed open task.
    for (final t in sortForDay(dayTasks)) {
      if (t.status.isOpen && t.startMinutes == null) return t;
    }
    return null;
  }
}
