import 'package:vynqix/domain/entities/day_log.dart';
import 'package:vynqix/domain/entities/focus_session.dart';
import 'package:vynqix/domain/entities/subtask.dart';
import 'package:vynqix/domain/entities/task.dart';
import 'package:vynqix/domain/enums/task_enums.dart';

/// Builders that keep tests readable: only the fields a test actually cares
/// about appear at the call site.
int _seq = 0;

String _nextId() => 'id-${_seq++}';

final _epoch = DateTime(2026, 1, 1);

Task task({
  String? id,
  String title = 'Task',
  String dayKey = '2026-07-31',
  TaskStatus status = TaskStatus.pending,
  TaskCategory category = TaskCategory.other,
  TaskPriority priority = TaskPriority.medium,
  int? startMinutes,
  int durationMinutes = 30,
  RepeatRule repeat = RepeatRule.none,
  String? seriesId,
  int sortIndex = 0,
  List<Subtask> subtasks = const [],
  DateTime? createdAt,
}) {
  return Task(
    id: id ?? _nextId(),
    title: title,
    dayKey: dayKey,
    status: status,
    category: category,
    priority: priority,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
    repeat: repeat,
    seriesId: seriesId,
    sortIndex: sortIndex,
    subtasks: subtasks,
    createdAt: createdAt ?? _epoch,
    updatedAt: createdAt ?? _epoch,
  );
}

Subtask subtaskDone(String title) =>
    Subtask(id: _nextId(), title: title, isDone: true);

FocusSession session({
  String? id,
  String dayKey = '2026-07-31',
  FocusSessionType type = FocusSessionType.focus,
  int plannedMinutes = 25,
  int elapsedSeconds = 0,
  bool wasCompleted = false,
  String? taskId,
}) {
  return FocusSession(
    id: id ?? _nextId(),
    dayKey: dayKey,
    type: type,
    plannedMinutes: plannedMinutes,
    startedAt: _epoch,
    elapsedSeconds: elapsedSeconds,
    wasCompleted: wasCompleted,
    taskId: taskId,
  );
}

DayLog dayLog({
  String dayKey = '2026-07-31',
  Mood? mood,
  EnergyLevel? energy,
  int rating = 0,
  String highlight = '',
}) {
  return DayLog(
    dayKey: dayKey,
    mood: mood,
    energy: energy,
    rating: rating,
    highlight: highlight,
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}
