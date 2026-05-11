import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Platform-specific imports
import 'package:camera_macos/camera_macos.dart' if (dart.library.html) 'dart:html' as camera_macos;

/// Simple camera manager that mimics the working dart_barcode_old implementation
class SimpleCameraManager {
  CameraController? controller;
  bool _isDisposed = false;
  
  bool get isWindows => Platform.isWindows;
  bool get isInitialized => controller?.value.isInitialized ?? false;
  Size? get previewSize => controller?.value.previewSize;
  
  Future<CameraController?> initializeCamera() async {
    try {
      // Dispose previous controller if exists - enhanced for Windows
      if (controller != null) {
        await dispose();
        // Windows needs extra time for camera resource cleanup
        if (isWindows) {
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      _isDisposed = false;
      
      // Platform-specific camera initialization
      if (Platform.isMacOS) {
        // Use camera_macos for macOS
        return await _initializeMacOSCamera();
      } else {
        // Use standard camera package for other platforms
        return await _initializeStandardCamera();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      
      // If we get a "camera already exists" error on Windows, try disposing and retrying once
      if (isWindows && e.toString().contains('already exists')) {
        debugPrint('Windows: Camera "already exists" error detected, attempting cleanup and retry...');
        try {
          // Force complete disposal and cleanup
          if (controller != null) {
            await controller!.dispose();
            controller = null;
          }
          
          // Extended wait for Windows camera resource cleanup
          await Future.delayed(const Duration(milliseconds: 2000));
          
          return await _retryInitializeCamera();
        } catch (retryError) {
          debugPrint('Windows: Camera retry failed: $retryError');
          return null;
        }
      }
      
      return null;
    }
  }

  Future<CameraController?> _initializeStandardCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('No cameras available');
      return null;
    }

    // Platform-specific camera selection
    CameraDescription selectedCamera;
    if (isWindows) {
      selectedCamera = cameras.first;
      debugPrint('Windows: Using camera: ${selectedCamera.name}');
    } else {
      selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    }

    // Platform-specific resolution settings
    ResolutionPreset resolution;
    ImageFormatGroup? imageFormat;
    
    if (isWindows) {
      resolution = ResolutionPreset.high;
      imageFormat = ImageFormatGroup.bgra8888;
    } else {
      resolution = ResolutionPreset.high;
      imageFormat = Platform.isAndroid 
          ? ImageFormatGroup.yuv420 
          : ImageFormatGroup.bgra8888;
    }

    final newController = CameraController(
      selectedCamera,
      resolution,
      enableAudio: false,
      imageFormatGroup: imageFormat,
    );

    final timeout = isWindows ? const Duration(seconds: 15) : const Duration(seconds: 8);
    
    await newController.initialize().timeout(
      timeout,
      onTimeout: () {
        debugPrint('Camera initialization timed out (${timeout.inSeconds}s)');
        throw TimeoutException('Camera initialization timeout', timeout);
      },
    );
    
    if (!_isDisposed && newController.value.isInitialized) {
      try {
        await newController.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus mode setting failed (non-critical): $e');
      }
      
      controller = newController;
      debugPrint('Camera initialized successfully on ${Platform.operatingSystem}');
      debugPrint('Camera resolution: ${newController.value.previewSize}');
      return newController;
    } else {
      await newController.dispose();
      return null;
    }
  }

  Future<CameraController?> _initializeMacOSCamera() async {
    // For macOS, we need to use a different approach since camera_macos doesn't provide
    // the same API as the standard camera package. We'll need to implement a macOS-specific
    // camera controller or use the existing MacOSCameraManager from platform_camera_manager.dart
    
    debugPrint('macOS camera initialization - using platform-specific implementation');
    
    // For now, return null to indicate that macOS camera is not yet implemented
    // in this SimpleCameraManager. The BarcodeScannerWidget should use the
    // PlatformCameraManager.create() method instead.
    return null;
  }

  Future<CameraController?> _retryInitializeCamera() async {
    try {
      // Ensure complete disposal before retry
      if (controller != null) {
        debugPrint('Windows retry: Force disposing existing controller...');
        await dispose();
        // Extra wait for Windows camera resource cleanup
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      
      _isDisposed = false;
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available on retry');
        return null;
      }

      final selectedCamera = cameras.first;
      debugPrint('Windows retry: Using camera: ${selectedCamera.name}');

      final newController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await newController.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Camera retry initialization timeout');
        },
      );
      
      if (!_isDisposed && newController.value.isInitialized) {
        try {
          await newController.setFocusMode(FocusMode.auto);
        } catch (e) {
          debugPrint('Windows retry: Focus mode setting failed (non-critical): $e');
        }
        
        controller = newController;
        debugPrint('Windows: Camera retry successful');
        return newController;
      } else {
        await newController.dispose();
        return null;
      }
    } catch (e) {
      debugPrint('Windows: Camera retry failed: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    
    if (controller != null) {
      try {
        debugPrint('Starting camera disposal...');
        
        // Stop image stream first if it's running
        if (controller!.value.isStreamingImages) {
          debugPrint('Stopping image stream...');
          await controller!.stopImageStream();
          // Give time for stream to fully stop
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Dispose the controller
        debugPrint('Disposing camera controller...');
        await controller!.dispose();
        debugPrint('Camera controller disposed');
        
        // Windows needs extra cleanup time and process isolation
        if (isWindows) {
          await Future.delayed(const Duration(milliseconds: 800));
          // Force garbage collection to help with resource cleanup
          // This is critical for Windows camera resource management
          debugPrint('Windows: Waiting for camera resource cleanup...');
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      } finally {
        controller = null;
        debugPrint('Camera disposal complete');
      }
    }
  }

  // Add a force dispose method for hot reload scenarios
  Future<void> forceDispose() async {
    debugPrint('Force disposing camera for hot reload...');
    _isDisposed = true;
    
    if (controller != null) {
      try {
        // More aggressive disposal for hot reload
        if (controller!.value.isStreamingImages) {
          await controller!.stopImageStream();
        }
        await controller!.dispose();
        
        // Longer wait for Windows on hot reload
        if (isWindows) {
          await Future.delayed(const Duration(milliseconds: 1500));
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('Error in force dispose: $e');
      } finally {
        controller = null;
        debugPrint('Force disposal complete');
      }
    }
  }

  Future<Uint8List?> takePicture() async {
    try {
      if (controller == null || !controller!.value.isInitialized || _isDisposed) {
        return null;
      }

      final image = await controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      
      // Clean up temporary file
      try {
        await File(image.path).delete();
      } catch (e) {
        debugPrint('Failed to delete temp image: $e');
      }
      
      return bytes;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  Widget buildPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }
    
    // Use enhanced camera preview like the working project
    if (isWindows) {
      return _buildWindowsPreview();
    } else {
      return CameraPreview(controller!);
    }
  }

  Widget _buildWindowsPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final previewSize = controller!.value.previewSize!;
        
        // Calculate scaling to fill the screen while maintaining aspect ratio
        final screenRatio = size.width / size.height;
        final previewRatio = previewSize.width / previewSize.height;
        
        late final double scale;
        if (screenRatio > previewRatio) {
          // Screen is wider than preview, scale to fill height
          scale = size.height / previewSize.height;
        } else {
          // Screen is taller than preview, scale to fill width
          scale = size.width / previewSize.width;
        }

        return Container(
          width: size.width,
          height: size.height,
          color: Colors.black,
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  // Flip horizontally to correct mirror effect for Windows cameras
                  transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                  child: CameraPreview(controller!),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 