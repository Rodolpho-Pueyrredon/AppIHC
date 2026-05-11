/// Supported image formats for barcode detection
enum ImageFormat {
  /// PNG format
  png,
  
  /// YUV format (generic)
  yuv,
  
  /// BGRA8888 format (32-bit with alpha)
  bgra8888,
  
  /// JPEG format
  jpeg,
  
  /// YUV420 format (widely used in cameras)
  yuv420,
}

/// Extensions for ImageFormat
extension ImageFormatExtension on ImageFormat {
  /// Get the integer index for FFI calls
  int get index {
    switch (this) {
      case ImageFormat.png:
        return 0;
      case ImageFormat.yuv:
        return 1;
      case ImageFormat.bgra8888:
        return 2;
      case ImageFormat.jpeg:
        return 3;
      case ImageFormat.yuv420:
        return 4;
    }
  }
}
