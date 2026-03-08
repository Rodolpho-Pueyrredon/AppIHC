class Product {
  const Product({
    this.id,
    required this.barcode,
    this.name,
    this.brand,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String barcode;
  final String? name;
  final String? brand;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? brand,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
