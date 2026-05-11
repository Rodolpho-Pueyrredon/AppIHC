import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart_barcode/weebi_barcode_dart.dart' as core;

import 'barcode_result.dart';
import 'barcode_scanner_widget.dart';
import 'scanner_config.dart';

/// Simple barcode scanner API with automatic model management
/// 
/// This class provides the easiest way to integrate barcode scanning:
/// - Automatically downloads the YOLO model from Hugging Face if needed
/// - Handles all initialization and error management
/// - Provides a simple Widget for scanning
/// 
/// Example usage:
/// ```dart
/// // Basic usage with default settings
/// SimpleBarcodeScanner(
///   onBarcodeDetected: (barcode) {
///     print('Scanned: ${barcode.text}');
///   },
/// )
/// 
/// // With custom model path
/// SimpleBarcodeScanner(
///   modelPath: '/custom/path/to/model.rten',
///   onBarcodeDetected: (barcode) {
///     print('Scanned: ${barcode.text}');
///   },
/// )
/// ```
class SimpleBarcodeScanner extends StatelessWidget {
  /// Callback when a barcode is detected
  final Function(BarcodeResult) onBarcodeDetected;
  
  /// Optional custom model path
  /// If null, uses default location with auto-download
  final String? modelPath;
  
  /// Scanner configuration
  final ScannerConfig? config;
  
  /// Error callback
  final Function(String)? onError;
  
  /// Loading widget while initializing
  final Widget? loadingWidget;

  const SimpleBarcodeScanner({
    super.key,
    required this.onBarcodeDetected,
    this.modelPath,
    this.config,
    this.onError,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Create config with custom model path if provided
    final finalConfig = config?.copyWith(modelPath: modelPath) ?? 
                       ScannerConfig(modelPath: modelPath);
    
    return BarcodeScannerWidget(
      onBarcodeDetected: onBarcodeDetected,
      config: finalConfig,
      onError: onError,
      loadingWidget: loadingWidget,
    );
  }
}
extension ScannerConfigExtension on ScannerConfig {
  ScannerConfig copyWith({
    String? modelPath,
    bool? useSuperResolution,
    bool? enableProductLookup,
    bool? showOverlay,
    bool? showStatusOverlay,
    Color? overlayColor,
    Duration? scanInterval,
    Duration? timeout,
    bool? enableImageEnhancement,
    bool? enablePreprocessing,
    bool? debugMode,
    bool? scanOnce,
    bool? enableHapticFeedback,
    bool? enableContinuousAutoFocus,
  }) {
    return ScannerConfig(
      modelPath: modelPath ?? this.modelPath,
      useSuperResolution: useSuperResolution ?? this.useSuperResolution,
      enableProductLookup: enableProductLookup ?? this.enableProductLookup,
      showOverlay: showOverlay ?? this.showOverlay,
      showStatusOverlay: showStatusOverlay ?? this.showStatusOverlay,
      overlayColor: overlayColor ?? this.overlayColor,
      scanInterval: scanInterval ?? this.scanInterval,
      timeout: timeout ?? this.timeout,
      enableImageEnhancement: enableImageEnhancement ?? this.enableImageEnhancement,
      enablePreprocessing: enablePreprocessing ?? this.enablePreprocessing,
      debugMode: debugMode ?? this.debugMode,
      scanOnce: scanOnce ?? this.scanOnce,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableContinuousAutoFocus: enableContinuousAutoFocus ?? this.enableContinuousAutoFocus,
    );
  }
}

/// Static methods for advanced usage
class BarcodeScanner {
  /// Initialize the barcode detector with automatic model download
  /// 
  /// This method automatically downloads the YOLO model from Hugging Face
  /// if it's not found locally. By default, it stores the model in the
  /// app's documents directory.
  /// 
  /// Parameters:
  /// - [modelPath]: Custom path for the model file. If null, uses default location.
  /// - [onProgress]: Optional callback to track download progress (0.0 to 1.0)
  /// 
  /// Throws:
  /// - [Exception] if model download fails or initialization fails
  /// 
  /// Example:
  /// ```dart
  /// // Use default location
  /// await BarcodeScanner.initialize();
  /// 
  /// // Use custom path with progress tracking
  /// await BarcodeScanner.initialize(
  ///   '/custom/path/to/model.rten',
  ///   (progress, status) => print('$status: ${(progress * 100).toInt()}%'),
  /// );
  /// ```
  static Future<void> initialize([
    String? modelPath,
    void Function(double progress, String status)? onProgress,
  ]) async {
    await core.BarcodeDetector.initializeOrDownload(modelPath, onProgress);
  }
  
