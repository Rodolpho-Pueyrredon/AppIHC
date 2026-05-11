import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'models/barcode_result.dart';
import 'models/image_format.dart';
import 'utils/model_manager.dart';

/// Main barcode detection class providing high-level API
class BarcodeDetector {
  static DynamicLibrary? _lib;
  static bool _initialized = false;

  // FFI function signatures
  static late final _ProcessImage _processImage;
  static late final _ProcessYuv420Image _processYuv420Image;
  static late final _SdkInit _sdkInit;
  static late final _FreeRustString _freeRustString;

  /// Initialize the barcode SDK with the model file path
  /// This must be called before any barcode processing functions
  /// Returns true on success, false on error
  static Future<bool> initialize(String modelFilePath) async {
    if (_initialized) return true;

    debugPrint('🔍 BarcodeDetector: Starting initialization with model: $modelFilePath');

    try {
      debugPrint('🔍 BarcodeDetector: Loading native library...');
      _lib = _loadNativeLibrary();
      debugPrint('✅ BarcodeDetector: Native library loaded successfully');
      
      debugPrint('🔍 BarcodeDetector: Binding FFI functions...');
      _bindFunctions();
      debugPrint('✅ BarcodeDetector: FFI functions bound successfully');
      
      debugPrint('🔍 BarcodeDetector: Checking if model file exists...');
      final modelFile = File(modelFilePath);
      if (!await modelFile.exists()) {
        debugPrint('❌ BarcodeDetector: Model file does not exist: $modelFilePath');
        return false;
      }
      debugPrint('✅ BarcodeDetector: Model file exists (${await modelFile.length()} bytes)');
      
      final pathPointer = modelFilePath.toNativeUtf8();
      try {
        debugPrint('🔍 BarcodeDetector: Calling Rust SDK init function...');
        final result = _sdkInit(pathPointer.cast<Char>());
        debugPrint('🔍 BarcodeDetector: Rust SDK init returned: $result');
        _initialized = result == 0; // 0 means success in C
        
        if (_initialized) {
          debugPrint('✅ BarcodeDetector: Initialization successful');
        } else {
          debugPrint('❌ BarcodeDetector: Rust SDK init failed (returned $result)');
        }
        
        return _initialized;
      } finally {
        malloc.free(pathPointer);
      }
    } catch (e) {
      debugPrint('❌ BarcodeDetector: Initialization failed with exception: $e');
      debugPrint('❌ BarcodeDetector: Exception type: ${e.runtimeType}');
      if (e is ArgumentError) {
        debugPrint('❌ BarcodeDetector: ArgumentError details: ${e.message}');
      }
      return false;
    }
  }

  /// Initialize the barcode SDK with automatic model download if needed
  /// If modelPath is null, uses default location in app documents
  /// Downloads model from Hugging Face if not found locally
  /// Throws exception if model not found and download fails
  static Future<void> initializeOrDownload([
    String? modelPath,
    void Function(double progress, String status)? onProgress,
  ]) async {
    if (_initialized) return;

    try {
      // Use provided path or default
      final finalModelPath = modelPath ?? await ModelManager.getDefaultModelPath();
      
      // Ensure model exists (download if needed)
      await ModelManager.ensureModel(finalModelPath, onProgress: onProgress);
      
      onProgress?.call(1.0, 'Initializing barcode SDK...');
      
      // Initialize SDK
      final success = await initialize(finalModelPath);
      if (!success) {
        throw Exception('Failed to initialize barcode SDK with model: $finalModelPath');
      }
      
    } catch (e) {
      throw Exception('Failed to initialize barcode detector: $e');
    }
  }

