class Product {
  const Product({
    required this.barcode,
    this.workId,
    this.name,
    this.brand,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  final String barcode;
  final String? workId;
  final String? name;
  final String? brand;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product copyWith({
    String? barcode,
    String? workId,
    String? name,
    String? brand,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      barcode: barcode ?? this.barcode,
      workId: workId ?? this.workId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
