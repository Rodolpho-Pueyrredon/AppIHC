import 'dart:typed_data';
import 'detection_bounds.dart';

/// Represents a detected barcode with its text, format and location
class BarcodeResult {
  /// The decoded barcode text
  final String text;
  
  /// The barcode format (e.g., "EAN_13", "CODE_128", etc.)
  final String format;
  
  /// Bounding box and confidence of the detection
  final DetectionBounds? bounds;
  
  /// Optional processed image data
  final Uint8List? imageData;
  
  /// Width of the processed image
  final int? imageWidth;
  
  /// Height of the processed image
  final int? imageHeight;

  BarcodeResult({
    required this.text,
    required this.format,
    this.bounds,
    this.imageData,
    this.imageWidth,
    this.imageHeight,
  });

  /// Create from JSON data returned by the FFI layer
  factory BarcodeResult.fromJson(Map<String, dynamic> json) {
    return BarcodeResult(
      text: json['text'] as String,
      format: json['format'] as String,
      bounds: json['detection'] != null
          ? DetectionBounds.fromJson(json['detection'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create a copy with optional overrides
  BarcodeResult copyWith({
    String? text,
    String? format,
    DetectionBounds? bounds,
    Uint8List? imageData,
    int? imageWidth,
    int? imageHeight,
  }) {
    return BarcodeResult(
      text: text ?? this.text,
      format: format ?? this.format,
      bounds: bounds ?? this.bounds,
      imageData: imageData ?? this.imageData,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'format': format,
      if (bounds != null) 'detection': bounds!.toJson(),
      if (imageWidth != null) 'imageWidth': imageWidth,
      if (imageHeight != null) 'imageHeight': imageHeight,
    };
  }

  @override
  String toString() {
    return 'BarcodeResult(text: "$text", format: "$format", bounds: $bounds)';
  }
}
