import 'package:app_ihc/domain/models/product.dart';

abstract interface class ProductLookupServiceContract {
  Future<Product> lookupByBarcode(String barcode);
}
