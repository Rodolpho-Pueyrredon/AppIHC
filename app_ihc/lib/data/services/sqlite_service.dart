import 'package:app_ihc/database/app_database.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService implements SQLiteServiceContract {
  Database? _database;
  Future<void>? _initFuture;

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    await init();
    return _database!;
  }

  @override
  Future<void> init() async {
    if (_database != null) {
      return;
    }
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    _initFuture = () async {
      _database = await AppDatabase.instance;
      final path = _database?.path;
      if (path != null && path.isNotEmpty) {
        debugPrint('SQLite DB path: $path');
      }

      await _database!.execute('PRAGMA foreign_keys = ON;');
    }();

    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  @override
  Future<void> execute(String sql) async {
    final db = await _db;
    await db.execute(sql);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await _db;
    return db.insert(table, values);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await _db;
    final result = await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    return result
        .map((row) => row.map((key, value) => MapEntry(key, value)))
        .toList();
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await _db;
    final result = await db.rawQuery(sql, arguments);
    return result
        .map((row) => row.map((key, value) => MapEntry(key, value)))
        .toList();
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await _db;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await _db;
    return db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
