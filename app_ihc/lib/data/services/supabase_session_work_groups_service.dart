import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/core/constants/database_schema.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/session_work_group.dart';
import 'package:app_ihc/domain/services/session_work_groups_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class SupabaseSessionWorkGroupsService
    implements SessionWorkGroupsServiceContract {
  SupabaseSessionWorkGroupsService({
    required SupabaseApiConfig config,
    required HttpJsonClient httpJsonClient,
    required SQLiteServiceContract sqliteService,
  }) : _config = config,
       _httpJsonClient = httpJsonClient,
       _sqliteService = sqliteService;

  static const _sessionTable = 'sessao';

  final SupabaseApiConfig _config;
  final HttpJsonClient _httpJsonClient;
  final SQLiteServiceContract _sqliteService;

  @override
  Future<List<SessionWorkGroup>> getWorkGroupsFromSession() async {
    final sessionRows = await _getSessionRowsByWorkId();
    final groups = <SessionWorkGroup>[];

    for (final entry in sessionRows.entries) {
      final workId = entry.key;
      final cachedGroup = _fromSessionRow(entry.value);
      final remoteResult = await _getRemoteWorkGroup(workId);

      if (remoteResult.group != null) {
        await _cacheWorkGroup(remoteResult.group!);
        groups.add(remoteResult.group!);
        continue;
      }

      if (remoteResult.failed) {
        if (cachedGroup != null) {
          groups.add(cachedGroup);
          continue;
        }

        groups.add(
          SessionWorkGroup(
            workGroupId: workId,
            storeName: 'Trabalho $workId',
            storeAddress: '',
          ),
        );
      }
    }

    return groups;
  }

  Future<Map<String, Map<String, Object?>>> _getSessionRowsByWorkId() async {
    await _ensureSessionTable();

    final rows = await _sqliteService.query(
      _sessionTable,
      columns: ['work_id', 'store_name', 'store_address'],
    );

    final rowsByWorkId = <String, Map<String, Object?>>{};
    for (final row in rows) {
      final workId = _stringValue(row['work_id']);
      if (workId != null) {
        rowsByWorkId.putIfAbsent(workId, () => row);
      }
    }

    return rowsByWorkId;
  }

  Future<_RemoteWorkGroupResult> _getRemoteWorkGroup(String workId) async {
    try {
      final response = await _httpJsonClient.getJson(
        _config.tableUri(
          'work_groups_full',
          queryParameters: {'work_group_id': 'eq.$workId', 'done': 'eq.false'},
        ),
        headers: _config.headers,
      );

      if (response is! List) {
        return const _RemoteWorkGroupResult();
      }

      for (final item in response) {
        if (item is! Map<String, Object?>) {
          continue;
        }

        final group = _fromJson(item);
        if (group != null) {
          return _RemoteWorkGroupResult(group: group);
        }
      }
    } catch (_) {
      return const _RemoteWorkGroupResult(failed: true);
    }

    return const _RemoteWorkGroupResult();
  }

  Future<void> _cacheWorkGroup(SessionWorkGroup group) async {
    await _sqliteService.update(
      _sessionTable,
      {'store_name': group.storeName, 'store_address': group.storeAddress},
      where: 'work_id = ?',
      whereArgs: [group.workGroupId],
    );
  }

  SessionWorkGroup? _fromSessionRow(Map<String, Object?> row) {
    final workGroupId = _stringValue(row['work_id']);
    final storeName = _stringValue(row['store_name']);
    if (workGroupId == null || storeName == null) {
      return null;
    }

    return SessionWorkGroup(
      workGroupId: workGroupId,
      storeName: storeName,
      storeAddress: _stringValue(row['store_address']) ?? '',
    );
  }

  Future<void> _ensureSessionTable() async {
    await _sqliteService.execute(DatabaseSchema.createSessionTable);

    final columns = await _sqliteService.rawQuery(
      'PRAGMA table_info($_sessionTable)',
    );
    final hasStoreName = columns.any(
      (column) => column['name'] == 'store_name',
    );
    if (!hasStoreName) {
      await _sqliteService.execute(
        'ALTER TABLE $_sessionTable ADD COLUMN store_name TEXT',
      );
    }

    final hasStoreAddress = columns.any(
      (column) => column['name'] == 'store_address',
    );
    if (!hasStoreAddress) {
      await _sqliteService.execute(
        'ALTER TABLE $_sessionTable ADD COLUMN store_address TEXT',
      );
    }
  }

  SessionWorkGroup? _fromJson(Map<String, Object?> json) {
    final workGroupId = _stringValue(json['work_group_id']);
    final storeName = _stringValue(json['store_name']);
    final storeAddress = _stringValue(json['store_address']);

    if (workGroupId == null || storeName == null || storeAddress == null) {
      return null;
    }

    return SessionWorkGroup(
      workGroupId: workGroupId,
      storeName: storeName,
      storeAddress: storeAddress,
    );
  }

  String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _RemoteWorkGroupResult {
  const _RemoteWorkGroupResult({this.group, this.failed = false});

  final SessionWorkGroup? group;
  final bool failed;
}