  /// Check if the scanner is initialized
  static bool get isInitialized => core.BarcodeDetector.isInitialized;
  
  /// Get the default model path
  static Future<String> getDefaultModelPath() async {
    return await core.ModelManager.getDefaultModelPath();
  }
  
  /// Check if model exists at path
  static bool modelExists(String path) {
    return core.ModelManager.modelExists(path);
  }
  
  /// Download model to specific path with progress tracking
  static Future<void> downloadModel(
    String path, {
    void Function(double progress, String status)? onProgress,
  }) async {
    await core.ModelManager.downloadModel(path, onProgress: onProgress);
  }
}

/// Simple barcode scanner API similar to barcode_scan2
/// 
/// Provides a clean, one-line API to scan barcodes:
/// ```dart
/// var result = await WeebiBarcodeScanner.scan();
/// ```
class WeebiBarcodeScanner {
  /// Scan a single barcode using the camera
  /// 
  /// Opens a full-screen scanning interface and returns when a barcode
  /// is detected or the user cancels.
  /// 
  /// Returns a [WeebiBarcodeResult] containing the scanned data or error information.
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await WeebiBarcodeScanner.scan(
  ///     title: 'Scan Product Barcode',
  ///     subtitle: 'Point your camera at a barcode to scan it',
  ///   );
  ///   if (result.isSuccess) {
  ///     print('Scanned: ${result.code}');
  ///   } else if (result.isCancelled) {
  ///     print('User cancelled');
  ///   } else {
  ///     print('Error: ${result.error}');
  ///   }
  /// } catch (e) {
  ///   print('Error: $e');
  /// }
  /// ```
  static Future<WeebiBarcodeResult> scan({
    ScannerConfig? config,
    String? title,
    String? subtitle,
    bool showFlashToggle = true,
    bool showGalleryButton = false,
  }) async {
    try {
      // Get current context automatically
      final navigatorContext = _getCurrentContext();
      if (navigatorContext == null) {
        return WeebiBarcodeResult.error('No valid context found. Ensure you have a MaterialApp in your widget tree and call scan() from within a widget.');
      }

      // Use default config if none provided
      final scannerConfig = config ?? ScannerConfig();

      // Navigate to full-screen scanner
      final result = await Navigator.of(navigatorContext).push<WeebiBarcodeResult>(
        MaterialPageRoute(
          builder: (context) => _SimpleScannerScreen(
            config: scannerConfig,
            title: title ?? 'Scan Barcode',
            subtitle: subtitle,
            showFlashToggle: showFlashToggle,
            showGalleryButton: showGalleryButton,
          ),
          fullscreenDialog: true,
        ),
      );

      return result ?? WeebiBarcodeResult.cancelled();
      
    } catch (e) {
      return WeebiBarcodeResult.error('Failed to start scanner: $e');
    }
  }

  /// Get the current navigator context (best effort)
  static BuildContext? _getCurrentContext() {
    try {
      // Try to get the root context and find Navigator
      final rootElement = WidgetsBinding.instance.rootElement;
      if (rootElement != null) {
        // Try to find a context that has a Navigator
        BuildContext? navigatorContext;
        
        void visitor(Element element) {
          if (navigatorContext != null) return;
          
          // Check if this element has Navigator in its widget tree
          try {
            Navigator.of(element, rootNavigator: false);
            navigatorContext = element;
            return;
          } catch (e) {
            // This element doesn't have Navigator, continue searching
          }
          
          // Visit children
          element.visitChildren(visitor);
        }
        
        visitor(rootElement);
        return navigatorContext;
      }
    } catch (e) {
      // Fallback failed
    }
    return null;
  }
}

/// Simple result class similar to barcode_scan2's ScanResult
class WeebiBarcodeResult {
  final String? code;
  final String? format;
  final String? error;
  final bool cancelled;

