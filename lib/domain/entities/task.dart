import 'package:meta/meta.dart';

import '../enums/task_enums.dart';
import 'subtask.dart';

/// A single scheduled unit of work.
///
/// Times are stored as *minutes since midnight* rather than `DateTime` so a
/// task can be moved between days without re-deriving a wall-clock time, and
/// the scheduled day is the canonical `yyyy-MM-dd` [dayKey].
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dayKey,
    this.description = '',
    this.notes = '',
    this.iconKey,
    this.category = TaskCategory.other,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.startMinutes,
    this.durationMinutes = 30,
    this.tags = const [],
    this.subtasks = const [],
    this.repeat = RepeatRule.none,
    this.reminderMinutesBefore,
    this.seriesId,
    this.actualMinutes = 0,
    this.sortIndex = 0,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String notes;
  /// Key into `AppIcons.taskIcons`. Null means "use the category icon".
  final String? iconKey;

  /// Scheduled day, as `yyyy-MM-dd`.
  final String dayKey;

  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;

  /// Start time in minutes since midnight. `null` means "unscheduled" —
  /// the task lives in the day's backlog rather than on the timeline.
  final int? startMinutes;

  final int durationMinutes;
  final List<String> tags;
  final List<Subtask> subtasks;
  final RepeatRule repeat;

  /// Minutes before [startMinutes] at which to surface a reminder.
  final int? reminderMinutesBefore;

  /// Groups generated occurrences of a repeating task.
  final String? seriesId;

  /// Focus minutes actually logged against this task.
  final int actualMinutes;

  /// Manual ordering within its day, used by the planner's drag-to-reorder.
  final int sortIndex;

  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// End time in minutes since midnight, or `null` when unscheduled.
  int? get endMinutes =>
      startMinutes == null ? null : startMinutes! + durationMinutes;

  bool get isScheduled => startMinutes != null;

  bool get isDone => status.isDone;

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get completedSubtaskCount => subtasks.where((s) => s.isDone).length;

  /// 0–1 completion of the checklist; 1 when the task itself is done.
  double get subtaskProgress {
    if (isDone) return 1;
    if (subtasks.isEmpty) return status == TaskStatus.inProgress ? 0.5 : 0;
    return completedSubtaskCount / subtasks.length;
  }

  /// True when the scheduled window has passed and the task is still open.
  bool isOverdue(DateTime now) {
    if (!status.isOpen || startMinutes == null) return false;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: endMinutes!));
    return dayKey.compareTo(_key(now)) < 0 ||
        (dayKey == _key(now) && now.isAfter(end));
  }

  /// True when [now] falls inside the scheduled window on the scheduled day.
  bool isActiveAt(DateTime now) {
    if (startMinutes == null || dayKey != _key(now)) return false;
    final mins = now.hour * 60 + now.minute;
    return mins >= startMinutes! && mins < endMinutes!;
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Task copyWith({
    String? title,
    String? description,
    String? notes,
    String? iconKey,
    bool clearIcon = false,
    String? dayKey,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    int? startMinutes,
    bool clearStartMinutes = false,
    int? durationMinutes,
    List<String>? tags,
    List<Subtask>? subtasks,
    RepeatRule? repeat,
    int? reminderMinutesBefore,
    bool clearReminder = false,
    String? seriesId,
    int? actualMinutes,
    int? sortIndex,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      iconKey: clearIcon ? null : (iconKey ?? this.iconKey),
      dayKey: dayKey ?? this.dayKey,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startMinutes: clearStartMinutes
          ? null
          : (startMinutes ?? this.startMinutes),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      repeat: repeat ?? this.repeat,
      reminderMinutesBefore: clearReminder
          ? null
          : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      seriesId: seriesId ?? this.seriesId,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      sortIndex: sortIndex ?? this.sortIndex,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  @override
  String toString() => 'Task($id, $title, $dayKey, ${status.id})';
}
