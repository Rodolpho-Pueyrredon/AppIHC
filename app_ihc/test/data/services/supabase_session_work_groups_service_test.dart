import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/supabase_session_work_groups_service.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpJsonClient implements HttpJsonClient {
  _FakeHttpJsonClient({this.shouldThrow = false});

  final bool shouldThrow;
  final requestedUris = <Uri>[];

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    if (shouldThrow) {
      throw Exception('Network unavailable.');
    }

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
  _FakeSQLiteService({List<Map<String, Object?>>? sessionRows})
    : sessionRows =
          sessionRows ??
          [
            {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
            {'user': 'miao_yin@empresa.com', 'work_id': 'work-2'},
            {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
          ];

  final List<Map<String, Object?>> sessionRows;

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
    if (table == 'sessao') {
      final workId = whereArgs.first;
      for (final row in sessionRows) {
        if (row['work_id'] == workId) {
          row.addAll(values);
        }
      }
    }

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

  @override
  Future<T> transaction<T>(
    Future<T> Function(SQLiteTransactionContract transaction) action,
  ) {
    throw UnimplementedError();
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
      'https://example.com/rest/v1/work_groups_full?work_group_id=eq.work-1&done=eq.false',
      'https://example.com/rest/v1/work_groups_full?work_group_id=eq.work-2&done=eq.false',
    ]);
  });

  test('uses cached work groups from session when supabase fails', () async {
    final httpClient = _FakeHttpJsonClient(shouldThrow: true);
    final service = SupabaseSessionWorkGroupsService(
      config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
      httpJsonClient: httpClient,
      sqliteService: _FakeSQLiteService(
        sessionRows: [
          {
            'user': 'miao_yin@empresa.com',
            'work_id': 'work-1',
            'store_name': 'Loja em cache',
            'store_address': 'Endereco em cache',
          },
        ],
      ),
    );

    final groups = await service.getWorkGroupsFromSession();

    expect(groups, hasLength(1));
    expect(groups.single.workGroupId, 'work-1');
    expect(groups.single.storeName, 'Loja em cache');
    expect(groups.single.storeAddress, 'Endereco em cache');
  });
}
