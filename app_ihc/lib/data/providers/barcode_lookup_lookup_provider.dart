import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/services/product_lookup_provider.dart';

class BarcodeLookupLookupProvider implements ProductLookupProvider {
  BarcodeLookupLookupProvider({
    required HttpJsonClient httpJsonClient,
    required String? apiKey,
  })  : _httpJsonClient = httpJsonClient,
        _apiKey = apiKey;

  final HttpJsonClient _httpJsonClient;
  final String? _apiKey;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    final key = _apiKey?.trim();
    if (key == null || key.isEmpty) {
      // Falha silenciosa quando chave nao esta configurada.
      return null;
    }

    try {
      final uri = Uri.parse('https://api.barcodelookup.com/v3/products')
          .replace(queryParameters: {
        'barcode': barcode,
        'formatted': 'y',
        'key': key,
      });

      final json = await _httpJsonClient.getJson(uri);
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final products = json['products'];
      if (products is! List || products.isEmpty) {
        return null;
      }

      final product = products.first;
      if (product is! Map<String, dynamic>) {
        return null;
      }

      return Product(
        barcode: barcode,
        name: _cleanText(product['title']),
        brand: _cleanText(product['brand']),
        category: _cleanText(product['category']),
      );
    } catch (_) {
      return null;
    }
  }

  String? _cleanText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
