import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/recurrence_service.dart';
import '../../domain/services/schedule_service.dart';
import '../../domain/usecases/rewards_usecase.dart';
import 'app_providers.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

final rewardsUseCaseProvider = Provider<RewardsUseCase>((ref) {
  return RewardsUseCase(
    tasks: ref.watch(taskRepositoryProvider),
    dayLogs: ref.watch(dayLogRepositoryProvider),
    focusSessions: ref.watch(focusSessionRepositoryProvider),
    profile: ref.watch(profileRepositoryProvider),
  );
});

/// The day the Planner / Calendar / Review screens are pointed at.
final selectedDayProvider = StateProvider<DateTime>((ref) => DateX.tomorrow);

/// The month the calendar grid is showing.
final calendarMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

/// All tasks for a given `yyyy-MM-dd`, ordered for display.
final tasksForDayProvider = FutureProvider.family<List<Task>, String>((
  ref,
  dayKey,
) async {
  final repo = ref.watch(taskRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  return ScheduleService.sortForDay(await repo.getByDay(dayKey));
});

/// Tasks across an inclusive day-key range.
final tasksInRangeProvider =
    FutureProvider.family<List<Task>, ({String from, String to})>((
      ref,
      range,
    ) async {
      final repo = ref.watch(taskRepositoryProvider);
      refreshOnChanges(ref, [repo]);
      return repo.getRange(range.from, range.to);
    });

final taskByIdProvider = FutureProvider.family<Task?, String>((ref, id) async {
  final repo = ref.watch(taskRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  return repo.getById(id);
});

/// Day keys that have at least one task — powers the calendar's dots.
final daysWithTasksProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  return repo.daysWithTasks();
});

final taskSearchQueryProvider = StateProvider<String>((ref) => '');

