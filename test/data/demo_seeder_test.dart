import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vynqix/core/utils/date_x.dart';
import 'package:vynqix/data/local/app_database.dart';
import 'package:vynqix/data/local/demo_data.dart';
import 'package:vynqix/data/repositories/day_log_repository_impl.dart';
import 'package:vynqix/data/repositories/focus_session_repository_impl.dart';
import 'package:vynqix/data/repositories/profile_repository_impl.dart';
import 'package:vynqix/data/repositories/task_repository_impl.dart';
import 'package:vynqix/domain/enums/task_enums.dart';

/// Round-trips the generated dataset through the real schema, so a mapping
/// mistake shows up here rather than as an empty screen after seeding.
void main() {
  late AppDatabase db;
  late TaskRepositoryImpl tasks;
  late DayLogRepositoryImpl dayLogs;
  late FocusSessionRepositoryImpl focus;
  late ProfileRepositoryImpl profile;
  late DemoDataSeeder seeder;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    db = await AppDatabase.open(inMemory: true);
    tasks = TaskRepositoryImpl(db);
    dayLogs = DayLogRepositoryImpl(db);
    focus = FocusSessionRepositoryImpl(db);
    profile = ProfileRepositoryImpl(db);
    seeder = DemoDataSeeder(
      tasks: tasks,
      dayLogs: dayLogs,
      focusSessions: focus,
      profile: profile,
    );
  });

  tearDown(() async {
    await tasks.dispose();
    await dayLogs.dispose();
    await focus.dispose();
    await profile.dispose();
    await db.close();
  });

  test('persists the whole dataset and reads it back', () async {
    // A short range keeps the test quick; the shape is what matters here.
    final data = await seeder.seed(pastDays: 30, futureDays: 10);

    final stored = await tasks.getAll();
    expect(stored.length, data.tasks.length);
    expect(await tasks.countCompleted(), data.completedCount);
    expect((await dayLogs.getAll()).length, data.dayLogs.length);
    expect(await dayLogs.countLogged(), data.dayLogs.length);

    final today = await tasks.getByDay(DateX.todayKey);
    expect(today, isNotEmpty);
    expect(await tasks.daysWithTasks(), hasLength(41));
  });

  test('keeps checklists, tags and series links intact', () async {
    await seeder.seed(pastDays: 14, futureDays: 3);

    final stored = await tasks.getAll();
    final withChecklist = stored.firstWhere((t) => t.hasSubtasks);
    expect(withChecklist.subtasks.map((s) => s.title), isNotEmpty);
    expect(withChecklist.tags, isNotEmpty);

    final standups = stored.where((t) => t.title == 'Daily standup');
    expect(standups, isNotEmpty);
    expect(standups.every((t) => t.seriesId == 'demo-standup'), isTrue);
    expect(standups.every((t) => t.repeat == RepeatRule.weekdays), isTrue);
  });

  test('logs focus minutes against the tasks that earned them', () async {
    await seeder.seed(pastDays: 30, futureDays: 0);

    expect(await focus.totalFocusMinutes(), greaterThan(0));
    expect(await focus.countCompletedSessions(), greaterThan(0));

    final deepWork = (await tasks.getAll()).firstWhere(
      (t) => t.isDone && t.durationMinutes >= 90,
    );
    expect(await focus.getByTask(deepWork.id), isNotNull);
  });

  test('sets up a software engineer profile with earned XP', () async {
    final data = await seeder.seed(pastDays: 60, futureDays: 7);

    final saved = await profile.get();
    expect(saved.occupation, 'Software Engineer');
    expect(saved.onboardingCompleted, isTrue);
    expect(saved.xp, data.xp);
    expect(saved.level, greaterThan(1));
    expect(saved.createdAt, isNotNull);
  });

  test('does not overwrite a name the user already chose', () async {
    final existing = (await profile.get()).copyWith(name: 'Rishitha');
    await profile.save(existing);

    await seeder.seed(pastDays: 5, futureDays: 1);

    expect((await profile.get()).name, 'Rishitha');
  });
}
