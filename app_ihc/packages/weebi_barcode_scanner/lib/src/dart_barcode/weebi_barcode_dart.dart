/// Core barcode detection library using embedded YOLO neural network.
/// 
/// This library provides low-level FFI interface to Rust-based barcode detection
/// with support for multiple image formats and high accuracy detection.
/// 
/// Features:
/// - YOLO-based barcode detection
/// - Multiple image format support (PNG, JPEG, YUV420, BGRA8888)
/// - Super-resolution enhancement
/// - Cross-platform support (Windows, macOS, Linux, Android, iOS)
/// 
/// Example usage:
/// ```dart
/// import 'package:weebi_barcode_dart/weebi_barcode_dart.dart';
/// 
/// // Initialize the SDK
/// await BarcodeDetector.initialize('path/to/model.rten');
/// 
/// // Process an image
/// final results = await BarcodeDetector.processImage(
///   format: ImageFormat.png,
///   bytes: imageBytes,
/// );
/// 
/// for (final result in results) {
///   print('Found ${result.format}: ${result.text}');
/// }
/// ```
library weebi_barcode_dart;

export 'src/barcode_detector.dart';
export 'src/models/barcode_result.dart';
export 'src/models/image_format.dart';
export 'src/models/detection_bounds.dart';
export 'src/utils/image_utils.dart';
export 'src/utils/model_manager.dart';
