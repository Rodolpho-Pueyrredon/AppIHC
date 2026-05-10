import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required SQLiteServiceContract sqliteService})
    : _sqliteService = sqliteService;

  static const _table = 'products';
  final SQLiteServiceContract _sqliteService;

  @override
  Future<Product?> findByBarcode(String barcode) async {
    final rows = await _sqliteService.query(
      _table,
      where: 'barcode = ?',
      whereArgs: [barcode],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<Product> upsertByBarcode(Product product) async {
    final normalizedBarcode = product.barcode.trim();
    if (normalizedBarcode.isEmpty) {
      throw ArgumentError('Product barcode is required for upsert.');
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final normalizedWorkId = product.workId?.trim();
    final existing = await _findByBarcodeAndWorkId(
      normalizedBarcode,
      normalizedWorkId,
    );

    if (existing != null) {
      await _sqliteService.update(
        _table,
        {
          'product_name': product.name,
          'category': product.category,
          'brand': product.brand,
          'updated_at': nowIso,
        },
        where: 'barcode = ? AND work_id = ?',
        whereArgs: [normalizedBarcode, existing.workId],
      );

      return (await _findByBarcodeAndWorkId(
            normalizedBarcode,
            existing.workId,
          )) ??
          existing.copyWith(
            name: product.name,
            brand: product.brand,
            category: product.category,
            updatedAt: DateTime.parse(nowIso),
          );
    }

    if (normalizedWorkId == null || normalizedWorkId.isEmpty) {
      throw ArgumentError('Product workId is required for insert.');
    }

    await _sqliteService.insert(_table, {
      'barcode': normalizedBarcode,
      'work_id': normalizedWorkId,
      'product_name': product.name,
      'category': product.category,
      'brand': product.brand,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    return (await _findByBarcodeAndWorkId(
          normalizedBarcode,
          normalizedWorkId,
        )) ??
        product.copyWith(
          barcode: normalizedBarcode,
          workId: normalizedWorkId,
          createdAt: DateTime.parse(nowIso),
          updatedAt: DateTime.parse(nowIso),
        );
  }

  Future<Product?> _findByBarcodeAndWorkId(
    String barcode,
    String? workId,
  ) async {
    if (workId == null || workId.isEmpty) {
      return findByBarcode(barcode);
    }

    final rows = await _sqliteService.query(
      _table,
      where: 'barcode = ? AND work_id = ?',
      whereArgs: [barcode, workId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Product _fromRow(Map<String, Object?> row) {
    return Product(
      barcode: row['barcode'] as String? ?? '',
      workId: row['work_id'] as String?,
      name: row['product_name'] as String?,
      brand: row['brand'] as String?,
      category: row['category'] as String?,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
