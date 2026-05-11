import 'package:flutter/material.dart';

/// Configuration for the barcode scanner
class ScannerConfig {
  /// Path to the YOLO model file (best.rten)
  /// If null, uses default location in app documents with auto-download
  /// If specified, must be a valid file path (will auto-download if missing)
  final String? modelPath;
  
  /// Whether to use super resolution for better 1D barcode reading
  /// Improves accuracy for damaged or low-quality barcodes
  final bool useSuperResolution;
  
  /// Whether to enable product lookup (OpenFoodFacts integration)
  /// Requires internet connection for product information
  final bool enableProductLookup;
  
  /// Whether to show the scanning overlay rectangle
  final bool showOverlay;
  
  /// Whether to show the status overlay with scanning information
  final bool showStatusOverlay;
  
  /// Custom overlay color (default: green)
  final Color overlayColor;
  
  /// Scanning interval in seconds (default: 1 second)
  /// Lower values = faster scanning but more CPU usage
  final Duration scanInterval;
  
  /// Timeout for scanning operations
  final Duration timeout;
  
  /// Whether to enable image enhancement
  final bool enableImageEnhancement;
  
  /// Whether to enable preprocessing
  final bool enablePreprocessing;
  
  /// Whether to enable debug mode
  final bool debugMode;
  
  /// Whether to stop scanning after first successful detection
  /// Perfect for point-of-sale single scan use cases
  final bool scanOnce;
  
  /// Whether to play haptic feedback on successful scan
  final bool enableHapticFeedback;
  
  /// Whether to enable continuous auto-focus for better barcode detection
  /// Recommended for varying distances and lighting conditions
  final bool enableContinuousAutoFocus;

  const ScannerConfig({
    this.modelPath,
    this.useSuperResolution = true,
    this.enableProductLookup = true,
    this.showOverlay = true,
    this.showStatusOverlay = true,
    this.overlayColor = Colors.green,
    this.scanInterval = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 15),
    this.enableImageEnhancement = true,
    this.enablePreprocessing = true,
    this.debugMode = false,
    this.scanOnce = false,
    this.enableHapticFeedback = true,
    this.enableContinuousAutoFocus = true,
  });
  
  /// Continuous scanning mode - allows multiple scans, same product can be scanned multiple times
  const ScannerConfig.continuous({
    this.modelPath,
    this.useSuperResolution = true,
    this.enableProductLookup = true,
    this.showOverlay = true,
    this.showStatusOverlay = true,
    this.overlayColor = Colors.blue,
    this.scanInterval = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 15),
    this.enableImageEnhancement = true,
    this.enablePreprocessing = true,
    this.debugMode = false,
    this.scanOnce = false,
    this.enableHapticFeedback = true,
    this.enableContinuousAutoFocus = true,
  });
  
  /// Point-of-sale mode - optimized for quick single scans with immediate feedback
  const ScannerConfig.pointOfSale({
    this.modelPath,
    this.useSuperResolution = true,
    this.enableProductLookup = true, // Keep enabled for product info display
    this.showOverlay = true,
    this.showStatusOverlay = false, // Hide status overlay for cleaner POS experience
    this.overlayColor = Colors.green,
    this.scanInterval = const Duration(milliseconds: 500), // Faster scanning
    this.timeout = const Duration(seconds: 10),
    this.enableImageEnhancement = true,
    this.enablePreprocessing = true,
    this.debugMode = false,
    this.scanOnce = true, // Stop after first scan
    this.enableHapticFeedback = true,
    this.enableContinuousAutoFocus = true,
  });

  /// Create a copy of this config with some fields replaced
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
  
  // Keep static constants for backward compatibility
  static const ScannerConfig continuousMode = ScannerConfig.continuous();
  static const ScannerConfig pointOfSaleMode = ScannerConfig.pointOfSale();
}

/// Camera resolution presets for different use cases
enum CameraResolutionPreset {
  /// Low resolution - fastest processing, lowest accuracy
  low,
  /// Medium resolution - balanced performance
  medium,
  /// High resolution - good accuracy, moderate speed
  high,
  /// Very high resolution - best accuracy, slowest processing
  veryHigh,
} 