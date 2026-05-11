/// Represents the bounding box of a detected barcode
class DetectionBounds {
  /// Left coordinate
  final int left;
  
  /// Top coordinate
  final int top;
  
  /// Right coordinate
  final int right;
  
  /// Bottom coordinate
  final int bottom;
  
  /// Detection confidence (0.0 to 1.0)
  final double confidence;

  DetectionBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  /// Width of the bounding box
  int get width => right - left;

  /// Height of the bounding box
  int get height => bottom - top;

  /// Create from JSON data
  factory DetectionBounds.fromJson(Map<String, dynamic> json) {
    return DetectionBounds(
      left: json['left'] as int,
      top: json['top'] as int,
      right: json['right'] as int,
      bottom: json['bottom'] as int,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'DetectionBounds(left: $left, top: $top, right: $right, bottom: $bottom, confidence: ${confidence.toStringAsFixed(3)})';
  }
}
