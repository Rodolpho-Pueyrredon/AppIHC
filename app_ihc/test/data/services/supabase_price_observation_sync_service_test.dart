import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/supabase_price_observation_sync_service.dart';
import 'package:app_ihc/domain/models/price_observation_sync_key.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpJsonClient implements HttpJsonClient {
  _FakeHttpJsonClient({this.postResponse});

  final Object? postResponse;
  final postedUris = <Uri>[];
  final postedHeaders = <Map<String, String>?>[];
  final postedBodies = <Object?>[];

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    postedUris.add(uri);
    postedHeaders.add(headers);
    postedBodies.add(body);
    return postResponse;
  }
}

class _FakeSQLiteService implements SQLiteServiceContract {
  _FakeSQLiteService(
    this.rows, {
    List<Map<String, Object?>>? productRows,
    List<Map<String, Object?>>? sessionRows,
  }) : productRows = productRows ?? <Map<String, Object?>>[],
       sessionRows = sessionRows ?? <Map<String, Object?>>[];

  final List<Map<String, Object?>> rows;
  final List<Map<String, Object?>> productRows;
  final List<Map<String, Object?>> sessionRows;
  final deleteCalls = <_DeleteCall>[];

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
    if (table == 'price_observations') {
      return rows;
    }

    if (table == 'sessao') {
      return sessionRows;
    }

    return const [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final workIds = arguments?.whereType<String>().toSet();

    return rows
        .where((row) {
          final barcode = row['product_barcode'];
          final workId = row['work_id'];
          final matchesWorkId =
              workIds == null || workIds.isEmpty || workIds.contains(workId);
          final matchesProduct = productRows.any(
            (product) =>
                product['barcode'] == barcode && product['work_id'] == workId,
          );

          return matchesWorkId && matchesProduct;
        })
        .map(Map<String, Object?>.from)
        .toList(growable: false);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(SQLiteTransactionContract transaction) action,
  ) {
    return action(_FakeSQLiteTransaction(this));
  }

  Future<int> deleteInTransaction(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    deleteCalls.add(_DeleteCall(table: table, whereArgs: whereArgs));

    if (table == 'price_observations') {
      final barcode = whereArgs[0];
      final workId = whereArgs[1];
      final before = rows.length;
      rows.removeWhere(
        (row) => row['product_barcode'] == barcode && row['work_id'] == workId,
      );
      return before - rows.length;
    }

    if (table == 'products') {
      final barcode = whereArgs[0];
      final workId = whereArgs[1];
      final before = productRows.length;
      productRows.removeWhere(
        (row) => row['barcode'] == barcode && row['work_id'] == workId,
      );
      return before - productRows.length;
    }

    if (table == 'sessao') {
      final workId = whereArgs[0];
      final before = sessionRows.length;
      sessionRows.removeWhere((row) => row['work_id'] == workId);
      return before - sessionRows.length;
    }

    return 0;
  }
}

class _FakeSQLiteTransaction implements SQLiteTransactionContract {
  _FakeSQLiteTransaction(this._sqliteService);

