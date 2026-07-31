import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/data/local/app_database.dart';
import 'package:vynqix/data/repositories/task_repository_impl.dart';
import 'package:vynqix/domain/entities/subtask.dart';
import 'package:vynqix/domain/entities/task.dart';
import 'package:vynqix/domain/enums/task_enums.dart';

import '../helpers/fixtures.dart';

/// Exercises the real SQLite schema and mappers against an in-memory database.
void main() {
  late AppDatabase db;
  late TaskRepositoryImpl repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = await AppDatabase.open(inMemory: true);
    repo = TaskRepositoryImpl(db);
  });

  tearDown(() async {
    await repo.dispose();
    await db.close();
  });

  test('round-trips every field through the database', () async {
    final original = Task(
      id: 'task-1',
      title: 'Write the report',
      description: 'Q3 summary',
      notes: 'Include the churn chart',
      emoji: '📝',
      dayKey: '2026-07-31',
      category: TaskCategory.work,
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      startMinutes: 9 * 60 + 30,
      durationMinutes: 90,
      tags: const ['q3', 'reporting'],
      subtasks: const [
        Subtask(id: 's1', title: 'Draft', isDone: true),
        Subtask(id: 's2', title: 'Review'),
      ],
      repeat: RepeatRule.weekly,
      reminderMinutesBefore: 15,
      seriesId: 'series-1',
      actualMinutes: 40,
      sortIndex: 3,
      createdAt: DateTime(2026, 7, 30, 8),
      updatedAt: DateTime(2026, 7, 30, 9),
    );

    await repo.save(original);
    final loaded = await repo.getById('task-1');

    expect(loaded, isNotNull);
    expect(loaded!.title, original.title);
    expect(loaded.description, original.description);
    expect(loaded.notes, original.notes);
    expect(loaded.emoji, '📝');
    expect(loaded.category, TaskCategory.work);
    expect(loaded.priority, TaskPriority.high);
    expect(loaded.status, TaskStatus.inProgress);
    expect(loaded.startMinutes, 570);
    expect(loaded.durationMinutes, 90);
    expect(loaded.tags, ['q3', 'reporting']);
    expect(loaded.subtasks, hasLength(2));
    expect(loaded.subtasks.first.isDone, isTrue);
    expect(loaded.repeat, RepeatRule.weekly);
    expect(loaded.reminderMinutesBefore, 15);
    expect(loaded.seriesId, 'series-1');
    expect(loaded.actualMinutes, 40);
    expect(loaded.sortIndex, 3);
    expect(loaded.createdAt, DateTime(2026, 7, 30, 8));
  });

  test('saving the same id twice updates rather than duplicates', () async {
    final original = task(id: 'x', title: 'Before');
    await repo.save(original);
    await repo.save(original.copyWith(title: 'After'));

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'After');
  });

  test('getByDay returns only that day', () async {
    await repo.saveAll([
      task(dayKey: '2026-07-30'),
      task(dayKey: '2026-07-31'),
      task(dayKey: '2026-07-31'),
    ]);

    expect(await repo.getByDay('2026-07-31'), hasLength(2));
    expect(await repo.getByDay('2026-07-29'), isEmpty);
  });

  test('getRange is inclusive on both ends', () async {
    await repo.saveAll([
      task(dayKey: '2026-07-29'),
      task(dayKey: '2026-07-30'),
      task(dayKey: '2026-07-31'),
      task(dayKey: '2026-08-01'),
    ]);

    final range = await repo.getRange('2026-07-30', '2026-07-31');
    expect(range.map((t) => t.dayKey), ['2026-07-30', '2026-07-31']);
  });

  test('search matches title, notes and tags case-insensitively', () async {
    await repo.save(
      Task(
        id: 'a',
        title: 'Gym session',
        notes: 'Leg day',
        tags: const ['fitness'],
        dayKey: '2026-07-31',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    expect(await repo.search('GYM'), hasLength(1));
    expect(await repo.search('leg'), hasLength(1));
    expect(await repo.search('fitness'), hasLength(1));
    expect(await repo.search('swimming'), isEmpty);
    expect(await repo.search(''), isEmpty);
  });

  test('deleteSeriesFrom removes the series from a day onward only', () async {
    await repo.saveAll([
      task(id: 's-0', dayKey: '2026-07-29', seriesId: 's'),
      task(id: 's-1', dayKey: '2026-07-30', seriesId: 's'),
      task(id: 's-2', dayKey: '2026-07-31', seriesId: 's'),
      task(id: 'other', dayKey: '2026-07-31'),
    ]);

    await repo.deleteSeriesFrom('s', '2026-07-30');

    final remaining = (await repo.getAll()).map((t) => t.id).toSet();
    expect(remaining, {'s-0', 'other'});
  });

  test('countCompleted counts only completed tasks', () async {
    await repo.saveAll([
      task(status: TaskStatus.completed),
      task(status: TaskStatus.completed),
      task(status: TaskStatus.missed),
      task(),
    ]);

    expect(await repo.countCompleted(), 2);
  });

  test('daysWithTasks returns the distinct day keys', () async {
    await repo.saveAll([
      task(dayKey: '2026-07-30'),
      task(dayKey: '2026-07-31'),
      task(dayKey: '2026-07-31'),
    ]);

    expect(await repo.daysWithTasks(), {'2026-07-30', '2026-07-31'});
  });

  test('writes emit on the changes stream', () async {
    final events = <void>[];
    final sub = repo.changes.listen(events.add);

    await repo.save(task());
    await repo.delete('missing-id');
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    await sub.cancel();
  });
}