  /// Process an image and return detected barcodes
  static Future<List<BarcodeResult>> processImage({
    required ImageFormat format,
    required Uint8List bytes,
    int width = 0,
    int height = 0,
    int bytesPerRow = 0,
    bool useSuperResolution = true,
  }) async {
    if (!_initialized) {
      throw StateError('BarcodeDetector not initialized. Call initialize() first.');
    }

    // Allocate memory for the image bytes
    final pBytes = malloc.allocate<Uint8>(bytes.length);
    pBytes.asTypedList(bytes.length).setAll(0, bytes);

    Pointer<Char> resultPtr = nullptr;
    try {
      resultPtr = _processImage(
        format.index,
        pBytes,
        bytes.length,
        width,
        height,
        bytesPerRow,
        useSuperResolution,
      );
      
      if (resultPtr == nullptr) {
        throw Exception('Rust process_image function returned a null pointer.');
      }

      final jsonString = resultPtr.cast<Utf8>().toDartString();
      final result = jsonDecode(jsonString);

      if (result['error'] != null) {
        throw Exception('Error from Rust library: ${result['error']}');
      }

      final barcodesJson = result['barcodes'] as List;
      return barcodesJson
          .map((json) => BarcodeResult.fromJson(json))
          .toList();
    } finally {
      // Free the memory
      malloc.free(pBytes);
      if (resultPtr != nullptr) {
        _freeRustString(resultPtr);
      }
    }
  }

  /// Process YUV420 image data directly
  /// This is more efficient than converting to JPEG first
  static Future<List<BarcodeResult>> processYuv420Image({
    required Uint8List yPlane,
    required Uint8List uPlane,
    required Uint8List vPlane,
    required int width,
    required int height,
    required int uvRowStride,
    required int uvPixelStride,
    bool useSuperResolution = true,
  }) async {
    if (!_initialized) {
      throw StateError('BarcodeDetector not initialized. Call initialize() first.');
    }

    // Allocate memory for the YUV planes
    final pYPlane = malloc.allocate<Uint8>(yPlane.length);
    final pUPlane = malloc.allocate<Uint8>(uPlane.length);
    final pVPlane = malloc.allocate<Uint8>(vPlane.length);
    
    pYPlane.asTypedList(yPlane.length).setAll(0, yPlane);
    pUPlane.asTypedList(uPlane.length).setAll(0, uPlane);
    pVPlane.asTypedList(vPlane.length).setAll(0, vPlane);

    Pointer<Char> resultPtr = nullptr;
    try {
      resultPtr = _processYuv420Image(
        pYPlane,
        yPlane.length,
        pUPlane,
        uPlane.length,
        pVPlane,
        vPlane.length,
        width,
        height,
        uvRowStride,
        uvPixelStride,
        useSuperResolution,
      );
      
      if (resultPtr == nullptr) {
        throw Exception('Rust process_yuv420_image function returned a null pointer.');
      }

      final jsonString = resultPtr.cast<Utf8>().toDartString();
      final result = jsonDecode(jsonString);

      if (result['error'] != null) {
        throw Exception('Error from Rust library: ${result['error']}');
      }

      final barcodesJson = result['barcodes'] as List;
      return barcodesJson
          .map((json) => BarcodeResult.fromJson(json))
          .toList();
    } finally {
      // Free the memory
      malloc.free(pYPlane);
      malloc.free(pUPlane);
      malloc.free(pVPlane);
      if (resultPtr != nullptr) {
        _freeRustString(resultPtr);
      }
    }
  }

  /// Check if the SDK is initialized
  static bool get isInitialized => _initialized;

  // Private helper methods
  static String _libraryPath() {
    if (Platform.isWindows) {
      return 'rust_barcode_lib.dll';
    } else if (Platform.isAndroid) {
      return 'librust_barcode_lib.so';
    } else if (Platform.isLinux) {
      return 'librust_barcode_lib.so';
    } else if (Platform.isMacOS || Platform.isIOS) {
      return 'librust_barcode_lib.dylib';
    } else {
      throw UnsupportedError('Unsupported platform for FFI library.');
    }
  }

  static DynamicLibrary _loadNativeLibrary() {
    final libName = _libraryPath();
    debugPrint('🔍 BarcodeDetector: Loading library: $libName');
    
    // For desktop platforms, check development path first
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final devPath = '../rust-barcode-lib/target/release/$libName';
      debugPrint('🔍 BarcodeDetector: Checking development path: $devPath');
      if (File(devPath).existsSync()) {
        debugPrint('✅ BarcodeDetector: Found library at development path');
        return DynamicLibrary.open(devPath);
      }
      debugPrint('⚠️ BarcodeDetector: Library not found at development path');
    }
    
