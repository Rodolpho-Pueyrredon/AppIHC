import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Windows/Linux camera support
import 'package:camera/camera.dart' as camera;

// macOS camera support
import 'package:camera_macos/camera_macos.dart';

import 'scanner_config.dart';

/// Abstract interface for platform-specific camera operations
abstract class PlatformCameraManager {
  /// Initialize the camera with the given configuration
  Future<void> initialize(ScannerConfig config);

  /// Dispose of camera resources
  Future<void> dispose();

  /// Take a picture and return the image bytes
  Future<Uint8List> takePicture();

  /// Get the camera preview widget
  Widget buildPreviewWidget();

  /// Check if the camera is initialized
  bool get isInitialized;

  /// Get the camera preview size
  Size? get previewSize;

  /// Factory method to create the appropriate camera manager for the current platform
  static PlatformCameraManager create() {
    if (Platform.isMacOS) {
      return MacOSCameraManager();
    } else {
      return WindowsCameraManager();
    }
  }
}

/// Windows/Linux camera implementation using the standard camera package
class WindowsCameraManager extends PlatformCameraManager {
  camera.CameraController? _controller;

  @override
  Future<void> initialize(ScannerConfig config) async {
    await dispose();

    final cameras = await camera.availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    _controller = camera.CameraController(
      cameras.first,
      camera.ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: camera.ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize().timeout(
        config.timeout,
        onTimeout: () async {
          await dispose();
          throw Exception(
            'Camera initialization timed out (${config.timeout.inSeconds}s)',
          );
        },
      );
    } catch (_) {
      await dispose();
      rethrow;
    }

    // Set focus mode
    try {
      if (config.enableContinuousAutoFocus) {
        await _controller!.setFocusMode(camera.FocusMode.auto);
        debugPrint('✅ Windows: Continuous auto-focus enabled');
      } else {
        await _controller!.setFocusMode(camera.FocusMode.locked);
        debugPrint('✅ Windows: Focus locked for performance');
      }
    } catch (e) {
      debugPrint('Windows focus mode setting failed (non-critical): $e');
    }

    debugPrint('✅ Windows camera initialized successfully');
    debugPrint(
        '📷 Windows camera resolution: ${_controller!.value.previewSize}');
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  @override
  Future<Uint8List> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    final image = await _controller!.takePicture();
    final bytes = await File(image.path).readAsBytes();

    // Clean up temporary file
    try {
      await File(image.path).delete();
    } catch (e) {
      debugPrint('Failed to delete temp image: $e');
    }

    return bytes;
  }

  @override
  Widget buildPreviewWidget() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return camera.CameraPreview(_controller!);
  }

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  Size? get previewSize => _controller?.value.previewSize;
}

/// macOS camera implementation using camera_macos package
class MacOSCameraManager extends PlatformCameraManager {
  CameraMacOSController? _controller;
  final GlobalKey _cameraKey = GlobalKey();
  bool _isInitialized = false;

  @override
  Future<void> initialize(ScannerConfig config) async {
    debugPrint('🔍 MacOSCameraManager: Starting initialization...');

    try {
      // Note: macOS camera initialization is handled in the widget
      // This is due to the architecture of camera_macos package
      debugPrint('✅ MacOSCameraManager: Ready for widget-based initialization');

      // For now, we'll simulate successful initialization
      // The actual camera will be initialized when the widget is built
      _isInitialized = true;
      debugPrint('✅ MacOSCameraManager: Initialization completed (simulated)');
    } catch (e) {
      debugPrint('❌ MacOSCameraManager: Initialization failed: $e');
      rethrow;
    }
  }

  void _onCameraInitialized(CameraMacOSController controller) {
    debugPrint('🔍 MacOSCameraManager: Camera controller initialized');
    _controller = controller;
    _isInitialized = true;

    // Set focus point to center for better barcode detection
    try {
      _controller!.setFocusPoint(const Offset(0.5, 0.5));
      debugPrint('✅ macOS: Focus point set to center');
    } catch (e) {
      debugPrint('⚠️ macOS focus point setting failed (non-critical): $e');
    }

    debugPrint('✅ macOS camera initialized successfully');
  }

  @override
  Future<void> dispose() async {
    debugPrint('🔍 MacOSCameraManager: Disposing...');
    _controller = null;
    _isInitialized = false;
    debugPrint('✅ MacOSCameraManager: Disposed');
  }

  @override
  Future<Uint8List> takePicture() async {
    debugPrint('🔍 MacOSCameraManager: Taking picture...');

    if (_controller == null || !_isInitialized) {
      debugPrint('❌ MacOSCameraManager: Camera not initialized for picture');
      throw Exception('macOS camera not initialized');
    }

    try {
      final file = await _controller!.takePicture();
      if (file?.bytes == null) {
        debugPrint('❌ MacOSCameraManager: Failed to capture image');
        throw Exception('Failed to capture image on macOS');
      }

      debugPrint(
          '✅ MacOSCameraManager: Picture taken successfully (${file!.bytes!.length} bytes)');
      return file!.bytes!;
    } catch (e) {
      debugPrint('❌ MacOSCameraManager: Picture taking failed: $e');
      rethrow;
    }
  }

  @override
  Widget buildPreviewWidget() {
    debugPrint('🔍 MacOSCameraManager: Building preview widget...');

    if (!_isInitialized) {
      debugPrint(
          '⚠️ MacOSCameraManager: Not initialized, showing loading widget');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing macOS camera...'),
          ],
        ),
      );
    }

    debugPrint('✅ MacOSCameraManager: Building camera preview widget');

    // For macOS, we need to use the camera_macos widget
    return CameraMacOSView(
      key: _cameraKey,
      cameraMode: CameraMacOSMode.photo,
      onCameraInizialized: _onCameraInitialized,
      onCameraLoading: (error) {
        debugPrint('🔍 MacOSCameraManager: Camera loading: $error');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading macOS camera...'),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Size? get previewSize {
    if (_controller != null) {
      // Return a default size for macOS
      return const Size(640, 480);
    }
    return null;
  }
}
