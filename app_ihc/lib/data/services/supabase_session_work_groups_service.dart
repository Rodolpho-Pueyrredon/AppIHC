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
    final workIds = await _getSessionWorkIds();
    final groups = <SessionWorkGroup>[];

    for (final workId in workIds) {
      final response = await _httpJsonClient.getJson(
        _config.tableUri(
          'work_groups_full',
          queryParameters: {'work_group_id': 'eq.$workId'},
        ),
        headers: _config.headers,
      );

      if (response is! List) {
        continue;
      }

      for (final item in response) {
        if (item is! Map<String, Object?>) {
          continue;
        }

        final group = _fromJson(item);
        if (group != null) {
          groups.add(group);
        }
      }
    }

    return groups;
  }

  Future<List<String>> _getSessionWorkIds() async {
    await _sqliteService.execute(DatabaseSchema.createSessionTable);

    final rows = await _sqliteService.query(
      _sessionTable,
      columns: ['work_id'],
    );

    final workIds = <String>{};
    for (final row in rows) {
      final workId = _stringValue(row['work_id']);
      if (workId != null) {
        workIds.add(workId);
      }
    }

    return workIds.toList(growable: false);
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
