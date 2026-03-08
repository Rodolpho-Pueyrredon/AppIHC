import 'package:app_ihc/core/utils/store_name_normalizer.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl({
    required SQLiteServiceContract sqliteService,
  }) : _sqliteService = sqliteService;

  static const _table = 'stores';
  final SQLiteServiceContract _sqliteService;

  @override
  Future<Store?> findById(int id) async {
    final rows = await _sqliteService.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<Store?> findByNormalizedName(String normalizedName) async {
    final rows = await _sqliteService.query(
      _table,
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<Store> upsertByName(String name) async {
    final normalizedName = normalizeStoreName(name);
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final existing = await findByNormalizedName(normalizedName);

    if (existing != null) {
      await _sqliteService.update(
        _table,
        {
          'name': name,
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );

      final updated = await findById(existing.id!);
      return updated ?? existing;
    }

    final insertedId = await _sqliteService.insert(
      _table,
      {
        'name': name,
        'normalized_name': normalizedName,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
    );

    final inserted = await findById(insertedId);
    return inserted ??
        Store(
          id: insertedId,
          name: name,
          normalizedName: normalizedName,
          createdAt: DateTime.parse(nowIso),
          updatedAt: DateTime.parse(nowIso),
        );
  }

  Store _fromRow(Map<String, Object?> row) {
    return Store(
      id: row['id'] as int?,
      name: row['name'] as String? ?? '',
      normalizedName: row['normalized_name'] as String?,
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
