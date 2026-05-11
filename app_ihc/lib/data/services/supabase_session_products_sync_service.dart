import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/core/constants/database_schema.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/services/session_products_sync_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class SupabaseSessionProductsSyncService
    implements SessionProductsSyncServiceContract {
  SupabaseSessionProductsSyncService({
    required SupabaseApiConfig config,
    required HttpJsonClient httpJsonClient,
    required SQLiteServiceContract sqliteService,
  }) : _config = config,
       _httpJsonClient = httpJsonClient,
       _sqliteService = sqliteService;

  static const _productsTable = 'products';
  static const _sessionTable = 'sessao';

  final SupabaseApiConfig _config;
  final HttpJsonClient _httpJsonClient;
  final SQLiteServiceContract _sqliteService;

  @override
  Future<int> syncProductsFromSession() async {
    await _ensureTables();

    final username = await _getSessionUsername();
    if (username == null) {
      return 0;
    }

    final response = await _httpJsonClient.getJson(
      _config.tableUri(
        'works_full',
        queryParameters: {'collaborator_username': 'eq.$username'},
      ),
      headers: _config.headers,
    );

    if (response is! List) {
      return 0;
    }

    var insertedCount = 0;
    for (final item in response) {
      if (item is! Map<String, Object?>) {
        continue;
      }

      final barcode = _stringValue(item['barcode']);
      final workId = _stringValue(item['work_id']);
      if (barcode == null || workId == null) {
        continue;
      }

      final exists = await _productExists(barcode: barcode, workId: workId);
      if (exists) {
        continue;
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _sqliteService.insert(_productsTable, {
        'barcode': barcode,
        'work_id': workId,
        'category': _stringValue(item['category']),
        'brand': _stringValue(item['brand']),
        'product_name': _stringValue(item['product_name']),
        'created_at': nowIso,
        'updated_at': nowIso,
      });
      insertedCount++;
    }

    return insertedCount;
  }

  Future<void> _ensureTables() async {
    await _sqliteService.execute(DatabaseSchema.createSessionTable);
    await _sqliteService.execute(DatabaseSchema.createProductsTable);
  }

  Future<String?> _getSessionUsername() async {
    final rows = await _sqliteService.query(
      _sessionTable,
      columns: ['user'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return _stringValue(rows.first['user']);
  }

  Future<bool> _productExists({
    required String barcode,
    required String workId,
  }) async {
    final rows = await _sqliteService.query(
      _productsTable,
      columns: ['barcode'],
      where: 'barcode = ? AND work_id = ?',
      whereArgs: [barcode, workId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
