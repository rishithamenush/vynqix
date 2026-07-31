import 'dart:convert';

import '../../domain/entities/day_log.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';

/// Row <-> entity conversion.
///
/// Keeping this in one file means the SQL column names appear in exactly two
/// places: the schema and here.
typedef Row = Map<String, Object?>;

extension TaskMapper on Task {
  Row toRow() => {
    'id': id,
    'title': title,
    'description': description,
    'notes': notes,
    'emoji': emoji,
    'dayKey': dayKey,
    'category': category.id,
    'priority': priority.id,
    'status': status.id,
    'startMinutes': startMinutes,
    'durationMinutes': durationMinutes,
    'tags': jsonEncode(tags),
    'subtasks': jsonEncode(subtasks.map((s) => s.toJson()).toList()),
    'repeatRule': repeat.id,
    'reminderMinutesBefore': reminderMinutesBefore,
    'seriesId': seriesId,
    'actualMinutes': actualMinutes,
    'sortIndex': sortIndex,
    'completedAt': completedAt?.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };
}

abstract final class TaskRowMapper {
  static Task fromRow(Row row) {
    return Task(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      emoji: row['emoji'] as String?,
      dayKey: row['dayKey'] as String,
      category: TaskCategory.fromId(row['category'] as String?),
      priority: TaskPriority.fromId(row['priority'] as String?),
      status: TaskStatus.fromId(row['status'] as String?),
      startMinutes: row['startMinutes'] as int?,
      durationMinutes: row['durationMinutes'] as int? ?? 30,
      tags: _decodeStringList(row['tags']),
      subtasks: _decodeSubtasks(row['subtasks']),
      repeat: RepeatRule.fromId(row['repeatRule'] as String?),
      reminderMinutesBefore: row['reminderMinutesBefore'] as int?,
      seriesId: row['seriesId'] as String?,
      actualMinutes: row['actualMinutes'] as int? ?? 0,
      sortIndex: row['sortIndex'] as int? ?? 0,
      completedAt: _dateOrNull(row['completedAt']),
      createdAt: _date(row['createdAt']),
      updatedAt: _date(row['updatedAt']),
    );
  }

  static List<String> _decodeStringList(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => '$e').toList();
    } on FormatException {
      // Corrupt payload — degrade to empty rather than losing the whole task.
    }
    return const [];
  }

  static List<Subtask> _decodeSubtasks(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Subtask.fromJson)
            .toList();
      }
    } on FormatException {
      // Same rationale as above.
    }
    return const [];
  }
}

extension DayLogMapper on DayLog {
  Row toRow() => {
    'dayKey': dayKey,
    'mood': mood?.id,
    'energy': energy?.id,
    'rating': rating,
    'highlight': highlight,
    'gratitude': gratitude,
    'blocker': blocker,
    'improvement': improvement,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };
}

abstract final class DayLogRowMapper {
  static DayLog fromRow(Row row) => DayLog(
    dayKey: row['dayKey'] as String,
    mood: Mood.fromId(row['mood'] as String?),
    energy: EnergyLevel.fromId(row['energy'] as String?),
    rating: row['rating'] as int? ?? 0,
    highlight: row['highlight'] as String? ?? '',
    gratitude: row['gratitude'] as String? ?? '',
    blocker: row['blocker'] as String? ?? '',
    improvement: row['improvement'] as String? ?? '',
    createdAt: _date(row['createdAt']),
    updatedAt: _date(row['updatedAt']),
  );
}

extension FocusSessionMapper on FocusSession {
  Row toRow() => {
    'id': id,
    'dayKey': dayKey,
    'taskId': taskId,
    'type': type.id,
    'plannedMinutes': plannedMinutes,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'endedAt': endedAt?.millisecondsSinceEpoch,
    'elapsedSeconds': elapsedSeconds,
    'wasCompleted': wasCompleted ? 1 : 0,
  };
}

abstract final class FocusSessionRowMapper {
  static FocusSession fromRow(Row row) => FocusSession(
    id: row['id'] as String,
    dayKey: row['dayKey'] as String,
    taskId: row['taskId'] as String?,
    type: FocusSessionType.fromId(row['type'] as String?),
    plannedMinutes: row['plannedMinutes'] as int? ?? 0,
    startedAt: _date(row['startedAt']),
    endedAt: _dateOrNull(row['endedAt']),
    elapsedSeconds: row['elapsedSeconds'] as int? ?? 0,
    wasCompleted: (row['wasCompleted'] as int? ?? 0) == 1,
  );
}

DateTime _date(Object? raw) =>
    DateTime.fromMillisecondsSinceEpoch(raw as int? ?? 0);

DateTime? _dateOrNull(Object? raw) =>
    raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw as int);
