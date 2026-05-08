import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required SQLiteServiceContract sqliteService,
  }) : _sqliteService = sqliteService;

  static const _table = 'products';
  final SQLiteServiceContract _sqliteService;

  @override
  Future<Product?> findByBarcode(String barcode) async {
    final rows = await _sqliteService.query(
      _table,
      where: 'barcode = ?',
      whereArgs: [barcode],
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
    final existing = await findByBarcode(normalizedBarcode);

    if (existing != null) {
      await _sqliteService.update(
        _table,
        {
          'name': product.name,
          'category': product.category,
          'brand': product.brand,
          'updated_at': nowIso,
        },
        where: 'barcode = ?',
        whereArgs: [normalizedBarcode],
      );

      return (await findByBarcode(normalizedBarcode)) ??
          existing.copyWith(
            name: product.name,
            brand: product.brand,
            category: product.category,
            updatedAt: DateTime.parse(nowIso),
          );
    }

    await _sqliteService.insert(
      _table,
      {
        'barcode': normalizedBarcode,
        'name': product.name,
        'category': product.category,
        'brand': product.brand,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
    );

    return (await findByBarcode(normalizedBarcode)) ??
        product.copyWith(
          barcode: normalizedBarcode,
          createdAt: DateTime.parse(nowIso),
          updatedAt: DateTime.parse(nowIso),
        );
  }

  Product _fromRow(Map<String, Object?> row) {
    return Product(
      barcode: row['barcode'] as String? ?? '',
      name: row['name'] as String?,
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
