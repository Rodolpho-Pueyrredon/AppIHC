import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/domain/repositories/price_observation_repository.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class PriceObservationRepositoryImpl implements PriceObservationRepository {
  PriceObservationRepositoryImpl({
    required SQLiteServiceContract sqliteService,
    required ProductRepository productRepository,
    required StoreRepository storeRepository,
  })  : _sqliteService = sqliteService,
        _productRepository = productRepository,
        _storeRepository = storeRepository;

  final SQLiteServiceContract _sqliteService;
  final ProductRepository _productRepository;
  final StoreRepository _storeRepository;

  @override
  Future<PriceObservation?> getById(int id) async {
    final rows = await _sqliteService.rawQuery(
      _baseSelectQuery(where: 'WHERE po.id = ?'),
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromJoinedRow(rows.first);
  }

  @override
  Future<List<PriceObservation>> getObservations() async {
    final rows = await _sqliteService.rawQuery(
      _baseSelectQuery(orderBy: 'ORDER BY po.observed_at DESC'),
    );
    return rows.map(_fromJoinedRow).toList();
  }

  @override
  Future<PriceObservation> saveObservation(PriceObservation observation) async {
    final barcode = observation.product.barcode.trim();
    if (barcode.isEmpty) {
      throw ArgumentError('Product barcode is required for upsert.');
    }

    final product = await _productRepository.upsertByBarcode(
      observation.product.copyWith(barcode: barcode),
    );
    final store = await _storeRepository.upsertByName(observation.store.name);

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final insertedId = await _sqliteService.insert(
      'price_observations',
      {
        'product_barcode': product.barcode,
        'store_id': store.id,
        'price_cents': observation.priceCents,
        'latitude': observation.latitude,
        'longitude': observation.longitude,
        'observed_at': observation.observedAt.toUtc().toIso8601String(),
        'notes': observation.note,
        'created_at': nowIso,
      },
    );

    return (await getById(insertedId)) ??
        observation.copyWith(
          id: insertedId,
          product: product,
          store: store,
          createdAt: DateTime.parse(nowIso),
        );
  }

  @override
  Future<void> updateObservation(PriceObservation observation) async {
    if (observation.id == null) {
      throw ArgumentError('Observation ID is required for update.');
    }

    final barcode = observation.product.barcode.trim();
    if (barcode.isEmpty) {
      throw ArgumentError('Product barcode is required for upsert.');
    }

    final product = await _productRepository.upsertByBarcode(
      observation.product.copyWith(barcode: barcode),
    );
    final store = await _storeRepository.upsertByName(observation.store.name);

    await _sqliteService.update(
      'price_observations',
      {
        'product_barcode': product.barcode,
        'store_id': store.id,
        'price_cents': observation.priceCents,
        'latitude': observation.latitude,
        'longitude': observation.longitude,
        'observed_at': observation.observedAt.toUtc().toIso8601String(),
        'notes': observation.note,
      },
      where: 'id = ?',
      whereArgs: [observation.id],
    );
  }

  @override
  Future<void> deleteObservation(int id) async {
    await _sqliteService.delete(
      'price_observations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String _baseSelectQuery({
    String where = '',
    String orderBy = '',
  }) {
    return '''
SELECT
  po.id AS po_id,
  po.price_cents AS po_price_cents,
  po.latitude AS po_latitude,
  po.longitude AS po_longitude,
  po.observed_at AS po_observed_at,
  po.notes AS po_notes,
  po.created_at AS po_created_at,
  p.barcode AS p_barcode,
  p.category AS p_category,
  p.brand AS p_brand,
  p.created_at AS p_created_at,
  p.updated_at AS p_updated_at,
  s.id AS s_id,
  s.name AS s_name,
  s.normalized_name AS s_normalized_name,
  s.created_at AS s_created_at,
  s.updated_at AS s_updated_at
FROM price_observations po
JOIN products p ON p.barcode = po.product_barcode
JOIN stores s ON s.id = po.store_id
$where
$orderBy
''';
  }

  PriceObservation _fromJoinedRow(Map<String, Object?> row) {
    final category = row['p_category'] as String?;
    return PriceObservation(
      id: row['po_id'] as int?,
      product: Product(
        barcode: row['p_barcode'] as String? ?? '',
        name: category,
        brand: row['p_brand'] as String?,
        category: category,
        createdAt: _parseDate(row['p_created_at']),
        updatedAt: _parseDate(row['p_updated_at']),
      ),
      store: Store(
        id: row['s_id'] as int?,
        name: row['s_name'] as String? ?? '',
        normalizedName: row['s_normalized_name'] as String?,
        createdAt: _parseDate(row['s_created_at']),
        updatedAt: _parseDate(row['s_updated_at']),
      ),
      priceCents: row['po_price_cents'] as int? ?? 0,
      latitude: (row['po_latitude'] as num?)?.toDouble() ?? 0,
      longitude: (row['po_longitude'] as num?)?.toDouble() ?? 0,
      observedAt: _parseDate(row['po_observed_at']) ?? DateTime.now().toUtc(),
      note: row['po_notes'] as String?,
      createdAt: _parseDate(row['po_created_at']),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}