final taskSearchResultsProvider = FutureProvider<List<Task>>((ref) async {
  final query = ref.watch(taskSearchQueryProvider);
  final repo = ref.watch(taskRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  if (query.trim().length < 2) return const [];
  return repo.search(query);
});

/// The task currently running (or scheduled for right now).
final currentTaskProvider = Provider<Task?>((ref) {
  final now = ref.watch(nowProvider);
  final tasks = ref.watch(tasksForDayProvider(now.dayKey)).valueOrNull;
  if (tasks == null) return null;
  return ScheduleService.currentTask(tasks, now);
});

final nextTaskProvider = Provider<Task?>((ref) {
  final now = ref.watch(nowProvider);
  final tasks = ref.watch(tasksForDayProvider(now.dayKey)).valueOrNull;
  if (tasks == null) return null;
  return ScheduleService.nextTask(tasks, now);
});

final taskControllerProvider = Provider<TaskController>(
  TaskController.new,
);

/// Everything that mutates tasks.
///
/// Controllers own the side effects (recurrence expansion, XP, achievement
/// checks) so widgets stay declarative and repositories stay dumb.
class TaskController {
  TaskController(this._ref);

  final Ref _ref;

  TaskRepository get _repo => _ref.read(taskRepositoryProvider);
  RewardsUseCase get _rewards => _ref.read(rewardsUseCaseProvider);

  /// Builds a blank task for [dayKey], pre-filled with sensible defaults.
  Task draft({String? dayKey}) {
    final now = DateTime.now();
    return Task(
      id: newId(),
      title: '',
      dayKey: dayKey ?? DateX.tomorrowKey,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Saves a new task and materialises its future occurrences if it repeats.
  Future<void> create(Task task) async {
    final seriesId = task.repeat.repeats ? task.id : null;
    final root = task.copyWith(seriesId: seriesId, updatedAt: DateTime.now());
    await _repo.save(root);
    if (root.repeat.repeats) {
      await _repo.saveAll(RecurrenceService.expand(root));
    }
  }

  /// Updates one occurrence. When [applyToSeries] is true, future occurrences
  /// are regenerated from this one.
  Future<void> update(Task task, {bool applyToSeries = false}) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _repo.save(updated);

    final seriesId = updated.seriesId;
    if (applyToSeries && seriesId != null && updated.repeat.repeats) {
      await _repo.deleteSeriesFrom(
        seriesId,
        DateX.parseKey(updated.dayKey)
            .add(const Duration(days: 1))
            .dayKey,
      );
      await _repo.saveAll(RecurrenceService.expand(updated));
    }
  }

  /// Deletes a task (or the rest of its series) and returns the rows that
  /// were removed, so the caller can offer an undo.
  Future<List<Task>> delete(Task task, {bool wholeSeries = false}) async {
    final seriesId = task.seriesId;
    if (wholeSeries && seriesId != null) {
      final all = await _repo.getAll();
      final removed = all
          .where(
            (t) =>
                t.seriesId == seriesId &&
                t.dayKey.compareTo(task.dayKey) >= 0,
          )
          .toList();
      await _repo.deleteSeriesFrom(seriesId, task.dayKey);
      return removed;
    }
    await _repo.delete(task.id);
    return [task];
  }

  /// Puts back tasks removed by [delete].
  Future<void> restore(List<Task> tasks) => _repo.saveAll(tasks);

  /// Toggles between completed and pending, awarding XP on completion.
  ///
  /// Returns any achievements unlocked by the change so the caller can show
  /// a celebration.
  Future<List<AchievementDefinition>> toggleComplete(Task task) async {
    if (task.isDone) {
      await _repo.save(
        task.copyWith(
          status: TaskStatus.pending,
          clearCompletedAt: true,
          updatedAt: DateTime.now(),
        ),
      );
      return const [];
    }

    await _repo.save(
      task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        subtasks: task.subtasks.map((s) => s.copyWith(isDone: true)).toList(),
        updatedAt: DateTime.now(),
      ),
    );
    return _rewards.grant(_xpFor(task));
  }

  static int _xpFor(Task task) => switch (task.priority) {
    TaskPriority.high => (AppConstants.xpPerTask * 1.5).round(),
    TaskPriority.medium => AppConstants.xpPerTask,
    TaskPriority.low => (AppConstants.xpPerTask * 0.7).round(),
  };

  Future<void> setStatus(Task task, TaskStatus status) async {
    await _repo.save(
      task.copyWith(
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
        clearCompletedAt: status != TaskStatus.completed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> start(Task task) => setStatus(task, TaskStatus.inProgress);

  Future<void> skip(Task task) => setStatus(task, TaskStatus.skipped);

  /// Moves a task to another day and/or start time.
  Future<void> reschedule(
    Task task, {
    String? dayKey,
    int? startMinutes,
    bool clearStart = false,
  }) async {
    await _repo.save(
      task.copyWith(
        dayKey: dayKey,
        startMinutes: startMinutes,
        clearStartMinutes: clearStart,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Persists a new manual order for a day's task list.
  Future<void> reorder(List<Task> ordered) async {
    final now = DateTime.now();
    await _repo.saveAll([
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortIndex: i, updatedAt: now),
    ]);
  }

  Future<void> toggleSubtask(Task task, String subtaskId) async {
    final subtasks = task.subtasks
        .map((s) => s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s)
        .toList();
    await _repo.save(
      task.copyWith(subtasks: subtasks, updatedAt: DateTime.now()),
    );
  }

  Future<void> addSubtask(Task task, String title) async {
    final subtasks = [
      ...task.subtasks,
      Subtask(id: newId(), title: title, sortIndex: task.subtasks.length),
    ];
    await _repo.save(
      task.copyWith(subtasks: subtasks, updatedAt: DateTime.now()),
    );
  }

  /// Records focus time against a task.
  Future<void> addFocusMinutes(String taskId, int minutes) async {
    final task = await _repo.getById(taskId);
    if (task == null) return;
    await _repo.save(
      task.copyWith(
        actualMinutes: task.actualMinutes + minutes,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Duplicates a task onto another day — the "plan tomorrow like today" path.
  Future<void> duplicateTo(Task task, String dayKey) async {
    final now = DateTime.now();
    await _repo.save(
      Task(
        id: newId(),
        title: task.title,
        description: task.description,
        notes: task.notes,
        iconKey: task.iconKey,
        dayKey: dayKey,
        category: task.category,
        priority: task.priority,
        startMinutes: task.startMinutes,
        durationMinutes: task.durationMinutes,
        tags: task.tags,
        subtasks: task.subtasks.map((s) => s.copyWith(isDone: false)).toList(),
        reminderMinutesBefore: task.reminderMinutesBefore,
        sortIndex: task.sortIndex,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Marks past-due open tasks as missed and, when enabled, carries them to
  /// today. Runs once at startup.
  Future<int> rolloverUnfinished({required bool moveToToday}) async {
    final todayKey = DateX.todayKey;
    final all = await _repo.getAll();
    final stale = all
        .where((t) => t.status.isOpen && t.dayKey.compareTo(todayKey) < 0)
        .toList();
    if (stale.isEmpty) return 0;

    final now = DateTime.now();
    final updates = stale.map((t) {
      return moveToToday
          ? t.copyWith(dayKey: todayKey, updatedAt: now)
          : t.copyWith(status: TaskStatus.missed, updatedAt: now);
    }).toList();

    await _repo.saveAll(updates);
    return updates.length;
  }
}
