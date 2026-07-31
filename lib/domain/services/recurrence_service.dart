import '../../core/utils/date_x.dart';
import '../entities/task.dart';
import '../enums/task_enums.dart';

/// Materialises repeating tasks into concrete per-day occurrences.
///
/// Occurrences are real rows sharing a `seriesId` rather than being computed
/// on read. That keeps every query a simple day lookup, and lets the user
/// edit or complete a single occurrence without special-casing.
abstract final class RecurrenceService {
  /// How far ahead occurrences are generated when a repeating task is saved.
  static const horizonDays = 90;

  /// Builds the occurrences of [template] after its own day, up to
  /// [horizonDays] ahead. The template itself is not included.
  static List<Task> expand(Task template, {int? horizon}) {
    if (!template.repeat.repeats) return const [];

    final seriesId = template.seriesId ?? template.id;
    final start = DateX.parseKey(template.dayKey);
    final limit = start.add(Duration(days: horizon ?? horizonDays));

    final occurrences = <Task>[];
    var cursor = _next(start, template.repeat);
    var index = 1;

    while (!cursor.isAfter(limit) && occurrences.length < 400) {
      occurrences.add(
        Task(
          id: '$seriesId-$index',
          title: template.title,
          description: template.description,
          notes: template.notes,
          emoji: template.emoji,
          dayKey: cursor.dayKey,
          category: template.category,
          priority: template.priority,
          startMinutes: template.startMinutes,
          durationMinutes: template.durationMinutes,
          tags: template.tags,
          subtasks: template.subtasks
              .map((s) => s.copyWith(isDone: false))
              .toList(),
          repeat: template.repeat,
          reminderMinutesBefore: template.reminderMinutesBefore,
          seriesId: seriesId,
          sortIndex: template.sortIndex,
          createdAt: template.createdAt,
          updatedAt: template.updatedAt,
        ),
      );
      cursor = _next(cursor, template.repeat);
      index++;
    }
    return occurrences;
  }

  static DateTime _next(DateTime from, RepeatRule rule) {
    switch (rule) {
      case RepeatRule.none:
        return from;
      case RepeatRule.daily:
        return from.add(const Duration(days: 1));
      case RepeatRule.weekdays:
        var next = from.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RepeatRule.weekly:
        return from.add(const Duration(days: 7));
      case RepeatRule.monthly:
        final month = from.month + 1;
        final year = from.year + (month > 12 ? 1 : 0);
        final normalised = month > 12 ? 1 : month;
        final lastDay = DateTime(year, normalised + 1, 0).day;
        return DateTime(
          year,
          normalised,
          from.day > lastDay ? lastDay : from.day,
        );
    }
  }
}
