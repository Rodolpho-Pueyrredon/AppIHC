import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/services/product_lookup_provider.dart';

class OpenFoodFactsLookupProvider implements ProductLookupProvider {
  OpenFoodFactsLookupProvider({
    required HttpJsonClient httpJsonClient,
  }) : _httpJsonClient = httpJsonClient;

  final HttpJsonClient _httpJsonClient;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final json = await _httpJsonClient.getJson(uri);
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final status = (json['status'] as num?)?.toInt() ?? 0;
      if (status != 1) {
        return null;
      }

      final productJson = json['product'];
      if (productJson is! Map<String, dynamic>) {
        return null;
      }

      return Product(
        barcode: barcode,
        name: _cleanText(productJson['product_name']),
        brand: _cleanText(productJson['brands']),
        category: _cleanText(productJson['categories']),
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
