import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/supabase_session_products_sync_service.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpJsonClient implements HttpJsonClient {
  _FakeHttpJsonClient(this.response);

  final dynamic response;
  Uri? lastUri;

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    lastUri = uri;
    return response;
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
  final sessionRows = <Map<String, Object?>>[];
  final productRows = <Map<String, Object?>>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> execute(String sql) async {}

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    if (table == 'products') {
      productRows.add(Map<String, Object?>.from(values));
      return productRows.length;
    }

    if (table == 'sessao') {
      sessionRows.add(Map<String, Object?>.from(values));
      return sessionRows.length;
    }

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
    if (table == 'sessao') {
      return sessionRows.take(limit ?? sessionRows.length).toList();
    }

    if (table == 'products') {
      final barcode = whereArgs?[0];
      final workId = whereArgs?[1];
      return productRows
          .where((row) => row['barcode'] == barcode && row['work_id'] == workId)
          .take(limit ?? productRows.length)
          .toList();
    }

    return const [];
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
  test('syncs only products missing from the local products table', () async {
    final sqliteService = _FakeSQLiteService()
      ..sessionRows.add({'user': 'miao_yin@empresa.com', 'work_id': 'work-1'})
      ..productRows.add({
        'barcode': '7891095100729',
        'work_id': 'work-1',
        'category': 'Alimento',
        'brand': 'Yoki',
        'product_name': 'Pipoca Sabor Bacon',
      });
    final httpClient = _FakeHttpJsonClient([
      {
        'work_id': 'work-1',
        'collaborator_username': 'miao_yin@empresa.com',
        'barcode': '7891095100729',
        'category': 'Alimento',
        'brand': 'Yoki',
        'product_name': 'Pipoca Sabor Bacon',
      },
      {
        'work_id': 'work-2',
        'collaborator_username': 'miao_yin@empresa.com',
        'barcode': '1234567890123',
        'category': 'Bebida',
        'brand': 'Marca',
        'product_name': 'Suco',
      },
    ]);
    final service = SupabaseSessionProductsSyncService(
      config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
      httpJsonClient: httpClient,
      sqliteService: sqliteService,
    );

    final insertedCount = await service.syncProductsFromSession();

    expect(insertedCount, 1);
    expect(sqliteService.productRows, hasLength(2));
    expect(sqliteService.productRows.last['barcode'], '1234567890123');
    expect(sqliteService.productRows.last['work_id'], 'work-2');
    expect(sqliteService.productRows.last['category'], 'Bebida');
    expect(sqliteService.productRows.last['brand'], 'Marca');
    expect(sqliteService.productRows.last['product_name'], 'Suco');
    expect(
      httpClient.lastUri.toString(),
      'https://example.com/rest/v1/works_full?collaborator_username=eq.miao_yin%40empresa.com&done=eq.false',
    );
  });
}
