/// Generates a realistic year of history for a working software engineer.
///
/// This exists so every screen — Home, Planner, Calendar, Analytics, Insights,
/// Achievements — can be looked at with believable data instead of an empty
/// state. Nothing here is used by the normal app flow; it is triggered on
/// demand from Settings.
///
/// The generator is **deterministic**: it runs off a fixed [Random] seed, so
/// the same day always produces the same timetable and screenshots stay
/// reproducible. Only the anchor date ("today") moves.
library;

import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/day_log.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';
import '../../domain/repositories/repositories.dart';

/// Everything a seed run produces, before it is written to storage.
class DemoDataset {
  const DemoDataset({
    required this.tasks,
    required this.dayLogs,
    required this.focusSessions,
    required this.xp,
  });

  final List<Task> tasks;
  final List<DayLog> dayLogs;
  final List<FocusSession> focusSessions;

  /// XP earned by the generated history, before achievement bonuses.
  final int xp;

  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;

  int get totalRecords => tasks.length + dayLogs.length + focusSessions.length;
}

/// Builds a [DemoDataset]. Pure — it touches no storage and no clock beyond
/// the [now] it is handed.
abstract final class DemoDataBuilder {
  /// How far back the generated history reaches.
  static const defaultPastDays = 300;

  /// How far ahead the generated plan reaches.
  static const defaultFutureDays = 60;

  static const _seed = 20260731;

  static DemoDataset build({
    DateTime? now,
    int pastDays = defaultPastDays,
    int futureDays = defaultFutureDays,
  }) {
    final anchor = (now ?? DateTime.now());
    final today = anchor.dateOnly;
    final nowMinutes = anchor.hour * 60 + anchor.minute;
    final rnd = Random(_seed);

    final tasks = <Task>[];
    final logs = <DayLog>[];
    final sessions = <FocusSession>[];
    var xp = 0;
    var taskSeq = 0;
    var sessionSeq = 0;

    final first = today.subtract(Duration(days: pastDays));
    final last = today.add(Duration(days: futureDays));

    for (final day in DateX.daysBetween(first, last)) {
      final offset = day.difference(today).inDays;
      final isPast = offset < 0;
      final isToday = offset == 0;

      // A handful of days off: travel, illness, a long weekend. They keep the
      // streak charts from looking like a metronome.
      final dayOff = isPast && rnd.nextDouble() < 0.05;

      final slots = _slotsForDay(day, rnd)
        ..sort((a, b) => a.start.compareTo(b.start));

      final dayTasks = <Task>[];
      for (final slot in slots) {
        if (dayOff && !slot.essential) continue;
        // The far future is a sketch, not a full plan — only the standing
        // commitments are on the calendar three weeks out.
        if (offset > 21 && !slot.essential && rnd.nextDouble() > 0.35) continue;

        final id = 'demo-task-${(taskSeq++).toString().padLeft(5, '0')}';
        final end = slot.start + slot.duration;

        final TaskStatus status;
        if (isPast) {
          status = _pastStatus(slot, offset, pastDays, rnd);
        } else if (isToday) {
          status = _todayStatus(slot, end, nowMinutes, rnd);
        } else {
          status = TaskStatus.pending;
        }

        final done = status == TaskStatus.completed;
        final createdAt = day
            .subtract(const Duration(days: 1))
            .add(Duration(minutes: 20 * 60 + rnd.nextInt(90)));
        final completedAt = done
            ? day.add(Duration(minutes: end - rnd.nextInt(12)))
            : null;

        final actual = switch (status) {
          TaskStatus.completed => _jitter(slot.duration, 0.25, rnd),
          TaskStatus.inProgress => (nowMinutes - slot.start).clamp(
            0,
            slot.duration,
          ),
          _ => 0,
        };

        dayTasks.add(
          Task(
            id: id,
            title: slot.title,
            description: slot.description,
            iconKey: slot.icon,
            dayKey: day.dayKey,
            category: slot.category,
            priority: slot.priority,
            status: status,
            startMinutes: slot.start,
            durationMinutes: slot.duration,
            tags: slot.tags,
            subtasks: _checklist(id, slot.checklist, status, rnd),
            repeat: slot.repeat,
            reminderMinutesBefore: slot.reminder,
            seriesId: slot.seriesKey == null ? null : 'demo-${slot.seriesKey}',
            actualMinutes: actual,
            sortIndex: dayTasks.length,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: completedAt ?? createdAt,
          ),
        );

        if (done) xp += _xpFor(slot.priority);
      }

      tasks.addAll(dayTasks);

      if (isPast || isToday) {
        for (final task in dayTasks) {
          if (task.status != TaskStatus.completed) continue;
          for (final session in _sessionsFor(task, day, rnd, () {
            return 'demo-focus-${(sessionSeq++).toString().padLeft(5, '0')}';
          })) {
            sessions.add(session);
            if (session.isFocus && session.wasCompleted) {
              xp += AppConstants.xpPerFocusSession;
            }
          }
        }
      }

      // Reviews are written in the evening, so today only has one once the
      // day is effectively over.
      final reviewable = isPast || (isToday && nowMinutes >= 21 * 60);
      if (reviewable && !dayOff && rnd.nextDouble() < 0.82) {
        logs.add(_dayLog(day, dayTasks, rnd));
        xp += AppConstants.xpPerReview;
      }
    }

    return DemoDataset(
      tasks: tasks,
      dayLogs: logs,
      focusSessions: sessions,
      xp: xp,
    );
  }

