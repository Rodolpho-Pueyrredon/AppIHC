abstract interface class SQLiteServiceContract {
  Future<void> init();
  Future<void> execute(String sql);
  Future<int> insert(String table, Map<String, Object?> values);
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  });
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  });
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);
}
