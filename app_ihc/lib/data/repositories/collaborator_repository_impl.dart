import 'package:app_ihc/domain/models/collaborator.dart';
import 'package:app_ihc/domain/repositories/collaborator_repository.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class CollaboratorRepositoryImpl implements CollaboratorRepository {
  CollaboratorRepositoryImpl({
    required SQLiteServiceContract sqliteService,
  }) : _sqliteService = sqliteService;

  static const _table = 'collaborator';
  final SQLiteServiceContract _sqliteService;

  @override
  Future<Collaborator?> findByUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final rows = await _sqliteService.query(
      _table,
      where: 'username = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<Collaborator?> findById(int id) async {
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
  Future<Collaborator> findOrCreateByUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Username is required.');
    }

    final existing = await findByUsername(normalized);
    if (existing != null) {
      return existing;
    }

    final insertedId = await _sqliteService.insert(
      _table,
      {
        'username': normalized,
      },
    );

    return (await findById(insertedId)) ??
        Collaborator(
          id: insertedId,
          username: normalized,
        );
  }

  Collaborator _fromRow(Map<String, Object?> row) {
    return Collaborator(
      id: row['id'] as int?,
      username: row['username'] as String? ?? '',
      friendlyName: row['friendly_name'] as String?,
      createdAt: _parseDate(row['created_at']),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
