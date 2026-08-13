import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vynqix/data/local/app_database.dart';
import 'package:vynqix/presentation/providers/app_providers.dart';
import 'package:vynqix/presentation/providers/task_providers.dart';

import '../helpers/fixtures.dart';

/// The Planner's "copy today" and "auto-schedule" buttons used to persist one
/// task at a time. Every save publishes a change notification, and every list
/// provider listening re-queries the whole day on each one — so copying a full
/// day did O(n²) database work on the UI isolate and visibly froze the screen.
///
/// These lock in the batching. The counts are the point: one write, one
/// notification, however many tasks are involved.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late TaskController controller;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    db = await AppDatabase.open(inMemory: true);
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    controller = container.read(taskControllerProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Counts change notifications published while [action] runs.
  Future<int> countNotifications(Future<void> Function() action) async {
    var notifications = 0;
    final sub = container
        .read(taskRepositoryProvider)
        .changes
        .listen((_) => notifications++);
    await action();
    // Let the broadcast stream deliver before we read the tally.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return notifications;
  }

  test('duplicateAllTo copies a whole day in a single notification', () async {
    final today = [for (var i = 0; i < 12; i++) task(title: 'Task $i')];
    await controller.reorder(today);

    final notifications = await countNotifications(
      () => controller.duplicateAllTo(today, '2026-08-01'),
    );

    expect(notifications, 1);
    expect((await container.read(taskRepositoryProvider).getByDay('2026-08-01')).length, 12);
  });

  test('rescheduleAll writes every task in a single notification', () async {
    final tasks = [for (var i = 0; i < 12; i++) task(title: 'Task $i')];
    await controller.reorder(tasks);

    final timed = [
      for (var i = 0; i < tasks.length; i++)
        tasks[i].copyWith(startMinutes: 540 + i * 30),
    ];

    final notifications = await countNotifications(
      () => controller.rescheduleAll(timed),
    );

    expect(notifications, 1);
    final saved = await container
        .read(taskRepositoryProvider)
        .getByDay(tasks.first.dayKey);
    expect(saved.every((t) => t.startMinutes != null), isTrue);
  });

  test('the per-task path still notifies per task', () async {
    // Guards the comparison the batch methods exist for: this is what the
    // Planner used to do, and why it froze.
    final tasks = [for (var i = 0; i < 5; i++) task(title: 'Task $i')];
    await controller.reorder(tasks);

    final notifications = await countNotifications(() async {
      for (final t in tasks) {
        await controller.duplicateTo(t, '2026-08-02');
      }
    });

    expect(notifications, 5);
  });

  test('empty batches never touch the database', () async {
    final notifications = await countNotifications(() async {
      await controller.duplicateAllTo(const [], '2026-08-03');
      await controller.rescheduleAll(const []);
    });

    expect(notifications, 0);
  });
}
