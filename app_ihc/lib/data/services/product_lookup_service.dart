import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';

class ProductLookupService implements ProductLookupServiceContract {
  ProductLookupService({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  @override
  Future<Product> lookupByBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      return const Product(barcode: '');
    }

    final local = await _productRepository.findByBarcode(normalizedBarcode);
    if (local != null) {
      return local;
    }

    return Product(barcode: normalizedBarcode);
  }
}
