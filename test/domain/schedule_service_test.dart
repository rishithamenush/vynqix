import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/domain/entities/user_profile.dart';
import 'package:vynqix/domain/enums/task_enums.dart';
import 'package:vynqix/domain/services/schedule_service.dart';

import '../helpers/fixtures.dart';

void main() {
  const profile = UserProfile(wakeMinutes: 8 * 60, sleepMinutes: 22 * 60);

  group('sortForDay', () {
    test('timed tasks come first, in start order', () {
      final sorted = ScheduleService.sortForDay([
        task(title: 'later', startMinutes: 15 * 60),
        task(title: 'untimed'),
        task(title: 'earlier', startMinutes: 9 * 60),
      ]);

      expect(sorted.map((t) => t.title), ['earlier', 'later', 'untimed']);
    });

    test('untimed tasks fall back to manual sort index', () {
      final sorted = ScheduleService.sortForDay([
        task(title: 'c', sortIndex: 2),
        task(title: 'a', sortIndex: 0),
        task(title: 'b', sortIndex: 1),
      ]);

      expect(sorted.map((t) => t.title), ['a', 'b', 'c']);
    });
  });

  group('conflictsFor', () {
    test('detects an overlapping window', () {
      final a = task(startMinutes: 9 * 60, durationMinutes: 60);
      final b = task(startMinutes: 9 * 60 + 30, durationMinutes: 60);

      expect(ScheduleService.conflictsFor(a, [a, b]), [b]);
    });

    test('touching windows do not overlap', () {
      final a = task(startMinutes: 9 * 60, durationMinutes: 60);
      final b = task(startMinutes: 10 * 60, durationMinutes: 60);

      expect(ScheduleService.conflictsFor(a, [a, b]), isEmpty);
    });

    test('completed tasks are not conflicts', () {
      final a = task(startMinutes: 9 * 60, durationMinutes: 60);
      final b = task(
        startMinutes: 9 * 60,
        durationMinutes: 60,
        status: TaskStatus.completed,
      );

      expect(ScheduleService.conflictsFor(a, [a, b]), isEmpty);
    });

    test('unscheduled tasks never conflict', () {
      final a = task();
      expect(
        ScheduleService.conflictsFor(a, [a, task(startMinutes: 9 * 60)]),
        isEmpty,
      );
    });
  });

  group('suggestStart', () {
    test('places the first task at the wake time', () {
      final start = ScheduleService.suggestStart(
        dayTasks: const [],
        profile: profile,
        durationMinutes: 60,
      );

      expect(start, 8 * 60);
    });

    test('fits a task into the gap between two blocks', () {
      final start = ScheduleService.suggestStart(
        dayTasks: [
          task(startMinutes: 8 * 60, durationMinutes: 60),
          task(startMinutes: 11 * 60, durationMinutes: 60),
        ],
        profile: profile,
        durationMinutes: 90,
      );

      expect(start, 9 * 60);
    });

    test('skips a gap that is too small', () {
      final start = ScheduleService.suggestStart(
        dayTasks: [
          task(startMinutes: 8 * 60, durationMinutes: 60),
          task(startMinutes: 9 * 60 + 30, durationMinutes: 60),
        ],
        profile: profile,
        durationMinutes: 60,
      );

      // The 30-minute gap at 09:00 cannot hold 60 minutes, so it lands after.
      expect(start, 10 * 60 + 30);
    });

    test('returns null when the day is full', () {
      final start = ScheduleService.suggestStart(
        dayTasks: [
          task(startMinutes: 8 * 60, durationMinutes: 14 * 60),
        ],
        profile: profile,
        durationMinutes: 60,
      );

      expect(start, isNull);
    });

    test('respects a notBefore floor', () {
      final start = ScheduleService.suggestStart(
        dayTasks: const [],
        profile: profile,
        durationMinutes: 30,
        notBefore: 13 * 60,
      );

      expect(start, 13 * 60);
    });
  });

  group('currentTask / nextTask', () {
    final now = DateTime(2026, 7, 31, 10, 15);

    test('an in-progress task always wins', () {
      final running = task(status: TaskStatus.inProgress);
      final scheduled = task(
        dayKey: '2026-07-31',
        startMinutes: 10 * 60,
        durationMinutes: 60,
      );

      expect(
        ScheduleService.currentTask([scheduled, running], now)?.id,
        running.id,
      );
    });

    test('otherwise the task whose window contains now', () {
      final active = task(
        dayKey: '2026-07-31',
        startMinutes: 10 * 60,
        durationMinutes: 60,
      );
      final other = task(
        dayKey: '2026-07-31',
        startMinutes: 14 * 60,
        durationMinutes: 60,
      );

      expect(ScheduleService.currentTask([active, other], now)?.id, active.id);
    });

    test('nextTask picks the soonest task starting after now', () {
      final soon = task(dayKey: '2026-07-31', startMinutes: 11 * 60);
      final later = task(dayKey: '2026-07-31', startMinutes: 16 * 60);
      final past = task(dayKey: '2026-07-31', startMinutes: 8 * 60);

      expect(
        ScheduleService.nextTask([later, past, soon], now)?.id,
        soon.id,
      );
    });

    test('nextTask falls back to an untimed open task', () {
      final backlog = task(dayKey: '2026-07-31');
      final done = task(
        dayKey: '2026-07-31',
        startMinutes: 8 * 60,
        status: TaskStatus.completed,
      );

      expect(
        ScheduleService.nextTask([done, backlog], now)?.id,
        backlog.id,
      );
    });
  });
}
