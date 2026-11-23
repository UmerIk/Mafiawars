class FriendEntity {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final DateTime addedAt;
  final String status; // 'online', 'in_game', 'offline'

  const FriendEntity({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.addedAt,
    this.status = 'offline',
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'addedAt': addedAt.toIso8601String(),
      'status': status,
    };
  }

  factory FriendEntity.fromJson(Map<String, dynamic> json) {
    return FriendEntity(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Agent',
      avatarUrl: json['avatarUrl'] ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
      status: json['status'] ?? 'offline',
    );
  }
}
