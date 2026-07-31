import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';

/// Owns the SQLite connection and schema.
///
/// The database is opened once at startup and injected through Riverpod, so
/// no widget ever reaches for a global.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const tableTasks = 'tasks';
  static const tableDayLogs = 'day_logs';
  static const tableFocusSessions = 'focus_sessions';
  static const tableAchievements = 'achievements';
  static const tableKeyValue = 'key_value';

  /// Opens (and migrates) the database. Pass [inMemory] in tests.
  static Future<AppDatabase> open({bool inMemory = false}) async {
    final factory = _factory();
    final path = inMemory
        ? inMemoryDatabasePath
        : p.join(await _databaseDirectory(factory), AppConstants.databaseName);

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  /// Desktop keeps the file in the app-support directory; mobile uses the
  /// platform's canonical databases directory.
  static Future<String> _databaseDirectory(DatabaseFactory factory) async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      return dir.path;
    }
    return factory.getDatabasesPath();
  }

  /// Desktop and tests need the FFI factory; mobile uses the platform plugin.
  static DatabaseFactory _factory() {
    if (kIsWeb) return databaseFactory;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  static Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        iconKey TEXT,
        dayKey TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        startMinutes INTEGER,
        durationMinutes INTEGER NOT NULL DEFAULT 30,
        tags TEXT NOT NULL DEFAULT '[]',
        subtasks TEXT NOT NULL DEFAULT '[]',
        repeatRule TEXT NOT NULL DEFAULT 'none',
        reminderMinutesBefore INTEGER,
        seriesId TEXT,
        actualMinutes INTEGER NOT NULL DEFAULT 0,
        sortIndex INTEGER NOT NULL DEFAULT 0,
        completedAt INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_tasks_day ON $tableTasks (dayKey)');
    batch.execute('CREATE INDEX idx_tasks_status ON $tableTasks (status)');
    batch.execute('CREATE INDEX idx_tasks_series ON $tableTasks (seriesId)');

    batch.execute('''
      CREATE TABLE $tableDayLogs (
        dayKey TEXT PRIMARY KEY,
        mood TEXT,
        energy TEXT,
        rating INTEGER NOT NULL DEFAULT 0,
        highlight TEXT NOT NULL DEFAULT '',
        gratitude TEXT NOT NULL DEFAULT '',
        blocker TEXT NOT NULL DEFAULT '',
        improvement TEXT NOT NULL DEFAULT '',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableFocusSessions (
        id TEXT PRIMARY KEY,
        dayKey TEXT NOT NULL,
        taskId TEXT,
        type TEXT NOT NULL,
        plannedMinutes INTEGER NOT NULL,
        startedAt INTEGER NOT NULL,
        endedAt INTEGER,
        elapsedSeconds INTEGER NOT NULL DEFAULT 0,
        wasCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_focus_day ON $tableFocusSessions (dayKey)');
    batch.execute(
      'CREATE INDEX idx_focus_task ON $tableFocusSessions (taskId)',
    );

    batch.execute('''
      CREATE TABLE $tableAchievements (
        id TEXT PRIMARY KEY,
        unlockedAt INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableKeyValue (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// Migrations are additive and versioned. Bump
  /// `AppConstants.databaseVersion` and add a case here.
  static Future<void> _migrate(Database db, int from, int to) async {
    // v2: tasks stored a literal emoji character; they now store a key into
    // the app's icon set. The old column is left in place (SQLite cannot
    // drop columns portably) but is no longer read or written.
    if (from < 2) {
      await db.execute('ALTER TABLE $tableTasks ADD COLUMN iconKey TEXT');
    }
  }

  Future<void> close() => db.close();

  /// Wipes user data while leaving the schema in place.
  Future<void> clearAll() async {
    final batch = db.batch();
    for (final table in [
      tableTasks,
      tableDayLogs,
      tableFocusSessions,
      tableAchievements,
      tableKeyValue,
    ]) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
