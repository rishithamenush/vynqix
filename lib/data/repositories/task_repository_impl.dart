import 'package:sqflite/sqflite.dart';

import '../../domain/entities/task.dart';
import '../../domain/enums/task_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/mappers.dart';
import 'change_notifier_repository.dart';

class TaskRepositoryImpl
    with ChangeNotifierRepository
    implements TaskRepository {
  TaskRepositoryImpl(this._db);

  final AppDatabase _db;

  Database get _c => _db.db;
  static const _table = AppDatabase.tableTasks;

  @override
  Future<List<Task>> getByDay(String dayKey) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey = ?',
      whereArgs: [dayKey],
    );
    return rows.map(TaskRowMapper.fromRow).toList();
  }

  @override
  Future<List<Task>> getRange(String fromDayKey, String toDayKey) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey >= ? AND dayKey <= ?',
      whereArgs: [fromDayKey, toDayKey],
      orderBy: 'dayKey ASC, startMinutes ASC',
    );
    return rows.map(TaskRowMapper.fromRow).toList();
  }

  @override
  Future<List<Task>> getAll() async {
    final rows = await _c.query(_table, orderBy: 'dayKey DESC');
    return rows.map(TaskRowMapper.fromRow).toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final rows = await _c.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : TaskRowMapper.fromRow(rows.first);
  }

  @override
  Future<List<Task>> search(String query) async {
    final term = '%${query.trim().toLowerCase()}%';
    if (query.trim().isEmpty) return const [];
    final rows = await _c.query(
      _table,
      where:
          'LOWER(title) LIKE ? OR LOWER(description) LIKE ? '
          'OR LOWER(notes) LIKE ? OR LOWER(tags) LIKE ?',
      whereArgs: [term, term, term, term],
      orderBy: 'dayKey DESC',
      limit: 200,
    );
    return rows.map(TaskRowMapper.fromRow).toList();
  }

  @override
  Future<void> save(Task task) async {
    await _c.insert(
      _table,
      task.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyChanged();
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final batch = _c.batch();
    for (final task in tasks) {
      batch.insert(
        _table,
        task.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    notifyChanged();
  }

  @override
  Future<void> delete(String id) async {
    await _c.delete(_table, where: 'id = ?', whereArgs: [id]);
    notifyChanged();
  }

  @override
  Future<void> deleteSeriesFrom(String seriesId, String fromDayKey) async {
    await _c.delete(
      _table,
      where: 'seriesId = ? AND dayKey >= ?',
      whereArgs: [seriesId, fromDayKey],
    );
    notifyChanged();
  }

  @override
  Future<Set<String>> daysWithTasks() async {
    final rows = await _c.rawQuery('SELECT DISTINCT dayKey FROM $_table');
    return rows.map((r) => r['dayKey'] as String).toSet();
  }

  @override
  Future<int> countCompleted() async {
    final rows = await _c.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE status = ?',
      [TaskStatus.completed.id],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
