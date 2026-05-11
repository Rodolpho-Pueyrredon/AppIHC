import 'package:weebi_openfoodfacts_service/weebi_openfoodfacts_service.dart';

/// Represents a barcode scanning result
class BarcodeResult {
  /// The scanned barcode text
  final String text;
  
  /// The format of the barcode (e.g., 'QR_CODE', 'EAN_13')
  final String format;
  
  /// Product name (if available)
  final String? productName;
  
  /// Product brand (if available)
  final String? productBrand;
  
  /// Confidence level of the scan (0.0 to 1.0)
  final double? confidence;
  
  /// Location of the barcode in the image (optional)
  final Map<String, int>? location;
  
  /// OpenFoodFacts product information (if available)
  final OFFProduct? product;
  
  /// Whether product information was found
  bool get hasProductInfo => product != null;
  
  /// Nutri-Score (A, B, C, D, E)
  String? get nutriScore => product?.nutriScore;
  
  /// NOVA group (1-4, food processing level)
  int? get novaGroup => product?.novaGroup;
  
  /// List of allergens
  List<String> get allergens => product?.allergens ?? [];
  
  /// Main product image URL
  String? get imageUrl => product?.imageUrl;
  
  /// Ingredients text
  String? get ingredients => product?.ingredients;
  
  const BarcodeResult({
    required this.text,
    required this.format,
    this.productName,
    this.productBrand,
    this.confidence,
    this.location,
    this.product,
  });
  
  /// Create a copy with updated fields
  BarcodeResult copyWith({
    String? text,
    String? format,
    String? productName,
    String? productBrand,
    double? confidence,
    Map<String, int>? location,
    OFFProduct? product,
  }) {
    return BarcodeResult(
      text: text ?? this.text,
      format: format ?? this.format,
      productName: productName ?? this.productName,
      productBrand: productBrand ?? this.productBrand,
      confidence: confidence ?? this.confidence,
      location: location ?? this.location,
      product: product ?? this.product,
    );
  }
  
  @override
  String toString() {
    if (hasProductInfo) {
      return 'BarcodeResult(text: $text, format: $format, product: ${productName ?? 'Unknown Product'})';
    }
    return 'BarcodeResult(text: $text, format: $format)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarcodeResult &&
        other.text == text &&
        other.format == format &&
        other.productName == productName &&
        other.productBrand == productBrand &&
        other.product == product;
  }
  
  @override
  int get hashCode => Object.hash(
        text.hashCode,
        format.hashCode,
        productName.hashCode,
        productBrand.hashCode,
        product.hashCode,
      );
} 