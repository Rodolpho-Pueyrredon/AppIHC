import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utility class for image processing and conversion
class ImageUtils {
  /// Convert image data to RGBA format suitable for processing
  static ({Uint8List bytes, int width, int height})? convertToRgba(Uint8List imageData) {
    if (imageData.isEmpty) return null;

    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // Convert to RGBA format
      final rgbaImage = _convertToRgb(image);
      final rgbaBytes = Uint8List.fromList(rgbaImage.getBytes(order: img.ChannelOrder.rgba));
      
      return (
        bytes: rgbaBytes,
        width: rgbaImage.width,
        height: rgbaImage.height
      );
    } catch (e) {
      throw Exception('Failed to convert image to RGBA format: $e');
    }
  }

  /// Convert image to RGB format (ensure 3 channels)
  static img.Image _convertToRgb(img.Image image) {
    if (image.numChannels == 3) {
      return image; // Already RGB
    }
    
    // Convert to RGB using the proper image package API
    return img.copyResize(image, width: image.width, height: image.height);
  }

  /// Get image dimensions from bytes
  static (int, int)? getImageDimensions(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      return (image.width, image.height);
    } catch (e) {
      return null;
    }
  }

  /// Prepare image for YOLO processing (resize to square, convert to RGB)
  static ({Uint8List bytes, int width, int height})? prepareForYolo(
    Uint8List imageBytes, {
    int yoloInputSize = 640,
  }) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize to square maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: yoloInputSize,
        height: yoloInputSize,
        interpolation: img.Interpolation.linear,
      );

      // Convert to RGB
      final rgbImage = _convertToRgb(resized);
      final rgbBytes = Uint8List.fromList(rgbImage.getBytes(order: img.ChannelOrder.rgb));
      
      return (
        bytes: rgbBytes,
        width: rgbImage.width,
        height: rgbImage.height,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert YUV420 to RGB
  /// This is a simplified conversion - production code should use optimized libraries
  static Uint8List yuv420ToRgb(
    Uint8List yPlane,
    Uint8List uPlane,
    Uint8List vPlane,
    int width,
    int height,
  ) {
    final rgb = Uint8List(width * height * 3);
    int rgbIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        if (yIndex >= yPlane.length || uvIndex >= uPlane.length || uvIndex >= vPlane.length) {
          continue;
        }

        final yValue = yPlane[yIndex];
        final uValue = uPlane[uvIndex];
        final vValue = vPlane[uvIndex];

        // YUV to RGB conversion
        final c = yValue - 16;
        final d = uValue - 128;
        final e = vValue - 128;

        final r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
        final g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
        final b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);

        rgb[rgbIndex++] = r;
        rgb[rgbIndex++] = g;
        rgb[rgbIndex++] = b;
      }
    }

    return rgb;
  }
}

/// Simple class to hold image data with metadata
class ImageData {
  final Uint8List bytes;
  final int width;
  final int height;

  ImageData(this.bytes, this.width, this.height);
}
