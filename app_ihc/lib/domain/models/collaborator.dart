class Collaborator {
  const Collaborator({
    this.id,
    required this.username,
    this.friendlyName,
    this.createdAt,
  });

  final int? id;
  final String username;
  final String? friendlyName;
  final DateTime? createdAt;

  Collaborator copyWith({
    int? id,
    String? username,
    String? friendlyName,
    DateTime? createdAt,
  }) {
    return Collaborator(
      id: id ?? this.id,
      username: username ?? this.username,
      friendlyName: friendlyName ?? this.friendlyName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
