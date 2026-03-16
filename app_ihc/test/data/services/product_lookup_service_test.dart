import 'package:app_ihc/data/services/product_lookup_service.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> _byBarcode = {};

  @override
  Future<Product?> findByBarcode(String barcode) async {
    return _byBarcode[barcode];
  }

  @override
  Future<Product> upsertByBarcode(Product product) async {
    _byBarcode[product.barcode] = product;
    return product;
  }
}

void main() {
  test('uses local product when barcode exists in database', () async {
    final repository = _FakeProductRepository();
    await repository.upsertByBarcode(
      const Product(barcode: '123', name: 'Local Product', brand: 'Brand X'),
    );

    final service = ProductLookupService(
      productRepository: repository,
    );

    final result = await service.lookupByBarcode('123');

    expect(result.name, 'Local Product');
    expect(result.brand, 'Brand X');
  });

  test('returns empty structure for manual fill when product is missing', () async {
    final repository = _FakeProductRepository();
    final service = ProductLookupService(
      productRepository: repository,
    );

    final result = await service.lookupByBarcode('777');

    expect(result.barcode, '777');
    expect(result.name, isNull);
    expect(result.brand, isNull);
    expect(result.category, isNull);
  });

  test('returns empty product for blank barcode input', () async {
    final repository = _FakeProductRepository();
    final service = ProductLookupService(
      productRepository: repository,
    );

    final result = await service.lookupByBarcode('   ');

    expect(result.barcode, '');
  });
}
