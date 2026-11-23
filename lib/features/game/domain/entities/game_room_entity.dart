enum GameRoomStatus { lobby, inGame, completed }

enum GamePhase {
  lobby,
  nightMafia,
  nightDoctor,
  nightDetective,
  dayDiscussion,
  dayVoting,
  gameOver,
}

enum PlayerRole {
  mafia,
  doctor,
  detective,
  civilian,
  snitch;

  String get faction {
    switch (this) {
      case PlayerRole.mafia:
      case PlayerRole.snitch:
        return 'MAFIA';
      case PlayerRole.doctor:
      case PlayerRole.detective:
      case PlayerRole.civilian:
        return 'TOWN';
    }
  }

  String get title {
    switch (this) {
      case PlayerRole.mafia:
        return 'MAFIA';
      case PlayerRole.doctor:
        return 'DOCTOR';
      case PlayerRole.detective:
        return 'DETECTIVE';
      case PlayerRole.civilian:
        return 'CIVILIAN';
      case PlayerRole.snitch:
        return 'SNITCH';
    }
  }
}

class PlayerRoleEntity {
  final String userId;
  final PlayerRole role;
  final String faction;

  const PlayerRoleEntity({
    required this.userId,
    required this.role,
    required this.faction,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role.name,
      'faction': faction,
    };
  }

  factory PlayerRoleEntity.fromJson(Map<String, dynamic> json) {
    return PlayerRoleEntity(
      userId: json['userId'] ?? '',
      role: PlayerRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => PlayerRole.civilian,
      ),
      faction: json['faction'] ?? 'TOWN',
    );
  }
}

class MafiaChatMessageEntity {
  final String id;
  final String senderId;
  final String senderDisplayName;
  final String message;
  final DateTime timestamp;

  const MafiaChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderDisplayName': senderDisplayName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MafiaChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return MafiaChatMessageEntity(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderDisplayName: json['senderDisplayName'] ?? 'Agent',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class RoomPlayerEntity {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final int slotIndex;
  final bool isHost;
  final bool isReady;
  final bool isAlive;
  final String eliminationType; // 'killed' or 'eliminated'
  final DateTime joinedAt;

  const RoomPlayerEntity({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.slotIndex,
    this.isHost = false,
    this.isReady = false,
    this.isAlive = true,
    this.eliminationType = 'killed',
    required this.joinedAt,
  });

  RoomPlayerEntity copyWith({
    String? displayName,
    String? avatarUrl,
    int? slotIndex,
    bool? isHost,
    bool? isReady,
    bool? isAlive,
    String? eliminationType,
  }) {
    return RoomPlayerEntity(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      slotIndex: slotIndex ?? this.slotIndex,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isAlive: isAlive ?? this.isAlive,
      eliminationType: eliminationType ?? this.eliminationType,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'slotIndex': slotIndex,
      'isHost': isHost,
      'isReady': isReady,
      'isAlive': isAlive,
      'eliminationType': eliminationType,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory RoomPlayerEntity.fromJson(Map<String, dynamic> json) {
    return RoomPlayerEntity(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Agent',
      avatarUrl: json['avatarUrl'] ?? '',
      slotIndex: json['slotIndex'] ?? 0,
      isHost: json['isHost'] ?? false,
      isReady: json['isReady'] ?? false,
      isAlive: json['isAlive'] ?? true,
      eliminationType: json['eliminationType'] ?? 'killed',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

class GameRoomEntity {
  final String roomId;
  final String code;
  final String hostId;
  final GameRoomStatus status;
  final GamePhase phase;
  final DateTime? phaseEndTime;
  final String? winningFaction;
  final List<String> alivePlayerIds;
  final List<String> eliminatedPlayerIds;
  final List<String> readyToVoteUserIds;
  final Map<String, String>? nightFacts;
  final int maxPlayers;
  final int playerCount;
  final DateTime createdAt;

  const GameRoomEntity({
    required this.roomId,
    required this.code,
    required this.hostId,
    this.status = GameRoomStatus.lobby,
    this.phase = GamePhase.lobby,
    this.phaseEndTime,
    this.winningFaction,
    this.nightFacts,
    this.alivePlayerIds = const [],
    this.eliminatedPlayerIds = const [],
    this.readyToVoteUserIds = const [],
    this.maxPlayers = 12,
    this.playerCount = 1,
    required this.createdAt,
  });

  GameRoomEntity copyWith({
    String? hostId,
    GameRoomStatus? status,
    GamePhase? phase,
    DateTime? phaseEndTime,
    String? winningFaction,
    Map<String, String>? nightFacts,
    List<String>? alivePlayerIds,
    List<String>? eliminatedPlayerIds,
    List<String>? readyToVoteUserIds,
    int? maxPlayers,
    int? playerCount,
  }) {
    return GameRoomEntity(
      roomId: roomId,
      code: code,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      phaseEndTime: phaseEndTime ?? this.phaseEndTime,
      winningFaction: winningFaction ?? this.winningFaction,
      nightFacts: nightFacts ?? this.nightFacts,
      alivePlayerIds: alivePlayerIds ?? this.alivePlayerIds,
      eliminatedPlayerIds: eliminatedPlayerIds ?? this.eliminatedPlayerIds,
      readyToVoteUserIds: readyToVoteUserIds ?? this.readyToVoteUserIds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      playerCount: playerCount ?? this.playerCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'code': code,
      'hostId': hostId,
      'status': status.name,
      'phase': phase.name,
      'phaseEndTime': phaseEndTime?.toIso8601String(),
      'winningFaction': winningFaction,
      'nightFacts': nightFacts,
      'alivePlayerIds': alivePlayerIds,
      'eliminatedPlayerIds': eliminatedPlayerIds,
      'readyToVoteUserIds': readyToVoteUserIds,
      'maxPlayers': maxPlayers,
      'playerCount': playerCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameRoomEntity.fromJson(Map<String, dynamic> json) {
    return GameRoomEntity(
      roomId: json['roomId'] ?? '',
      code: json['code'] ?? '',
      hostId: json['hostId'] ?? '',
      status: GameRoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameRoomStatus.lobby,
      ),
      phase: GamePhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => GamePhase.lobby,
      ),
      phaseEndTime: json['phaseEndTime'] != null
          ? DateTime.parse(json['phaseEndTime'])
          : null,
      winningFaction: json['winningFaction'],
      nightFacts: json['nightFacts'] != null
          ? Map<String, String>.from(json['nightFacts'])
          : null,
      alivePlayerIds: List<String>.from(json['alivePlayerIds'] ?? []),
      eliminatedPlayerIds: List<String>.from(json['eliminatedPlayerIds'] ?? []),
      readyToVoteUserIds: List<String>.from(json['readyToVoteUserIds'] ?? []),
      maxPlayers: json['maxPlayers'] ?? 12,
      playerCount: json['playerCount'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
