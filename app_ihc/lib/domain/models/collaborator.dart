class Collaborator {
  const Collaborator({
    this.id,
    required this.username,
    this.createdAt,
  });

  final int? id;
  final String username;
  final DateTime? createdAt;

  Collaborator copyWith({
    int? id,
    String? username,
    DateTime? createdAt,
  }) {
    return Collaborator(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
