import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/game_room_entity.dart';

class RoomPlayerModel extends RoomPlayerEntity {
  const RoomPlayerModel({
    required super.userId,
    required super.displayName,
    required super.avatarUrl,
    required super.slotIndex,
    super.isHost,
    super.isReady,
    super.isAlive,
    super.eliminationType,
    required super.joinedAt,
  });

  factory RoomPlayerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return RoomPlayerModel(
      userId: snapshot.id,
      displayName: data['displayName'] ?? 'Agent',
      avatarUrl: data['avatarUrl'] ?? '',
      slotIndex: data['slotIndex'] ?? 0,
      isHost: data['isHost'] ?? false,
      isReady: data['isReady'] ?? false,
      isAlive: data['isAlive'] ?? true,
      eliminationType: data['eliminationType'] ?? 'killed',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'slotIndex': slotIndex,
      'isHost': isHost,
      'isReady': isReady,
      'isAlive': isAlive,
      'eliminationType': eliminationType,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class GameRoomModel extends GameRoomEntity {
  const GameRoomModel({
    required super.roomId,
    required super.code,
    required super.hostId,
    super.status,
    super.phase,
    super.phaseEndTime,
    super.winningFaction,
    super.nightFacts,
    super.alivePlayerIds,
    super.eliminatedPlayerIds,
    super.readyToVoteUserIds,
    super.maxPlayers,
    super.playerCount,
    required super.createdAt,
  });

  factory GameRoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return GameRoomModel(
      roomId: snapshot.id,
      code: data['code'] ?? '',
      hostId: data['hostId'] ?? '',
      status: GameRoomStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GameRoomStatus.lobby,
      ),
      phase: GamePhase.values.firstWhere(
        (e) => e.name == data['phase'],
        orElse: () => GamePhase.lobby,
      ),
      phaseEndTime: (data['phaseEndTime'] as Timestamp?)?.toDate(),
      winningFaction: data['winningFaction'],
      nightFacts: data['nightFacts'] != null
          ? Map<String, String>.from(data['nightFacts'])
          : null,
      alivePlayerIds: List<String>.from(data['alivePlayerIds'] ?? []),
      eliminatedPlayerIds: List<String>.from(data['eliminatedPlayerIds'] ?? []),
      readyToVoteUserIds: List<String>.from(data['readyToVoteUserIds'] ?? []),
      maxPlayers: data['maxPlayers'] ?? 12,
      playerCount: data['playerCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'hostId': hostId,
      'status': status.name,
      'phase': phase.name,
      'phaseEndTime': phaseEndTime != null ? Timestamp.fromDate(phaseEndTime!) : null,
      'winningFaction': winningFaction,
      'nightFacts': nightFacts,
      'alivePlayerIds': alivePlayerIds,
      'eliminatedPlayerIds': eliminatedPlayerIds,
      'readyToVoteUserIds': readyToVoteUserIds,
      'maxPlayers': maxPlayers,
      'playerCount': playerCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
