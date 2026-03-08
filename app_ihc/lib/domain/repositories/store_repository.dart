import 'package:app_ihc/domain/models/store.dart';

abstract interface class StoreRepository {
  Future<Store> upsertByName(String name);
  Future<Store?> findByNormalizedName(String normalizedName);
  Future<Store?> findById(int id);
}
