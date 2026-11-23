class UserEntity {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;
  final int gamesPlayed;
  final int wins;
  final String userStatus; // 'online', 'in_game', 'offline'

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.userStatus = 'offline',
  });

  UserEntity copyWith({
    String? displayName,
    String? avatarUrl,
    int? gamesPlayed,
    int? wins,
    String? userStatus,
  }) {
    return UserEntity(
      uid: uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      userStatus: userStatus ?? this.userStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'status': userStatus,
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Agent',
      avatarUrl: json['avatarUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      gamesPlayed: json['gamesPlayed'] ?? 0,
      wins: json['wins'] ?? 0,
      userStatus: json['status'] ?? 'offline',
    );
  }
}
