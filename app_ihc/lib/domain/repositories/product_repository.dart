import 'package:app_ihc/domain/models/product.dart';

abstract interface class ProductRepository {
  Future<Product> upsertByBarcode(Product product);
  Future<Product?> findByBarcode(String barcode);
  Future<List<Product>> findByWorkId(String workId);
}