  const WeebiBarcodeResult._({
    this.code,
    this.format,
    this.error,
    this.cancelled = false,
  });

  /// Create a successful scan result
  factory WeebiBarcodeResult.success(String code, String format) {
    return WeebiBarcodeResult._(code: code, format: format);
  }

  /// Create a cancelled result
  factory WeebiBarcodeResult.cancelled() {
    return const WeebiBarcodeResult._(cancelled: true);
  }

  /// Create an error result
  factory WeebiBarcodeResult.error(String error) {
    return WeebiBarcodeResult._(error: error);
  }

  /// Check if the scan was successful
  bool get isSuccess => code != null && error == null && !cancelled;

  /// Check if the scan was cancelled
  bool get isCancelled => cancelled;

  /// Check if there was an error
  bool get hasError => error != null;

  @override
  String toString() {
    if (isSuccess) return 'WeebiBarcodeResult.success(code: $code, format: $format)';
    if (isCancelled) return 'WeebiBarcodeResult.cancelled()';
    if (hasError) return 'WeebiBarcodeResult.error($error)';
    return 'WeebiBarcodeResult.unknown()';
  }
}

/// Simple full-screen scanner screen
class _SimpleScannerScreen extends StatefulWidget {
  final ScannerConfig config;
  final String title;
  final String? subtitle;
  final bool showFlashToggle;
  final bool showGalleryButton;

  const _SimpleScannerScreen({
    required this.config,
    required this.title,
    this.subtitle,
    this.showFlashToggle = true,
    this.showGalleryButton = false,
  });

  @override
  State<_SimpleScannerScreen> createState() => _SimpleScannerScreenState();
}

class _SimpleScannerScreenState extends State<_SimpleScannerScreen> {
  bool _flashEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(WeebiBarcodeResult.cancelled()),
        ),
        actions: [
          if (widget.showFlashToggle)
            IconButton(
              icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
              onPressed: () {
                setState(() {
                  _flashEnabled = !_flashEnabled;
                });
                // TODO: Implement flash toggle
                HapticFeedback.lightImpact();
              },
            ),
          if (widget.showGalleryButton)
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: () {
                // TODO: Implement gallery picker
                HapticFeedback.lightImpact();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera/Scanner view
          BarcodeScannerWidget(
            config: widget.config,
            onBarcodeDetected: (barcode) {
                             // Return the first successful scan
               HapticFeedback.mediumImpact();
               Navigator.of(context).pop(
                 WeebiBarcodeResult.success(barcode.text, barcode.format),
               );
            },
          ),
          
          // Overlay with scanning area
          _buildScanningOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          // Center crosshair for YOLO-based detection
          Center(
            child: CustomPaint(
              size: const Size(60, 60),
              painter: _CrosshairPainter(),
            ),
          ),
          
          // Pulsing animation around the crosshair
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                // Restart the animation
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom painter for drawing a crosshair at the center of the screen
/// Designed for YOLO-based barcode detection where the entire frame is analyzed
class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double crosshairLength = 20.0;
    final double gapSize = 6.0;

    // Draw horizontal lines (left and right of center)
    canvas.drawLine(
      Offset(centerX - crosshairLength - gapSize, centerY),
      Offset(centerX - gapSize, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + gapSize, centerY),
      Offset(centerX + crosshairLength + gapSize, centerY),
      paint,
    );

    // Draw vertical lines (top and bottom of center)
    canvas.drawLine(
      Offset(centerX, centerY - crosshairLength - gapSize),
      Offset(centerX, centerY - gapSize),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + gapSize),
      Offset(centerX, centerY + crosshairLength + gapSize),
      paint,
    );

    // Draw center dot
    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      2.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 