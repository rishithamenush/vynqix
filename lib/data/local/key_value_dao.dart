import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Small JSON document store for singleton records (profile, settings).
///
/// Using a key/value table for these avoids a schema migration every time a
/// preference is added, while the typed entity keeps call sites safe.
class KeyValueDao {
  KeyValueDao(this._db);

  final AppDatabase _db;

  static const _table = AppDatabase.tableKeyValue;

  Future<Map<String, dynamic>?> readJson(String key) async {
    final rows = await _db.db.query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final decoded = jsonDecode(rows.first['value'] as String);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _db.db.insert(_table, {
      'key': key,
      'value': jsonEncode(value),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String key) async {
    await _db.db.delete(_table, where: 'key = ?', whereArgs: [key]);
  }
}