  // -------------------------------------------------------------------------
  // Status
  // -------------------------------------------------------------------------

  /// Completion odds for a past task.
  ///
  /// The base rate climbs across the history so the analytics trend lines have
  /// a story: the user started out patchy and got steadily better, with a bad
  /// week every couple of months.
  static TaskStatus _pastStatus(
    _Slot slot,
    int offset,
    int pastDays,
    Random rnd,
  ) {
    final progress = 1 - (offset.abs() / pastDays);
    var p = 0.54 + 0.32 * progress;

    p += switch (slot.category) {
      TaskCategory.health || TaskCategory.personal => 0.10,
      TaskCategory.work => 0.06,
      TaskCategory.social || TaskCategory.finance => 0.02,
      TaskCategory.study => -0.06,
      TaskCategory.creative => -0.12,
      TaskCategory.other => 0,
    };
    p += switch (slot.priority) {
      TaskPriority.high => 0.08,
      TaskPriority.medium => 0,
      TaskPriority.low => -0.10,
    };

    // A rough patch roughly every eight weeks.
    if ((offset.abs() ~/ 7) % 8 == 3) p *= 0.62;

    if (rnd.nextDouble() < p.clamp(0.05, 0.97)) return TaskStatus.completed;
    return rnd.nextDouble() < 0.68 ? TaskStatus.missed : TaskStatus.skipped;
  }

  /// Today is split by the clock: finished behind, running now, planned ahead.
  static TaskStatus _todayStatus(
    _Slot slot,
    int end,
    int nowMinutes,
    Random rnd,
  ) {
    if (nowMinutes >= slot.start && nowMinutes < end) {
      return TaskStatus.inProgress;
    }
    if (end > nowMinutes) return TaskStatus.pending;
    if (rnd.nextDouble() < 0.82) return TaskStatus.completed;
    return rnd.nextDouble() < 0.5 ? TaskStatus.missed : TaskStatus.pending;
  }

  static int _xpFor(TaskPriority priority) => switch (priority) {
    TaskPriority.high => (AppConstants.xpPerTask * 1.5).round(),
    TaskPriority.medium => AppConstants.xpPerTask,
    TaskPriority.low => (AppConstants.xpPerTask * 0.7).round(),
  };

  static int _jitter(int value, double spread, Random rnd) {
    final delta = (value * spread * (rnd.nextDouble() * 2 - 1)).round();
    return (value + delta).clamp(5, 600);
  }

  // -------------------------------------------------------------------------
  // Checklists
  // -------------------------------------------------------------------------

  static List<Subtask> _checklist(
    String taskId,
    List<String> titles,
    TaskStatus status,
    Random rnd,
  ) {
    if (titles.isEmpty) return const [];
    final done = switch (status) {
      TaskStatus.completed => titles.length,
      TaskStatus.inProgress => 1 + rnd.nextInt(titles.length),
      TaskStatus.pending => 0,
      _ => rnd.nextInt(titles.length),
    };
    return [
      for (var i = 0; i < titles.length; i++)
        Subtask(
          id: '$taskId-sub-$i',
          title: titles[i],
          isDone: i < done,
          sortIndex: i,
        ),
    ];
  }

  // -------------------------------------------------------------------------
  // Focus sessions
  // -------------------------------------------------------------------------

