import 'package:app_ihc/domain/models/product.dart';

abstract interface class ProductLookupProvider {
  Future<Product?> fetchByBarcode(String barcode);
}
