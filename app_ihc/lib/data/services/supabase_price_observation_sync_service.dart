import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/price_observation_sync_key.dart';
import 'package:app_ihc/domain/services/price_observation_sync_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class SupabasePriceObservationSyncService
    implements PriceObservationSyncServiceContract {
  SupabasePriceObservationSyncService({
    required SupabaseApiConfig config,
    required HttpJsonClient httpJsonClient,
    required SQLiteServiceContract sqliteService,
  }) : _config = config,
       _httpJsonClient = httpJsonClient,
       _sqliteService = sqliteService;

  static const _table = 'price_observations';
  static const _productsTable = 'products';
  static const _sessionTable = 'sessao';
  static const _barcodeColumn = 'product_barcode';
  static const _workIdColumn = 'work_id';

  final SupabaseApiConfig _config;
  final HttpJsonClient _httpJsonClient;
  final SQLiteServiceContract _sqliteService;

  @override
  Future<List<PriceObservationSyncKey>> insertPriceObservationRows(
    List<Map<String, Object?>> rows,
  ) async {
    final result = await _insertPriceObservationRows(rows);
    return result.insertedKeys;
  }

  Future<_PriceObservationInsertResult> _insertPriceObservationRows(
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.isEmpty) {
      return const _PriceObservationInsertResult(
        insertedKeys: [],
        removedWorkIds: [],
      );
    }

    if (rows.any((row) => row.isEmpty)) {
      throw ArgumentError('Price observation rows cannot contain empty rows.');
    }

    final observations = rows
        .map(_toSupabaseObservation)
        .toList(growable: false);
    final insertedKeys = _syncKeysFromRows(observations);

    final response = await _httpJsonClient.postJson(
      _config.rpcUri('insert_price_observations'),
      headers: _config.headers,
      body: {'observations': observations},
    );
    final removedWorkIds = _validateRpcResult(
      response,
      expectedInsertedCount: observations.length,
    );

    return _PriceObservationInsertResult(
      insertedKeys: insertedKeys,
      removedWorkIds: removedWorkIds,
    );
  }

  @override
  Future<List<PriceObservationSyncKey>> syncLocalPriceObservations() async {
    final rows = await _getLocalRowsWithMatchingProducts();
    final result = await _insertPriceObservationRows(rows);
    await _deleteSyncedLocalRows(
      result.insertedKeys,
      removedWorkIds: result.removedWorkIds,
    );

    return result.insertedKeys;
  }

  @override
  Future<List<PriceObservationSyncKey>> syncLocalPriceObservationsForWorkIds(
    Iterable<String> workIds,
  ) async {
    final normalizedWorkIds = workIds
        .map((workId) => workId.trim())
        .where((workId) => workId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedWorkIds.isEmpty) {
      return const [];
    }

    final rows = await _getLocalRowsWithMatchingProducts(
      workIds: normalizedWorkIds,
    );
    final result = await _insertPriceObservationRows(rows);
    await _deleteSyncedLocalRows(
      result.insertedKeys,
      removedWorkIds: result.removedWorkIds,
    );

    return result.insertedKeys;
  }

  Future<List<Map<String, Object?>>> _getLocalRowsWithMatchingProducts({
    List<String>? workIds,
  }) {
    final hasWorkFilter = workIds != null && workIds.isNotEmpty;
    final workFilter = hasWorkFilter
        ? 'AND po.$_workIdColumn IN (${List.filled(workIds.length, '?').join(', ')})'
        : '';

    return _sqliteService.rawQuery('''
SELECT po.*
FROM $_table po
WHERE EXISTS (
  SELECT 1
  FROM $_productsTable p
  WHERE p.barcode = po.$_barcodeColumn
    AND p.$_workIdColumn = po.$_workIdColumn
)
$workFilter
''', hasWorkFilter ? workIds : null);
  }

  Map<String, Object?> _toSupabaseObservation(Map<String, Object?> row) {
    return {
      _barcodeColumn: row[_barcodeColumn],
      'store_id': row['store_id'],
      _workIdColumn: row[_workIdColumn],
      'price_cents': row['price_cents'],
      'observed_at': row['observed_at'],
    };
  }

  Future<void> _deleteSyncedLocalRows(
    List<PriceObservationSyncKey> keys, {
    required List<String> removedWorkIds,
  }) async {
    if (keys.isEmpty && removedWorkIds.isEmpty) {
      return;
    }

    await _sqliteService.transaction((transaction) async {
      for (final key in keys) {
        await transaction.delete(
          _table,
          where: '$_barcodeColumn = ? AND $_workIdColumn = ?',
          whereArgs: [key.barcode, key.workId],
        );
      }

      for (final key in keys) {
        await transaction.delete(
          _productsTable,
          where: 'barcode = ? AND $_workIdColumn = ?',
          whereArgs: [key.barcode, key.workId],
        );
      }

      for (final workId in removedWorkIds) {
        await transaction.delete(
          _sessionTable,
          where: '$_workIdColumn = ?',
          whereArgs: [workId],
        );
      }
    });
  }

  List<PriceObservationSyncKey> _syncKeysFromRows(
    List<Map<String, Object?>> rows,
  ) {
    final keys = <PriceObservationSyncKey>[];
    for (final row in rows) {
      final barcode = _stringValue(row[_barcodeColumn]);
      final workId = _stringValue(row[_workIdColumn]);
      if (barcode == null || workId == null) {
        throw const FormatException(
          'Price observation row must include product_barcode and work_id.',
        );
      }

      keys.add(PriceObservationSyncKey(barcode: barcode, workId: workId));
    }

    return keys;
  }

  List<String> _validateRpcResult(
    Object? response, {
    required int expectedInsertedCount,
  }) {
    final result = _firstRpcResult(response);
    final insertedCount = _intValue(result['inserted_count']);
    final updatedWorksCount = _intValue(result['updated_works_count']);
    final removedWorkIds = _stringListValue(result['removed_work_ids']);

    if (insertedCount != expectedInsertedCount) {
      throw StateError(
        'Supabase inserted $insertedCount of $expectedInsertedCount price observations.',
      );
    }

    if (updatedWorksCount <= 0) {
      throw StateError('Supabase did not mark any work rows as done.');
    }

    return removedWorkIds;
  }

  Map<String, Object?> _firstRpcResult(Object? response) {
    if (response is List && response.isNotEmpty) {
      final item = response.first;
      if (item is Map<String, Object?>) {
        return item;
      }
    }

    if (response is Map<String, Object?>) {
      return response;
    }

    throw const FormatException(
      'Supabase RPC response must include inserted_count and updated_works_count.',
    );
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  List<String> _stringListValue(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((workId) => workId.trim())
        .where((workId) => workId.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PriceObservationInsertResult {
  const _PriceObservationInsertResult({
    required this.insertedKeys,
    required this.removedWorkIds,
  });

  final List<PriceObservationSyncKey> insertedKeys;
  final List<String> removedWorkIds;
}
