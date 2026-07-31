import 'package:sqflite/sqflite.dart';

import '../../domain/entities/focus_session.dart';
import '../../domain/enums/task_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/mappers.dart';
import 'change_notifier_repository.dart';

class FocusSessionRepositoryImpl
    with ChangeNotifierRepository
    implements FocusSessionRepository {
  FocusSessionRepositoryImpl(this._db);

  final AppDatabase _db;

  Database get _c => _db.db;
  static const _table = AppDatabase.tableFocusSessions;

  @override
  Future<List<FocusSession>> getByDay(String dayKey) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey = ?',
      whereArgs: [dayKey],
      orderBy: 'startedAt ASC',
    );
    return rows.map(FocusSessionRowMapper.fromRow).toList();
  }

  @override
  Future<List<FocusSession>> getRange(
    String fromDayKey,
    String toDayKey,
  ) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey >= ? AND dayKey <= ?',
      whereArgs: [fromDayKey, toDayKey],
      orderBy: 'startedAt ASC',
    );
    return rows.map(FocusSessionRowMapper.fromRow).toList();
  }

  @override
  Future<List<FocusSession>> getByTask(String taskId) async {
    final rows = await _c.query(
      _table,
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'startedAt ASC',
    );
    return rows.map(FocusSessionRowMapper.fromRow).toList();
  }

  @override
  Future<void> save(FocusSession session) async {
    await _c.insert(
      _table,
      session.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyChanged();
  }

  @override
  Future<void> delete(String id) async {
    await _c.delete(_table, where: 'id = ?', whereArgs: [id]);
    notifyChanged();
  }

  @override
  Future<int> totalFocusMinutes() async {
    final rows = await _c.rawQuery(
      'SELECT SUM(elapsedSeconds) AS s FROM $_table '
      'WHERE type = ? AND wasCompleted = 1',
      [FocusSessionType.focus.id],
    );
    final seconds = (rows.first['s'] as int?) ?? 0;
    return seconds ~/ 60;
  }

  @override
  Future<int> countCompletedSessions() async {
    final rows = await _c.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE type = ? AND wasCompleted = 1',
      [FocusSessionType.focus.id],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
