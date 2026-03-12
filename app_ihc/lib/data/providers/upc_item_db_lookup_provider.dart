import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/services/product_lookup_provider.dart';

class UpcItemDbLookupProvider implements ProductLookupProvider {
  UpcItemDbLookupProvider({
    required HttpJsonClient httpJsonClient,
    required String? apiKey,
  })  : _httpJsonClient = httpJsonClient,
        _apiKey = apiKey;

  final HttpJsonClient _httpJsonClient;
  final String? _apiKey;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    final key = _apiKey?.trim();

    try {
      final hasApiKey = key != null && key.isNotEmpty;
      final uri = Uri.parse(
        hasApiKey
            ? 'https://api.upcitemdb.com/prod/v1/lookup'
            : 'https://api.upcitemdb.com/prod/trial/lookup',
      )
          .replace(queryParameters: {'upc': barcode});
      final json = await _httpJsonClient.getJson(
        uri,
        headers: hasApiKey ? {'user_key': key} : null,
      );

      if (json is! Map<String, dynamic>) {
        return null;
      }

      final items = json['items'];
      if (items is! List || items.isEmpty) {
        return null;
      }

      final item = items.first;
      if (item is! Map<String, dynamic>) {
        return null;
      }

      return Product(
        barcode: barcode,
        name: _cleanText(item['title']),
        brand: _cleanText(item['brand']),
        category: _extractCategory(item),
      );
    } catch (_) {
      return null;
    }
  }

  String? _extractCategory(Map<String, dynamic> item) {
    final direct = _cleanText(item['category']);
    if (direct != null) {
      return direct;
    }

    final categoryPath = item['category_path'];
    if (categoryPath is List && categoryPath.isNotEmpty) {
      return _cleanText(categoryPath.first);
    }

    return null;
  }

  String? _cleanText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