  /// Deep-work tasks get Pomodoro blocks logged against them, each followed by
  /// a break, so the focus history lines up with what was actually done.
  static Iterable<FocusSession> _sessionsFor(
    Task task,
    DateTime day,
    Random rnd,
    String Function() nextId,
  ) sync* {
    if (!task.deservesFocus) return;
    if (rnd.nextDouble() > 0.72) return;

    final blocks = (task.durationMinutes ~/ 30).clamp(1, 4);
    var cursor = task.startMinutes ?? 9 * 60;

    for (var i = 0; i < blocks; i++) {
      final planned = 25;
      final completed = rnd.nextDouble() < 0.86;
      final elapsed = completed
          ? planned * 60
          : (planned * 60 * (0.3 + rnd.nextDouble() * 0.5)).round();
      final startedAt = day.add(Duration(minutes: cursor));

      yield FocusSession(
        id: nextId(),
        dayKey: day.dayKey,
        taskId: task.id,
        type: FocusSessionType.focus,
        plannedMinutes: planned,
        startedAt: startedAt,
        endedAt: startedAt.add(Duration(seconds: elapsed)),
        elapsedSeconds: elapsed,
        wasCompleted: completed,
      );
      cursor += planned;

      final isLong = (i + 1) % AppConstants.pomodorosPerLongBreak == 0;
      final breakMinutes = isLong ? 15 : 5;
      final breakStart = day.add(Duration(minutes: cursor));
      yield FocusSession(
        id: nextId(),
        dayKey: day.dayKey,
        taskId: task.id,
        type: isLong ? FocusSessionType.longBreak : FocusSessionType.shortBreak,
        plannedMinutes: breakMinutes,
        startedAt: breakStart,
        endedAt: breakStart.add(Duration(minutes: breakMinutes)),
        elapsedSeconds: breakMinutes * 60,
        wasCompleted: true,
      );
      cursor += breakMinutes;
    }
  }

  // -------------------------------------------------------------------------
  // Daily review
  // -------------------------------------------------------------------------

  static DayLog _dayLog(DateTime day, List<Task> dayTasks, Random rnd) {
    final total = dayTasks.length;
    final done = dayTasks.where((t) => t.status == TaskStatus.completed).length;
    final rate = total == 0 ? 0.0 : done / total;

    final mood = switch (rate) {
      >= 0.9 => Mood.great,
      >= 0.7 => Mood.good,
      >= 0.45 => Mood.okay,
      >= 0.25 => Mood.bad,
      _ => Mood.terrible,
    };
    final energy = switch (rate) {
      >= 0.75 => EnergyLevel.high,
      >= 0.4 => EnergyLevel.medium,
      _ => EnergyLevel.low,
    };
    final rating = (1 + (rate * 4).round()).clamp(1, 5);

    final writtenAt = day.add(Duration(minutes: 22 * 60 + rnd.nextInt(60)));

    return DayLog(
      dayKey: day.dayKey,
      mood: mood,
      energy: energy,
      rating: rating,
      highlight: _pick(rate >= 0.6 ? _goodHighlights : _flatHighlights, rnd),
      gratitude: _pick(_gratitudes, rnd),
      blocker: rate >= 0.85 ? '' : _pick(_blockers, rnd),
      improvement: _pick(_improvements, rnd),
      createdAt: writtenAt,
      updatedAt: writtenAt,
    );
  }

  // -------------------------------------------------------------------------
  // The timetable
  // -------------------------------------------------------------------------

  /// The slots that apply to [day], after rolling for the optional ones.
  static List<_Slot> _slotsForDay(DateTime day, Random rnd) {
    final weekday = day.weekday;
    final slots = <_Slot>[];

    for (final template in _templates) {
      if (!template.weekdays.contains(weekday)) continue;
      if (template.chance < 1 && rnd.nextDouble() > template.chance) continue;
      slots.add(template.resolve(rnd));
    }

    // Calendar-driven one-offs.
    if (day.day == 1) {
      slots.add(
        _Slot(
          title: 'Pay rent, utilities and subscriptions',
          start: _t(18, 30),
          duration: 30,
          category: TaskCategory.finance,
          priority: TaskPriority.high,
          icon: 'money',
          tags: const ['money', 'monthly'],
          reminder: 30,
          essential: true,
        ),
      );
    }
    if (day.day == 26) {
      slots.add(
        _Slot(
          title: 'Review monthly budget and savings',
          start: _t(19, 0),
          duration: 45,
          category: TaskCategory.finance,
          icon: 'money',
          tags: const ['money', 'monthly'],
          checklist: const [
            'Categorise last month’s spend',
            'Move surplus to savings',
            'Check subscription creep',
          ],
        ),
      );
    }

    return slots;
  }

