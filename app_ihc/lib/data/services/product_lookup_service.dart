import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/services/product_lookup_provider.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';

class ProductLookupService implements ProductLookupServiceContract {
  ProductLookupService({
    required ProductRepository productRepository,
    required List<ProductLookupProvider> providersInOrder,
  })  : _productRepository = productRepository,
        _providersInOrder = providersInOrder;

  final ProductRepository _productRepository;
  final List<ProductLookupProvider> _providersInOrder;

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

    for (final provider in _providersInOrder) {
      final found = await provider.fetchByBarcode(normalizedBarcode);
      if (found == null) {
        continue;
      }

      final completed = found.copyWith(barcode: normalizedBarcode);
      final persisted = await _productRepository.upsertByBarcode(completed);
      return persisted;
    }

    // Estrutura vazia para preenchimento manual.
    return Product(barcode: normalizedBarcode);
  }
}
