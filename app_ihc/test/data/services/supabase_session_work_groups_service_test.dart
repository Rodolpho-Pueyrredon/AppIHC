import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/supabase_session_work_groups_service.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpJsonClient implements HttpJsonClient {
  final requestedUris = <Uri>[];

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    requestedUris.add(uri);
    final workGroupId = uri.queryParameters['work_group_id']?.replaceFirst(
      'eq.',
      '',
    );

    return [
      {
        'work_group_id': workGroupId,
        'store_name': 'Loja $workGroupId',
        'store_address': 'Endereco $workGroupId',
      },
    ];
  }

  @override
  Future<dynamic> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSQLiteService implements SQLiteServiceContract {
  final sessionRows = <Map<String, Object?>>[
    {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
    {'user': 'miao_yin@empresa.com', 'work_id': 'work-2'},
    {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
  ];

  @override
  Future<void> init() async {}

  @override
  Future<void> execute(String sql) async {}

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    return 0;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return 0;
  }

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return 0;
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
    return table == 'sessao' ? sessionRows : const [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return const [];
  }
}

void main() {
  test('loads one work group for each unique work id in session', () async {
    final httpClient = _FakeHttpJsonClient();
    final service = SupabaseSessionWorkGroupsService(
      config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
      httpJsonClient: httpClient,
      sqliteService: _FakeSQLiteService(),
    );

    final groups = await service.getWorkGroupsFromSession();

    expect(groups, hasLength(2));
    expect(groups.first.workGroupId, 'work-1');
    expect(groups.first.storeName, 'Loja work-1');
    expect(groups.first.storeAddress, 'Endereco work-1');
    expect(groups.last.workGroupId, 'work-2');
    expect(httpClient.requestedUris.map((uri) => uri.toString()), [
      'https://example.com/rest/v1/work_groups_full?work_group_id=eq.work-1',
      'https://example.com/rest/v1/work_groups_full?work_group_id=eq.work-2',
    ]);
  });
}
