class Store {
  const Store({
    this.id,
    required this.name,
    this.normalizedName,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? normalizedName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Store copyWith({
    int? id,
    String? name,
    String? normalizedName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
