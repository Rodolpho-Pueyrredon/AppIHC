library weebi_barcode_scanner;

import 'package:weebi_openfoodfacts_service/weebi_openfoodfacts_service.dart';

// Export the main widget and supporting classes
export 'src/barcode_scanner_widget.dart';
export 'src/barcode_result.dart';
export 'src/scanner_config.dart';
export 'src/platform_camera_manager.dart';
export 'src/simple_barcode_scanner.dart';

// Export OpenFoodFacts types for convenience
export 'package:weebi_openfoodfacts_service/weebi_openfoodfacts_service.dart' show OFFProduct, OFFProductType, WeebiOpenFoodFactsService;


/// Public API for OpenFoodFacts integration
class WeebiBarcodeScannerAPI {
  /// Initialize OpenFoodFacts (no credentials required)
  static Future<void> initializeOpenFoodFacts({
    String appName = 'WeebiBarcodeScannerApp',
    bool enablePricing = false,
    bool enableBeautyProducts = true,
    bool enableGeneralProducts = true,
  }) async {
    await WeebiOpenFoodFactsService.initialize(
      appName: appName,
      enablePricing: enablePricing,
      enableBeautyProducts: enableBeautyProducts,
      enableGeneralProducts: enableGeneralProducts,
    );
  }

  /// Fetch product info by barcode (food, beauty, or general)
  static Future<OFFProduct?> fetchProduct(String barcode) async {
    // Try food first, then beauty, then general
    final food = await WeebiOpenFoodFactsService.getProduct(barcode);
    if (food != null) return food;
    
    final beauty = await WeebiOpenFoodFactsService.getBeautyProduct(barcode);
    if (beauty != null) return beauty;
    
    return await WeebiOpenFoodFactsService.getGeneralProduct(barcode);
  }

  /// Fetch food product only
  static Future<OFFProduct?> fetchFoodProduct(String barcode) =>
      WeebiOpenFoodFactsService.getProduct(barcode);

  /// Fetch beauty product only
  static Future<OFFProduct?> fetchBeautyProduct(String barcode) =>
      WeebiOpenFoodFactsService.getBeautyProduct(barcode);

  /// Fetch general product only
  static Future<OFFProduct?> fetchGeneralProduct(String barcode) =>
      WeebiOpenFoodFactsService.getGeneralProduct(barcode);

  /// Get available OpenFoodFacts features
  static Map<String, bool> getAvailableFeatures() =>
      WeebiOpenFoodFactsService.getAvailableFeatures();

  /// Get credential setup info (for pricing, etc.)
  static String getCredentialSetupInfo() =>
      WeebiOpenFoodFactsService.getCredentialSetupInfo();
}