    // For macOS, try to load from the app bundle's Frameworks directory
    if (Platform.isMacOS) {
      try {
        // Try to load from the app bundle's Frameworks directory
        final frameworksPath = 'Frameworks/$libName';
        debugPrint('🔍 BarcodeDetector: Trying macOS Frameworks path: $frameworksPath');
        final library = DynamicLibrary.open(frameworksPath);
        debugPrint('✅ BarcodeDetector: Library loaded successfully from Frameworks');
        return library;
      } catch (e) {
        debugPrint('⚠️ BarcodeDetector: Failed to load from Frameworks: $e');
      }
    }
    
    debugPrint('🔍 BarcodeDetector: Loading library from system path: $libName');
    try {
      final library = DynamicLibrary.open(libName);
      debugPrint('✅ BarcodeDetector: Library loaded successfully from system path');
      return library;
    } catch (e) {
      debugPrint('❌ BarcodeDetector: Failed to load library: $e');
      rethrow;
    }
  }

  static void _bindFunctions() {
    debugPrint('🔍 BarcodeDetector: Binding FFI functions...');
    
    try {
      _processImage = _lib!.lookupFunction<_ProcessImageNative, _ProcessImage>('process_image');
      debugPrint('✅ BarcodeDetector: process_image function bound');
      
      _processYuv420Image = _lib!.lookupFunction<_ProcessYuv420ImageNative, _ProcessYuv420Image>('process_yuv420_image');
      debugPrint('✅ BarcodeDetector: process_yuv420_image function bound');
      
      _sdkInit = _lib!.lookupFunction<_SdkInitNative, _SdkInit>('sdk_init');
      debugPrint('✅ BarcodeDetector: sdk_init function bound');
      
      _freeRustString = _lib!.lookupFunction<_FreeRustStringNative, _FreeRustString>('free_rust_string');
      debugPrint('✅ BarcodeDetector: free_rust_string function bound');
      
      debugPrint('✅ BarcodeDetector: All FFI functions bound successfully');
    } catch (e) {
      debugPrint('❌ BarcodeDetector: Failed to bind FFI functions: $e');
      rethrow;
    }
  }
}

// FFI type definitions
typedef _ProcessImageNative = Pointer<Char> Function(
  Int32 imageFormat,
  Pointer<Uint8> data,
  IntPtr len,
  Uint32 width,
  Uint32 height,
  Uint32 bytesPerRow,
  Bool useSuperResolution,
);

typedef _ProcessImage = Pointer<Char> Function(
  int imageFormat,
  Pointer<Uint8> data,
  int len,
  int width,
  int height,
  int bytesPerRow,
  bool useSuperResolution,
);

typedef _ProcessYuv420ImageNative = Pointer<Char> Function(
  Pointer<Uint8> yData,
  IntPtr yLen,
  Pointer<Uint8> uData,
  IntPtr uLen,
  Pointer<Uint8> vData,
  IntPtr vLen,
  Uint32 width,
  Uint32 height,
  Uint32 uvRowStride,
  Uint32 uvPixelStride,
  Bool useSuperResolution,
);

typedef _ProcessYuv420Image = Pointer<Char> Function(
  Pointer<Uint8> yData,
  int yLen,
  Pointer<Uint8> uData,
  int uLen,
  Pointer<Uint8> vData,
  int vLen,
  int width,
  int height,
  int uvRowStride,
  int uvPixelStride,
  bool useSuperResolution,
);

typedef _SdkInitNative = Int32 Function(Pointer<Char> modelPath);
typedef _SdkInit = int Function(Pointer<Char> modelPath);

typedef _FreeRustStringNative = Void Function(Pointer<Char> ptr);
typedef _FreeRustString = void Function(Pointer<Char> ptr);
