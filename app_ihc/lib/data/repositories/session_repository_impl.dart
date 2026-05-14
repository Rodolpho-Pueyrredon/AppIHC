import 'package:app_ihc/core/constants/database_schema.dart';
import 'package:app_ihc/domain/models/session_work.dart';
import 'package:app_ihc/domain/repositories/session_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required SQLiteServiceContract sqliteService})
    : _sqliteService = sqliteService;

  static const _table = 'sessao';
  final SQLiteServiceContract _sqliteService;

  @override
  Future<void> saveSessionWorks(List<SessionWork> works) async {
    await _ensureTable();
    final cachedWorkGroups = await _cachedWorkGroupsById();
    await clearSession();

    for (final work in works) {
      final username = work.username.trim();
      final workId = work.workId.trim();
      if (username.isEmpty || workId.isEmpty) {
        continue;
      }

      await _sqliteService.insert(_table, {
        'user': username,
        'work_id': workId,
        'store_name': cachedWorkGroups[workId]?['store_name'],
        'store_address': cachedWorkGroups[workId]?['store_address'],
      });
    }
  }

  @override
  Future<void> clearSession() async {
    await _ensureTable();
    await _sqliteService.delete(_table, where: '1 = ?', whereArgs: [1]);
  }

  Future<void> _ensureTable() async {
    await _sqliteService.execute(DatabaseSchema.createSessionTable);

    final columns = await _sqliteService.rawQuery('PRAGMA table_info($_table)');
    final hasWorkId = columns.any((column) => column['name'] == 'work_id');
    if (!hasWorkId) {
      await _sqliteService.execute(
        'ALTER TABLE $_table ADD COLUMN work_id TEXT',
      );
    }

    final hasStoreName = columns.any(
      (column) => column['name'] == 'store_name',
    );
    if (!hasStoreName) {
      await _sqliteService.execute(
        'ALTER TABLE $_table ADD COLUMN store_name TEXT',
      );
    }

    final hasStoreAddress = columns.any(
      (column) => column['name'] == 'store_address',
    );
    if (!hasStoreAddress) {
      await _sqliteService.execute(
        'ALTER TABLE $_table ADD COLUMN store_address TEXT',
      );
    }
  }

  Future<Map<String, Map<String, Object?>>> _cachedWorkGroupsById() async {
    final rows = await _sqliteService.query(
      _table,
      columns: ['work_id', 'store_name', 'store_address'],
    );
    final rowsByWorkId = <String, Map<String, Object?>>{};
    for (final row in rows) {
      final workId = row['work_id'];
      if (workId is String && workId.trim().isNotEmpty) {
        rowsByWorkId[workId.trim()] = row;
      }
    }

    return rowsByWorkId;
  }
}
