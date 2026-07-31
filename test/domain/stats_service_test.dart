import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/domain/entities/task.dart';
import 'package:vynqix/domain/enums/task_enums.dart';
import 'package:vynqix/domain/services/stats_service.dart';

import '../helpers/fixtures.dart';

void main() {
  group('StatsService.dayStats', () {
    test('counts totals, completions and misses for the day only', () {
      final stats = StatsService.dayStats(
        dayKey: '2026-07-31',
        tasks: [
          task(dayKey: '2026-07-31', status: TaskStatus.completed),
          task(dayKey: '2026-07-31', status: TaskStatus.completed),
          task(dayKey: '2026-07-31', status: TaskStatus.missed),
          task(dayKey: '2026-07-31'),
          // Different day — must be excluded.
          task(dayKey: '2026-08-01', status: TaskStatus.completed),
        ],
        sessions: const [],
      );

      expect(stats.total, 4);
      expect(stats.completed, 2);
      expect(stats.missed, 1);
      expect(stats.completionRate, 0.5);
      expect(stats.isPerfect, isFalse);
    });

    test('sums planned minutes and completed focus minutes', () {
      final stats = StatsService.dayStats(
        dayKey: '2026-07-31',
        tasks: [
          task(dayKey: '2026-07-31', durationMinutes: 45),
          task(dayKey: '2026-07-31', durationMinutes: 15),
        ],
        sessions: [
          session(elapsedSeconds: 1500, wasCompleted: true), // 25 min
          session(elapsedSeconds: 600, wasCompleted: true), // 10 min
          // Abandoned sessions do not count.
          session(elapsedSeconds: 900, wasCompleted: false),
          // Breaks do not count.
          session(
            elapsedSeconds: 300,
            wasCompleted: true,
            type: FocusSessionType.shortBreak,
          ),
        ],
      );

      expect(stats.plannedMinutes, 60);
      expect(stats.focusMinutes, 35);
    });

    test('a day where everything is done is perfect', () {
      final stats = StatsService.dayStats(
        dayKey: '2026-07-31',
        tasks: [
          task(dayKey: '2026-07-31', status: TaskStatus.completed),
          task(dayKey: '2026-07-31', status: TaskStatus.completed),
        ],
        sessions: const [],
      );

      expect(stats.isPerfect, isTrue);
      expect(stats.completionRate, 1.0);
    });

    test('an empty day is not perfect', () {
      final stats = StatsService.dayStats(
        dayKey: '2026-07-31',
        tasks: const [],
        sessions: const [],
      );

      expect(stats.isPerfect, isFalse);
      expect(stats.completionRate, 0);
    });
  });

  group('StatsService.rangeStats', () {
    test('buckets completions by category, priority and start hour', () {
      final tasks = <Task>[
        task(
          dayKey: '2026-07-30',
          status: TaskStatus.completed,
          category: TaskCategory.work,
          priority: TaskPriority.high,
          startMinutes: 9 * 60,
        ),
        task(
          dayKey: '2026-07-31',
          status: TaskStatus.completed,
          category: TaskCategory.work,
          priority: TaskPriority.low,
          startMinutes: 9 * 60 + 30,
        ),
        task(
          dayKey: '2026-07-31',
          status: TaskStatus.completed,
          category: TaskCategory.health,
          startMinutes: 18 * 60,
        ),
        // Not completed — excluded from the breakdowns.
        task(
          dayKey: '2026-07-31',
          category: TaskCategory.study,
          startMinutes: 9 * 60,
        ),
      ];

      final stats = StatsService.rangeStats(
        dayKeys: const ['2026-07-30', '2026-07-31'],
        tasks: tasks,
        sessions: const [],
        logs: const [],
      );

      expect(stats.byCategory[TaskCategory.work], 2);
      expect(stats.byCategory[TaskCategory.health], 1);
      expect(stats.byCategory[TaskCategory.study], isNull);
      expect(stats.byPriority[TaskPriority.high], 1);
      expect(stats.byHour[9], 2);
      expect(stats.byHour[18], 1);
      expect(stats.peakHour, 9);
      expect(stats.topCategory, TaskCategory.work);
      expect(stats.totalCompleted, 3);
      expect(stats.activeDays, 2);
    });

    test('produces one DayStats per requested key, even for empty days', () {
      final stats = StatsService.rangeStats(
        dayKeys: const ['2026-07-29', '2026-07-30', '2026-07-31'],
        tasks: [task(dayKey: '2026-07-30', status: TaskStatus.completed)],
        sessions: const [],
        logs: const [],
      );

      expect(stats.days, hasLength(3));
      expect(stats.days[0].total, 0);
      expect(stats.days[1].completed, 1);
      expect(stats.activeDays, 1);
      expect(stats.perfectDays, 1);
    });

    test('collects mood scores from reviewed days', () {
      final stats = StatsService.rangeStats(
        dayKeys: const ['2026-07-30', '2026-07-31'],
        tasks: const [],
        sessions: const [],
        logs: [
          dayLog(dayKey: '2026-07-30', mood: Mood.great),
          dayLog(dayKey: '2026-07-31', mood: Mood.bad),
        ],
      );

      expect(stats.moodScores['2026-07-30'], 5);
      expect(stats.moodScores['2026-07-31'], 2);
      expect(stats.avgMood, 3.5);
    });
  });
}