  static const _templates = <_Template>[
    // --- Morning routine -------------------------------------------------
    _Template(
      title: 'Morning run',
      hour: 6, minute: 30,
      duration: 45,
      category: TaskCategory.health,
      icon: 'workout',
      tags: ['routine', 'fitness'],
      weekdays: _weekdays,
      chance: 0.8,
      repeat: RepeatRule.weekdays,
      seriesKey: 'morning-run',
      essential: true,
    ),
    _Template(
      title: 'Long run',
      hour: 8, minute: 0,
      duration: 75,
      category: TaskCategory.health,
      icon: 'workout',
      tags: ['routine', 'fitness'],
      weekdays: {DateTime.saturday},
      chance: 0.75,
    ),
    _Template(
      title: 'Breakfast and tech newsletters',
      hour: 7, minute: 30,
      duration: 30,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'meal',
      tags: ['routine'],
      chance: 0.85,
      repeat: RepeatRule.daily,
      seriesKey: 'breakfast',
    ),
    _Template(
      title: 'Commute — podcast: {}',
      pool: [
        'Software Engineering Daily',
        'The Changelog',
        'Syntax',
        'CoRecursive',
        'Signals & Threads',
      ],
      hour: 8, minute: 15,
      duration: 30,
      category: TaskCategory.other,
      priority: TaskPriority.low,
      icon: 'travel',
      tags: ['commute'],
      weekdays: _weekdays,
      chance: 0.45,
    ),

    // --- Core engineering day --------------------------------------------
    _Template(
      title: 'Triage inbox, Slack and alerts',
      hour: 8, minute: 50,
      duration: 20,
      category: TaskCategory.work,
      priority: TaskPriority.low,
      icon: 'email',
      tags: ['admin'],
      weekdays: _weekdays,
      chance: 0.9,
    ),
    _Template(
      title: 'Daily standup',
      hour: 9, minute: 15,
      duration: 15,
      category: TaskCategory.work,
      icon: 'meeting',
      tags: ['ceremony', 'team'],
      weekdays: _weekdays,
      repeat: RepeatRule.weekdays,
      seriesKey: 'standup',
      reminder: 10,
      essential: true,
    ),
    _Template(
      title: 'Review open pull requests',
      hour: 9, minute: 35,
      duration: 40,
      category: TaskCategory.work,
      icon: 'code',
      tags: ['review', 'team'],
      weekdays: _weekdays,
      chance: 0.9,
      description: 'Unblock the team before starting my own work.',
      checklist: [
        'Read the description and linked ticket',
        'Pull the branch and run it locally',
        'Leave actionable comments',
      ],
    ),
    _Template(
      title: 'Deep work — implement {}',
      pool: [
        'the refresh-token rotation flow',
        'the offline sync queue',
        'the Stripe webhook handler',
        'search indexing for the catalogue',
        'the push notification service',
        'role-based access control',
        'the CSV export endpoint',
        'rate limiting on the public API',
        'the image upload pipeline',
        'the GraphQL schema for orders',
        'feature flags for the new checkout',
        'websocket presence tracking',
        'the multi-tenant database migration',
        'the audit log service',
        'pagination on the activity feed',
        'the retry policy for failed jobs',
      ],
      hour: 10, minute: 20,
      duration: 120,
      category: TaskCategory.work,
      priority: TaskPriority.high,
      icon: 'code',
      tags: ['deep-work', 'backend'],
      weekdays: _weekdays,
      reminder: 15,
      essential: true,
      description: 'Phones face down, Slack on do-not-disturb.',
      checklist: [
        'Write the short design note',
        'Build the happy path',
        'Cover the edge cases with tests',
        'Open the pull request',
      ],
    ),
    _Template(
      title: 'Lunch',
      hour: 12, minute: 30,
      duration: 45,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'meal',
      tags: ['routine'],
      chance: 0.95,
      repeat: RepeatRule.daily,
      seriesKey: 'lunch',
    ),

    // --- The weekly meeting rhythm ---------------------------------------
    _Template(
      title: 'Sprint planning',
      hour: 13, minute: 20,
      duration: 60,
      category: TaskCategory.work,
      icon: 'meeting',
      tags: ['ceremony', 'team'],
      weekdays: {DateTime.monday},
      repeat: RepeatRule.weekly,
      seriesKey: 'sprint-planning',
      reminder: 15,
      essential: true,
    ),
    _Template(
      title: 'Design sync with product',
      hour: 13, minute: 20,
      duration: 45,
      category: TaskCategory.work,
      icon: 'design',
      tags: ['team', 'product'],
      weekdays: {DateTime.tuesday},
      chance: 0.85,
    ),
    _Template(
      title: '1:1 with my engineering manager',
      hour: 13, minute: 20,
      duration: 30,
      category: TaskCategory.work,
      icon: 'call',
      tags: ['team', 'growth'],
      weekdays: {DateTime.wednesday},
      repeat: RepeatRule.weekly,
      seriesKey: 'one-on-one',
      reminder: 15,
      essential: true,
    ),
    _Template(
      title: 'Architecture review — {}',
      pool: [
        'event-driven order processing',
        'splitting the monolith',
        'the caching strategy',
        'the new service boundaries',
        'moving to trunk-based development',
      ],
      hour: 13, minute: 20,
      duration: 60,
      category: TaskCategory.work,
      icon: 'idea',
      tags: ['team', 'architecture'],
      weekdays: {DateTime.thursday},
      chance: 0.7,
    ),
    _Template(
      title: 'Sprint retrospective',
      hour: 13, minute: 20,
      duration: 45,
      category: TaskCategory.work,
      icon: 'meeting',
      tags: ['ceremony', 'team'],
      weekdays: {DateTime.friday},
      repeat: RepeatRule.weekly,
      seriesKey: 'retro',
      essential: true,
    ),

    // --- Afternoon --------------------------------------------------------
    _Template(
      title: '{}',
      pool: [
        'Fix bug — race condition in the sync worker',
        'Fix bug — timezone drift on recurring reminders',
        'Fix bug — memory leak in the image cache',
        'Fix bug — duplicate charges on retried payments',
        'Refactor the settings repository',
        'Refactor the legacy auth middleware',
        'Debug the flaky end-to-end suite',
        'Optimise the slow dashboard query',
        'Cut down the cold-start time',
        'Migrate the deprecated HTTP client',
        'Reduce the bundle size',
        'Harden the error handling in the API layer',
      ],
      hour: 14, minute: 30,
      duration: 90,
      category: TaskCategory.work,
      priority: TaskPriority.high,
      icon: 'code',
      tags: ['deep-work', 'maintenance'],
      weekdays: _weekdays,
      chance: 0.9,
      checklist: [
        'Reproduce it reliably',
        'Write a failing test',
        'Ship the fix',
      ],
    ),
    _Template(
      title: 'Write tests for {}',
      pool: [
        'the scheduling service',
        'the recurrence rules',
        'the payment reconciliation job',
        'the permissions layer',
        'the stats aggregation',
      ],
      hour: 16, minute: 10,
      duration: 45,
      category: TaskCategory.work,
      icon: 'task',
      tags: ['quality'],
      weekdays: _weekdays,
      chance: 0.6,
    ),
    _Template(
      title: 'Update the board and write standup notes',
      hour: 17, minute: 0,
      duration: 20,
      category: TaskCategory.work,
      priority: TaskPriority.low,
      icon: 'note',
      tags: ['admin'],
      weekdays: _weekdays,
      chance: 0.7,
    ),
    _Template(
      title: 'Deploy to staging and verify',
      hour: 17, minute: 30,
      duration: 30,
      category: TaskCategory.work,
      priority: TaskPriority.high,
      icon: 'urgent',
      tags: ['release'],
      weekdays: {DateTime.thursday},
      chance: 0.8,
      checklist: [
        'Run the migration on staging',
        'Smoke-test the critical paths',
        'Post the release notes',
      ],
    ),
    _Template(
      title: 'Watch a conference talk — {}',
      pool: [
        'scaling Postgres past a billion rows',
        'what nobody tells you about microservices',
        'Flutter rendering internals',
        'the cost of abstraction',
        'incident response that actually works',
      ],
      hour: 17, minute: 30,
      duration: 45,
      category: TaskCategory.study,
      priority: TaskPriority.low,
      icon: 'study',
      tags: ['learning'],
      weekdays: {DateTime.tuesday, DateTime.thursday},
      chance: 0.4,
    ),
    _Template(
      title: 'On-call — triage alerts and dashboards',
      hour: 15, minute: 30,
      duration: 45,
      category: TaskCategory.work,
      priority: TaskPriority.high,
      icon: 'urgent',
      tags: ['on-call'],
      weekdays: _weekdays,
      chance: 0.12,
    ),
    _Template(
      title: 'Technical screen — candidate interview',
      hour: 15, minute: 30,
      duration: 60,
      category: TaskCategory.work,
      icon: 'meeting',
      tags: ['hiring'],
      weekdays: _weekdays,
      chance: 0.08,
      reminder: 30,
    ),
    _Template(
      title: 'Gym — strength session',
      hour: 18, minute: 15,
      duration: 60,
      category: TaskCategory.health,
      icon: 'workout',
      tags: ['fitness'],
      weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      chance: 0.7,
    ),
    _Template(
      title: 'Dinner',
      hour: 19, minute: 15,
      duration: 45,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'meal',
      tags: ['routine'],
      chance: 0.95,
      repeat: RepeatRule.daily,
      seriesKey: 'dinner',
    ),

    // --- Evening: learning and side work ---------------------------------
    _Template(
      title: 'System design study — {}',
      pool: [
        'consistent hashing',
        'the CAP theorem in practice',
        'Kafka partitioning',
        'database sharding strategies',
        'CDN and edge caching',
        'event sourcing and CQRS',
        'gRPC versus REST trade-offs',
        'idempotency in distributed systems',
        'designing a rate limiter',
        'read replicas and failover',
      ],
      hour: 20, minute: 15,
      duration: 60,
      category: TaskCategory.study,
      icon: 'study',
      tags: ['learning', 'interview-prep'],
      weekdays: {DateTime.monday, DateTime.wednesday},
      chance: 0.75,
    ),
    _Template(
      title: 'Side project — {}',
      pool: [
        'wire up the offline database',
        'polish the onboarding flow',
        'add the analytics screen',
        'fix the dark theme contrast',
        'write the App Store listing',
        'set up the CI pipeline',
        'cut the first TestFlight build',
      ],
      hour: 20, minute: 15,
      duration: 90,
      category: TaskCategory.creative,
      icon: 'idea',
      tags: ['side-project'],
      weekdays: {DateTime.tuesday, DateTime.thursday},
      chance: 0.7,
    ),
    _Template(
      title: 'LeetCode — {}',
      pool: [
        'graphs',
        'dynamic programming',
        'two pointers',
        'binary search',
        'tries',
        'heaps and priority queues',
        'sliding window',
        'union find',
      ],
      hour: 20, minute: 15,
      duration: 45,
      category: TaskCategory.study,
      priority: TaskPriority.low,
      icon: 'study',
      tags: ['learning', 'interview-prep'],
      weekdays: {DateTime.friday},
      chance: 0.45,
    ),
    _Template(
      title: 'Read — {}',
      pool: [
        'Designing Data-Intensive Applications',
        'Clean Architecture',
        'The Pragmatic Programmer',
        'Staff Engineer',
        'Refactoring',
        'A Philosophy of Software Design',
      ],
      hour: 21, minute: 30,
      duration: 30,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'read',
      tags: ['reading'],
      chance: 0.45,
    ),
    _Template(
      title: 'Plan tomorrow',
      hour: 22, minute: 10,
      duration: 15,
      category: TaskCategory.personal,
      icon: 'note',
      tags: ['routine', 'planning'],
      chance: 0.9,
      repeat: RepeatRule.daily,
      seriesKey: 'plan-tomorrow',
      reminder: 10,
      essential: true,
    ),

    // --- Weekend ----------------------------------------------------------
    _Template(
      title: 'Open-source contribution — {}',
      pool: [
        'fix an issue in the Flutter package',
        'review a community pull request',
        'write the missing documentation',
        'add tests to the sqflite helper',
      ],
      hour: 10, minute: 0,
      duration: 120,
      category: TaskCategory.creative,
      icon: 'code',
      tags: ['open-source'],
      weekdays: {DateTime.saturday},
      chance: 0.5,
    ),
    _Template(
      title: 'Weekly review and planning',
      hour: 10, minute: 0,
      duration: 45,
      category: TaskCategory.personal,
      priority: TaskPriority.high,
      icon: 'goal',
      tags: ['planning'],
      weekdays: {DateTime.sunday},
      repeat: RepeatRule.weekly,
      seriesKey: 'weekly-review',
      essential: true,
      checklist: [
        'Close out last week',
        'Pick three priorities',
        'Block the calendar',
      ],
    ),
    _Template(
      title: 'Coffee with {}',
      pool: [
        'a friend from the last job',
        'my old team lead',
        'someone from the Flutter meetup',
      ],
      hour: 11, minute: 15,
      duration: 90,
      category: TaskCategory.social,
      priority: TaskPriority.low,
      icon: 'coffee',
      tags: ['friends'],
      weekdays: {DateTime.saturday},
      chance: 0.3,
    ),
    _Template(
      title: 'Apartment reset and laundry',
      hour: 11, minute: 15,
      duration: 60,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'home',
      tags: ['chores'],
      weekdays: {DateTime.sunday},
      chance: 0.75,
    ),
    _Template(
      title: 'Grocery shopping',
      hour: 13, minute: 30,
      duration: 60,
      category: TaskCategory.personal,
      icon: 'shopping',
      tags: ['chores'],
      weekdays: {DateTime.saturday},
      chance: 0.8,
    ),
    _Template(
      title: 'Course — {}',
      pool: [
        'Kubernetes for developers',
        'Advanced Dart and Flutter',
        'Machine learning fundamentals',
        'Rust in practice',
        'AWS solutions architect prep',
      ],
      hour: 15, minute: 0,
      duration: 90,
      category: TaskCategory.study,
      icon: 'study',
      tags: ['learning'],
      weekdays: _weekend,
      chance: 0.55,
    ),
    _Template(
      title: 'Football with friends',
      hour: 16, minute: 30,
      duration: 90,
      category: TaskCategory.social,
      icon: 'workout',
      tags: ['friends'],
      weekdays: {DateTime.saturday},
      chance: 0.45,
    ),
    _Template(
      title: 'Family video call',
      hour: 18, minute: 0,
      duration: 45,
      category: TaskCategory.social,
      icon: 'call',
      tags: ['family'],
      weekdays: {DateTime.sunday},
      chance: 0.8,
      repeat: RepeatRule.weekly,
      seriesKey: 'family-call',
    ),
    _Template(
      title: 'Team dinner',
      hour: 19, minute: 30,
      duration: 120,
      category: TaskCategory.social,
      priority: TaskPriority.low,
      icon: 'meal',
      tags: ['team'],
      weekdays: {DateTime.friday},
      chance: 0.15,
    ),
    _Template(
      title: 'Write blog post — {}',
      pool: [
        'what I learned shipping offline-first',
        'a short note on flaky tests',
        'why we moved off the ORM',
        'reading Postgres query plans',
      ],
      hour: 20, minute: 0,
      duration: 90,
      category: TaskCategory.creative,
      priority: TaskPriority.low,
      icon: 'write',
      tags: ['writing'],
      weekdays: _weekend,
      chance: 0.2,
    ),
    _Template(
      title: 'Doctor / dentist appointment',
      hour: 15, minute: 0,
      duration: 60,
      category: TaskCategory.health,
      priority: TaskPriority.high,
      icon: 'health',
      tags: ['appointment'],
      weekdays: _weekdays,
      chance: 0.03,
      reminder: 60,
    ),
    _Template(
      title: 'Movie night',
      hour: 20, minute: 30,
      duration: 120,
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      icon: 'music',
      tags: ['rest'],
      weekdays: _weekend,
      chance: 0.5,
    ),
  ];