  final _FakeSQLiteService _sqliteService;

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) {
    return _sqliteService.deleteInTransaction(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}

class _DeleteCall {
  const _DeleteCall({required this.table, required this.whereArgs});

  final String table;
  final List<Object?> whereArgs;
}

void main() {
  List<Map<String, Object?>> observationsFrom(List<Map<String, Object?>> rows) {
    return rows
        .map(
          (row) => {
            'product_barcode': row['product_barcode'],
            'store_id': row['store_id'],
            'work_id': row['work_id'],
            'price_cents': row['price_cents'],
            'observed_at': row['observed_at'],
          },
        )
        .toList(growable: false);
  }

  test('sends the received price observation rows to the insert rpc', () async {
    final httpClient = _FakeHttpJsonClient(
      postResponse: [
        {
          'inserted_count': 2,
          'updated_works_count': 2,
          'removed_work_ids': <String>[],
        },
      ],
    );
    final service = SupabasePriceObservationSyncService(
      config: const SupabaseApiConfig(
        baseUrl: 'https://example.com/rest/v1',
        anonKey: 'anon-key',
      ),
      httpJsonClient: httpClient,
      sqliteService: _FakeSQLiteService(const []),
    );
    final rows = [
      {
        'id': 1,
        'product_barcode': '7891095100729',
        'store_id': 2,
        'price_cents': 599,
        'observed_at': '2026-05-12T10:00:00.000Z',
        'created_at': '2026-05-12T10:01:00.000Z',
        'work_id': 'work-1',
      },
      {
        'id': 2,
        'product_barcode': '1234567890123',
        'store_id': 3,
        'price_cents': 1250,
        'observed_at': '2026-05-12T10:05:00.000Z',
        'created_at': '2026-05-12T10:06:00.000Z',
        'work_id': 'work-2',
      },
    ];

    final insertedKeys = await service.insertPriceObservationRows(rows);

    expect(
      httpClient.postedUris.single.path,
      '/rest/v1/rpc/insert_price_observations',
    );
    expect(httpClient.postedUris.single.queryParameters, isEmpty);
    expect(httpClient.postedBodies.single, {
      'observations': observationsFrom(rows),
    });
    expect(httpClient.postedHeaders.single, containsPair('apikey', 'anon-key'));
    expect(
      httpClient.postedHeaders.single,
      containsPair('Authorization', 'Bearer anon-key'),
    );
    expect(insertedKeys, const [
      PriceObservationSyncKey(barcode: '7891095100729', workId: 'work-1'),
      PriceObservationSyncKey(barcode: '1234567890123', workId: 'work-2'),
    ]);
  });

  test('syncs all local price observation rows', () async {
    final httpClient = _FakeHttpJsonClient(
      postResponse: [
        {
          'inserted_count': 2,
          'updated_works_count': 2,
          'removed_work_ids': ['work-1'],
        },
      ],
    );
    final rows = [
      {
        'id': 1,
        'product_barcode': '7891095100729',
        'store_id': 2,
        'price_cents': 599,
        'observed_at': '2026-05-12T10:00:00.000Z',
        'created_at': '2026-05-12T10:01:00.000Z',
        'work_id': 'work-1',
      },
      {
        'id': 2,
        'product_barcode': '1234567890123',
        'store_id': 3,
        'price_cents': 1250,
        'observed_at': '2026-05-12T10:05:00.000Z',
        'created_at': '2026-05-12T10:06:00.000Z',
        'work_id': 'work-1',
      },
    ];
    final productRows = [
      {'barcode': '7891095100729', 'work_id': 'work-1'},
      {'barcode': '1234567890123', 'work_id': 'work-1'},
    ];
    final sessionRows = [
      {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
      {'user': 'miao_yin@empresa.com', 'work_id': 'other-work'},
    ];
    final sqliteService = _FakeSQLiteService(
      rows,
      productRows: productRows,
      sessionRows: sessionRows,
    );
    final expectedPostedRows = observationsFrom(rows);
    final service = SupabasePriceObservationSyncService(
      config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
      httpJsonClient: httpClient,
      sqliteService: sqliteService,
    );

    final insertedKeys = await service.syncLocalPriceObservations();

    expect(insertedKeys, const [
      PriceObservationSyncKey(barcode: '7891095100729', workId: 'work-1'),
      PriceObservationSyncKey(barcode: '1234567890123', workId: 'work-1'),
    ]);
    expect(httpClient.postedBodies, [
      {'observations': expectedPostedRows},
    ]);
    expect(httpClient.postedUris, hasLength(1));
    expect(sqliteService.rows, isEmpty);
    expect(sqliteService.productRows, isEmpty);
    expect(sqliteService.sessionRows, [
      {'user': 'miao_yin@empresa.com', 'work_id': 'other-work'},
    ]);
    expect(sqliteService.deleteCalls.map((call) => call.table), [
      'price_observations',
      'price_observations',
      'products',
      'products',
      'sessao',
    ]);
  });

  test(
    'syncs only rows matching products from the requested work ids',
    () async {
      final httpClient = _FakeHttpJsonClient(
        postResponse: [
          {
            'inserted_count': 1,
            'updated_works_count': 1,
            'removed_work_ids': ['work-1'],
          },
        ],
      );
      final rows = [
        {
          'id': 1,
          'product_barcode': '7891095100729',
          'store_id': 2,
          'price_cents': 599,
          'observed_at': '2026-05-12T10:00:00.000Z',
          'created_at': '2026-05-12T10:01:00.000Z',
          'work_id': 'work-1',
        },
        {
          'id': 2,
          'product_barcode': '1234567890123',
          'store_id': 3,
          'price_cents': 1250,
          'observed_at': '2026-05-12T10:05:00.000Z',
          'created_at': '2026-05-12T10:06:00.000Z',
          'work_id': 'other-work',
        },
        {
          'id': 3,
          'product_barcode': '5555555555555',
          'store_id': 4,
          'price_cents': 300,
          'observed_at': '2026-05-12T10:07:00.000Z',
          'created_at': '2026-05-12T10:08:00.000Z',
          'work_id': 'work-1',
        },
      ];
      final productRows = [
        {'barcode': '7891095100729', 'work_id': 'work-1'},
        {'barcode': '1234567890123', 'work_id': 'other-work'},
      ];
      final sessionRows = [
        {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
        {'user': 'miao_yin@empresa.com', 'work_id': 'other-work'},
      ];
      final sqliteService = _FakeSQLiteService(
        rows,
        productRows: productRows,
        sessionRows: sessionRows,
      );
      final expectedPostedRows = observationsFrom([rows.first]);
      final service = SupabasePriceObservationSyncService(
        config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
        httpJsonClient: httpClient,
        sqliteService: sqliteService,
      );

      final insertedKeys = await service.syncLocalPriceObservationsForWorkIds([
        'work-1',
      ]);

      expect(insertedKeys, const [
        PriceObservationSyncKey(barcode: '7891095100729', workId: 'work-1'),
      ]);
      expect(httpClient.postedBodies.single, {
        'observations': expectedPostedRows,
      });
      expect(sqliteService.rows.map((row) => row['id']), [2, 3]);
      expect(sqliteService.productRows, [
        {'barcode': '1234567890123', 'work_id': 'other-work'},
      ]);
      expect(sqliteService.sessionRows, [
        {'user': 'miao_yin@empresa.com', 'work_id': 'other-work'},
      ]);
    },
  );

  test(
    'does not delete local rows when the rpc updates no work rows',
    () async {
      final httpClient = _FakeHttpJsonClient(
        postResponse: [
          {
            'inserted_count': 1,
            'updated_works_count': 0,
            'removed_work_ids': ['work-1'],
          },
        ],
      );
      final rows = [
        {
          'id': 1,
          'product_barcode': '7891095100729',
          'store_id': 2,
          'price_cents': 599,
          'observed_at': '2026-05-12T10:00:00.000Z',
          'created_at': '2026-05-12T10:01:00.000Z',
          'work_id': 'work-1',
        },
      ];
      final productRows = [
        {'barcode': '7891095100729', 'work_id': 'work-1'},
      ];
      final sessionRows = [
        {'user': 'miao_yin@empresa.com', 'work_id': 'work-1'},
      ];
      final sqliteService = _FakeSQLiteService(
        rows,
        productRows: productRows,
        sessionRows: sessionRows,
      );
      final service = SupabasePriceObservationSyncService(
        config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
        httpJsonClient: httpClient,
        sqliteService: sqliteService,
      );

      expect(
        () => service.syncLocalPriceObservations(),
        throwsA(isA<StateError>()),
      );
      expect(sqliteService.rows, hasLength(1));
      expect(sqliteService.productRows, hasLength(1));
      expect(sqliteService.sessionRows, hasLength(1));
      expect(sqliteService.deleteCalls, isEmpty);
    },
  );
}
