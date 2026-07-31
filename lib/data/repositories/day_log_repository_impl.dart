import 'package:sqflite/sqflite.dart';

import '../../domain/entities/day_log.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/mappers.dart';
import 'change_notifier_repository.dart';

class DayLogRepositoryImpl
    with ChangeNotifierRepository
    implements DayLogRepository {
  DayLogRepositoryImpl(this._db);

  final AppDatabase _db;

  Database get _c => _db.db;
  static const _table = AppDatabase.tableDayLogs;

  @override
  Future<DayLog?> getByDay(String dayKey) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey = ?',
      whereArgs: [dayKey],
      limit: 1,
    );
    return rows.isEmpty ? null : DayLogRowMapper.fromRow(rows.first);
  }

  @override
  Future<List<DayLog>> getRange(String fromDayKey, String toDayKey) async {
    final rows = await _c.query(
      _table,
      where: 'dayKey >= ? AND dayKey <= ?',
      whereArgs: [fromDayKey, toDayKey],
      orderBy: 'dayKey ASC',
    );
    return rows.map(DayLogRowMapper.fromRow).toList();
  }

  @override
  Future<List<DayLog>> getAll() async {
    final rows = await _c.query(_table, orderBy: 'dayKey DESC');
    return rows.map(DayLogRowMapper.fromRow).toList();
  }

  @override
  Future<void> save(DayLog log) async {
    await _c.insert(
      _table,
      log.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyChanged();
  }

  @override
  Future<void> delete(String dayKey) async {
    await _c.delete(_table, where: 'dayKey = ?', whereArgs: [dayKey]);
    notifyChanged();
  }

  @override
  Future<int> countLogged() async {
    final rows = await _c.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE mood IS NOT NULL OR rating > 0',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