  // --- Review copy --------------------------------------------------------

  static const _goodHighlights = [
    'Shipped the feature branch a day ahead of the sprint.',
    'The refactor landed with no regressions in staging.',
    'Two deep-work blocks with zero interruptions.',
    'Finally understood the caching bug — obvious in hindsight.',
    'Pair-programmed with a junior dev and it clicked for them.',
    'Cut the dashboard query from 4s to 300ms.',
    'Closed every review request before lunch.',
  ];

  static const _flatHighlights = [
    'Meetings ate the morning, but the afternoon block held.',
    'Slow day, though the tests are green again.',
    'Mostly firefighting, but nothing is on fire now.',
    'Not much shipped — at least the design note is written.',
    'Low energy. Kept the routines going anyway.',
  ];

  static const _gratitudes = [
    'A teammate caught a bug in review before it shipped.',
    'Quiet morning, good coffee, working headphones.',
    'The CI pipeline behaved for once.',
    'Got outside for the run before the day started.',
    'Manager cancelled a meeting so I could keep the focus block.',
    'Good documentation from whoever wrote this module.',
  ];

  static const _blockers = [
    'Waiting on the API contract from the platform team.',
    'Flaky tests cost me nearly an hour.',
    'Too much context switching between three tickets.',
    'Staging environment was down most of the afternoon.',
    'Started scrolling instead of starting the hard task.',
    'Meeting overran and swallowed the deep-work block.',
  ];

