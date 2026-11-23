import '../entities/chat_message_entity.dart';
import '../entities/game_room_entity.dart';

abstract class GameRepository {
  Future<GameRoomEntity> createRoom({int maxPlayers = 12});
  Future<GameRoomEntity> joinRoomByCode(String code);
  Future<void> leaveRoom(String roomId);
  Future<void> toggleReadyStatus(String roomId);
  Future<void> startGame(String roomId);
  Stream<GameRoomEntity?> getRoomStream(String roomId);
  Stream<List<RoomPlayerEntity>> getRoomPlayersStream(String roomId);

  Future<PlayerRoleEntity?> getMyRole(String roomId);
  Stream<PlayerRoleEntity?> getMyRoleStream(String roomId);
  Future<void> submitPhaseAction({required String roomId, required String targetUserId});
  Future<void> submitDayVote({required String roomId, required String targetUserId});
  Future<void> toggleReadyToVote(String roomId);
  Future<void> sendMafiaChatMessage({required String roomId, required String message});
  Stream<List<MafiaChatMessageEntity>> getMafiaChatStream(String roomId);

  Future<void> sendMultiChannelChatMessage({
    required String roomId,
    required String message,
    required String channel,
  });

  Stream<List<ChatMessageEntity>> getMultiChannelChatStream({
    required String roomId,
    required String channel,
  });

  Stream<Map<String, String>> getRoomVotesStream(String roomId);
  Stream<Map<String, String>> getRoomActionsStream(String roomId);

  Future<void> advanceGamePhase(String roomId);
  Future<void> resetRoomToLobby(String roomId);
  Future<Map<String, PlayerRole>> getAllRoomRoles(String roomId);
}
