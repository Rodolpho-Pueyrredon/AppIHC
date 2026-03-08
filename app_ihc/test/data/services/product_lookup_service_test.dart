import 'package:app_ihc/data/services/product_lookup_service.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/services/product_lookup_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> _byBarcode = {};

  @override
  Future<Product?> findByBarcode(String barcode) async {
    return _byBarcode[barcode];
  }

  @override
  Future<Product?> findById(int id) async {
    return null;
  }

  @override
  Future<Product> upsertByBarcode(Product product) async {
    _byBarcode[product.barcode] = product;
    return product;
  }
}

class _FakeProvider implements ProductLookupProvider {
  _FakeProvider(this.result);

  final Product? result;
  int calls = 0;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    calls += 1;
    return result;
  }
}

void main() {
  test('uses local product first and skips API providers', () async {
    final repository = _FakeProductRepository();
    await repository.upsertByBarcode(
      const Product(barcode: '123', name: 'Local Product'),
    );
    final provider = _FakeProvider(
      const Product(barcode: '123', name: 'Remote Product'),
    );

    final service = ProductLookupService(
      productRepository: repository,
      providersInOrder: [provider],
    );

    final result = await service.lookupByBarcode('123');

    expect(result.name, 'Local Product');
    expect(provider.calls, 0);
  });

  test('falls back across providers and persists first successful result', () async {
    final repository = _FakeProductRepository();
    final first = _FakeProvider(null);
    final second = _FakeProvider(
      const Product(
        barcode: '999',
        name: 'API Product',
        brand: 'Brand X',
        category: 'Category Y',
      ),
    );
    final third = _FakeProvider(
      const Product(barcode: '999', name: 'Should Not Be Called'),
    );

    final service = ProductLookupService(
      productRepository: repository,
      providersInOrder: [first, second, third],
    );

    final result = await service.lookupByBarcode('999');
    final persisted = await repository.findByBarcode('999');

    expect(first.calls, 1);
    expect(second.calls, 1);
    expect(third.calls, 0);
    expect(result.name, 'API Product');
    expect(persisted?.brand, 'Brand X');
    expect(persisted?.category, 'Category Y');
  });

  test('returns empty structure when all providers fail', () async {
    final repository = _FakeProductRepository();
    final service = ProductLookupService(
      productRepository: repository,
      providersInOrder: [_FakeProvider(null), _FakeProvider(null)],
    );

    final result = await service.lookupByBarcode('777');

    expect(result.barcode, '777');
    expect(result.name, isNull);
    expect(result.brand, isNull);
    expect(result.category, isNull);
  });
}