  static const _improvements = [
    'Block the calendar for deep work before anyone else can.',
    'Write the design note first — coding straight in cost me time.',
    'Stop reviewing pull requests inside the focus block.',
    'Smaller commits, earlier pull requests.',
    'Put the phone in the other room for the morning block.',
    'Say no to the optional meeting next time.',
  ];

  static String _pick(List<String> options, Random rnd) =>
      options[rnd.nextInt(options.length)];
}

/// Minutes since midnight, for readable slot definitions.
int _t(int hour, int minute) => hour * 60 + minute;

const _weekdays = <int>{
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

const _weekend = <int>{DateTime.saturday, DateTime.sunday};

const _allDays = <int>{1, 2, 3, 4, 5, 6, 7};

/// A recurring entry in the weekly timetable, before its variable parts are
/// resolved for a given day.
class _Template {
  const _Template({
    required this.title,
    required this.hour,
    this.minute = 0,
    required this.duration,
    required this.category,
    this.priority = TaskPriority.medium,
    this.icon,
    this.tags = const [],
    this.weekdays = _allDays,
    this.chance = 1.0,
    this.repeat = RepeatRule.none,
    this.seriesKey,
    this.reminder,
    this.checklist = const [],
    this.description = '',
    this.pool = const [],
    this.essential = false,
  });

  /// May contain a single `{}` placeholder, filled from [pool].
  final String title;
  final List<String> pool;

  /// Start of the slot, as a wall-clock time. Split into two fields so the
  /// template table below stays `const` and stays readable.
  final int hour;
  final int minute;

  final int duration;
  final TaskCategory category;
  final TaskPriority priority;
  final String? icon;
  final List<String> tags;
  final Set<int> weekdays;

  /// Probability the slot appears at all on a matching weekday.
  final double chance;

  final RepeatRule repeat;
  final String? seriesKey;
  final int? reminder;
  final List<String> checklist;
  final String description;

  /// Essential slots survive days off and the far-future taper — they are the
  /// standing commitments a real calendar always shows.
  final bool essential;

  int get start => hour * 60 + minute;

  _Slot resolve(Random rnd) => _Slot(
    title: pool.isEmpty
        ? title
        : title.replaceFirst('{}', pool[rnd.nextInt(pool.length)]),
    start: start,
    duration: duration,
    category: category,
    priority: priority,
    icon: icon,
    tags: tags,
    repeat: repeat,
    seriesKey: seriesKey,
    reminder: reminder,
    checklist: checklist,
    description: description,
    essential: essential,
  );
}

/// One concrete entry on one concrete day.
class _Slot {
  const _Slot({
    required this.title,
    required this.start,
    required this.duration,
    required this.category,
    this.priority = TaskPriority.medium,
    this.icon,
    this.tags = const [],
    this.repeat = RepeatRule.none,
    this.seriesKey,
    this.reminder,
    this.checklist = const [],
    this.description = '',
    this.essential = false,
  });

  final String title;
  final int start;
  final int duration;
  final TaskCategory category;
  final TaskPriority priority;
  final String? icon;
  final List<String> tags;
  final RepeatRule repeat;
  final String? seriesKey;
  final int? reminder;
  final List<String> checklist;
  final String description;
  final bool essential;
}

extension _FocusWorthy on Task {
  /// Only sustained, single-threaded work gets Pomodoro blocks logged — nobody
  /// runs a timer for lunch or a standup.
  bool get deservesFocus =>
      durationMinutes >= 45 &&
      const {
        TaskCategory.work,
        TaskCategory.study,
        TaskCategory.creative,
      }.contains(category);
}

/// Writes a [DemoDataset] into the repositories.
class DemoDataSeeder {
  const DemoDataSeeder({
    required TaskRepository tasks,
    required DayLogRepository dayLogs,
    required FocusSessionRepository focusSessions,
    required ProfileRepository profile,
  }) : _tasks = tasks,
       _dayLogs = dayLogs,
       _focus = focusSessions,
       _profile = profile;

  final TaskRepository _tasks;
  final DayLogRepository _dayLogs;
  final FocusSessionRepository _focus;
  final ProfileRepository _profile;

  /// Generates and persists the dataset, then updates the profile so the
  /// gamification numbers match the history that was just written.
  ///
  /// The caller is responsible for clearing existing data first; this only
  /// inserts.
  Future<DemoDataset> seed({
    DateTime? now,
    int pastDays = DemoDataBuilder.defaultPastDays,
    int futureDays = DemoDataBuilder.defaultFutureDays,
  }) async {
    final data = DemoDataBuilder.build(
      now: now,
      pastDays: pastDays,
      futureDays: futureDays,
    );

    await _tasks.saveAll(data.tasks);
    await _dayLogs.saveAll(data.dayLogs);
    await _focus.saveAll(data.focusSessions);

    final current = await _profile.get();
    await _profile.save(
      current.copyWith(
        name: current.name.trim().isEmpty ? 'Alex' : current.name,
        occupation: 'Software Engineer',
        goal: 'Ship deliberately and keep learning every day.',
        workStartMinutes: _t(9, 0),
        workEndMinutes: _t(18, 0),
        wakeMinutes: _t(6, 15),
        sleepMinutes: _t(23, 15),
        dailyTaskTarget: 6,
        xp: data.xp,
        onboardingCompleted: true,
        createdAt:
            current.createdAt ??
            (now ?? DateTime.now()).subtract(Duration(days: pastDays)),
      ),
    );

    return data;
  }
}
