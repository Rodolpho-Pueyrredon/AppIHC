import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';

class LookupProductByBarcodeUseCase {
  LookupProductByBarcodeUseCase({
    required ProductLookupServiceContract productLookupService,
  }) : _productLookupService = productLookupService;

  final ProductLookupServiceContract _productLookupService;

  Future<Product> call(String barcode) {
    return _productLookupService.lookupByBarcode(barcode);
  }
}
