import 'package:app_ihc/core/constants/database_schema.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService implements SQLiteServiceContract {
  Database? _database;

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

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, DatabaseSchema.databaseName);

    _database = await openDatabase(
      dbPath,
      version: DatabaseSchema.databaseVersion,
      onCreate: (db, _) async {
        await db.execute(DatabaseSchema.createProductsTable);
        await db.execute(DatabaseSchema.createStoresTable);
        await db.execute(DatabaseSchema.createStoresNormalizedNameIndex);
        await db.execute(DatabaseSchema.createPriceObservationsTable);
        await db.execute(DatabaseSchema.createPriceObsProductIdIndex);
        await db.execute(DatabaseSchema.createPriceObsStoreIdIndex);
        await db.execute(DatabaseSchema.createPriceObsObservedAtIndex);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
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
}
