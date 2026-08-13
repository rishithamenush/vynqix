import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/date_x.dart';
import 'package:vynqix/data/local/demo_data.dart';
import 'package:vynqix/domain/enums/task_enums.dart';

void main() {
  // A fixed anchor keeps every expectation below stable: the generator is
  // deterministic once "today" is pinned.
  final now = DateTime(2026, 7, 31, 14, 40);
  final data = DemoDataBuilder.build(now: now);
  final todayKey = now.dayKey;

  group('DemoDataBuilder volume', () {
    test('generates well over a thousand tasks', () {
      expect(data.tasks.length, greaterThan(1000));
      expect(data.dayLogs.length, greaterThan(150));
      expect(data.focusSessions.length, greaterThan(500));
    });

    test('covers the whole requested range with no gap around today', () {
      final days = data.tasks.map((t) => t.dayKey).toSet();
      final first = now.dateOnly.subtract(
        const Duration(days: DemoDataBuilder.defaultPastDays),
      );
      final last = now.dateOnly.add(
        const Duration(days: DemoDataBuilder.defaultFutureDays),
      );

      expect(days, contains(todayKey));
      expect(days, contains(first.dayKey));
      expect(days, contains(last.dayKey));
      // Days off aside, nearly every day should be planned.
      expect(days.length, greaterThan(340));
    });
  });

  group('DemoDataBuilder statuses', () {
    test('past days hold a mix of completed and unfinished work', () {
      final past = data.tasks.where((t) => t.dayKey.compareTo(todayKey) < 0);

      final completed = past.where((t) => t.status == TaskStatus.completed);
      final missed = past.where((t) => t.status == TaskStatus.missed);
      final skipped = past.where((t) => t.status == TaskStatus.skipped);

      expect(completed.length, greaterThan(500));
      expect(missed, isNotEmpty);
      expect(skipped, isNotEmpty);
      // Nothing in the past is left open — the app's rollover would have
      // resolved it, so seeded history must not contradict that.
      expect(past.where((t) => t.status.isOpen), isEmpty);
    });

    test('completed tasks carry a timestamp on their own day', () {
      for (final task in data.tasks.where((t) => t.isDone)) {
        expect(task.completedAt, isNotNull);
        expect(task.completedAt!.dayKey, task.dayKey);
        expect(task.actualMinutes, greaterThan(0));
        expect(task.subtasks.every((s) => s.isDone), isTrue);
      }
    });

    test('today is split by the clock', () {
      final today = data.tasks.where((t) => t.dayKey == todayKey).toList();
      expect(today, isNotEmpty);

      final nowMinutes = now.hour * 60 + now.minute;
      for (final task in today) {
        final end = task.endMinutes!;
        if (task.startMinutes! <= nowMinutes && nowMinutes < end) {
          expect(task.status, TaskStatus.inProgress);
        } else if (end > nowMinutes) {
          expect(task.status, TaskStatus.pending);
        }
      }
      expect(
        today.where((t) => t.status == TaskStatus.completed),
        isNotEmpty,
        reason: 'the morning should already be done at 14:40',
      );
    });

    test('future days are planned but untouched', () {
      final future = data.tasks.where((t) => t.dayKey.compareTo(todayKey) > 0);

      expect(future.length, greaterThan(100));
      expect(future.every((t) => t.status == TaskStatus.pending), isTrue);
      expect(future.every((t) => t.completedAt == null), isTrue);
      expect(future.every((t) => t.actualMinutes == 0), isTrue);
    });
  });

  group('DemoDataBuilder shape', () {
    test('reads as a software engineer’s week', () {
      final categories = data.tasks.map((t) => t.category).toSet();
      expect(categories, containsAll(TaskCategory.values));

      final titles = data.tasks.map((t) => t.title).toSet();
      expect(titles.any((t) => t.startsWith('Daily standup')), isTrue);
      expect(titles.any((t) => t.startsWith('Deep work')), isTrue);
      expect(titles.any((t) => t.startsWith('Sprint planning')), isTrue);
      // Enough variety that the list does not read as copy-paste.
      expect(titles.length, greaterThan(80));
    });

    test('every task is scheduled and ordered within its day', () {
      final byDay = <String, List<int>>{};
      for (final task in data.tasks) {
        expect(task.startMinutes, isNotNull);
        expect(task.durationMinutes, greaterThan(0));
        (byDay[task.dayKey] ??= []).add(task.sortIndex);
      }
      for (final indexes in byDay.values) {
        expect(indexes, List.generate(indexes.length, (i) => i));
      }
    });

    test('focus sessions belong to real tasks on the same day', () {
      final tasksById = {for (final t in data.tasks) t.id: t};
      for (final session in data.focusSessions) {
        final task = tasksById[session.taskId];
        expect(task, isNotNull);
        expect(task!.dayKey, session.dayKey);
        expect(session.startedAt.dayKey, session.dayKey);
      }
      expect(
        data.focusSessions.where((s) => s.isFocus),
        isNotEmpty,
        reason: 'breaks alone would leave the focus stats empty',
      );
    });

    test('day logs are only written for days that happened', () {
      expect(data.dayLogs, isNotEmpty);
      for (final log in data.dayLogs) {
        expect(log.dayKey.compareTo(todayKey), lessThanOrEqualTo(0));
        expect(log.isComplete, isTrue);
      }
    });

    test('xp is large enough to have earned several levels', () {
      expect(data.xp, greaterThan(5000));
    });
  });
}
