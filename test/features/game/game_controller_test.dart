import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_flutter_app/features/game/domain/entities/chat_message_entity.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';
import 'package:my_flutter_app/features/game/domain/repositories/game_repository.dart';
import 'package:my_flutter_app/features/game/presentation/providers/game_providers.dart';

class FakeGameRepository implements GameRepository {
  GameRoomEntity? mockRoom;
  List<RoomPlayerEntity> mockPlayers = [];

  @override
  Future<GameRoomEntity> createRoom({int maxPlayers = 12}) async {
    mockRoom = GameRoomEntity(
      roomId: 'room_abc',
      code: 'TEST66',
      hostId: 'host_uid',
      status: GameRoomStatus.lobby,
      maxPlayers: maxPlayers,
      playerCount: 1,
      createdAt: DateTime.now(),
    );
    mockPlayers = [
      RoomPlayerEntity(
        userId: 'host_uid',
        displayName: 'HostAgent',
        avatarUrl: '',
        slotIndex: 0,
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now(),
      ),
    ];
    return mockRoom!;
  }

  @override
  Future<GameRoomEntity> joinRoomByCode(String code) async {
    if (mockRoom != null && mockRoom!.code == code.toUpperCase()) {
      mockRoom = mockRoom!.copyWith(playerCount: mockRoom!.playerCount + 1);
      return mockRoom!;
    }
    throw Exception('Room not found');
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    mockRoom = null;
    mockPlayers = [];
  }

  @override
  Future<void> toggleReadyStatus(String roomId) async {
    if (mockPlayers.isNotEmpty) {
      final p = mockPlayers.first;
      mockPlayers[0] = p.copyWith(isReady: !p.isReady);
    }
  }

  @override
  Future<void> startGame(String roomId) async {
    if (mockRoom != null) {
      mockRoom = mockRoom!.copyWith(status: GameRoomStatus.inGame);
    }
  }

  @override
  Stream<GameRoomEntity?> getRoomStream(String roomId) => Stream.value(mockRoom);

  @override
  Stream<List<RoomPlayerEntity>> getRoomPlayersStream(String roomId) =>
      Stream.value(mockPlayers);

  @override
  Future<PlayerRoleEntity?> getMyRole(String roomId) async =>
      const PlayerRoleEntity(userId: 'host_uid', role: PlayerRole.mafia, faction: 'MAFIA');

  @override
  Stream<PlayerRoleEntity?> getMyRoleStream(String roomId) => Stream.value(
      const PlayerRoleEntity(userId: 'host_uid', role: PlayerRole.mafia, faction: 'MAFIA'));

  @override
  Future<void> submitPhaseAction({required String roomId, required String targetUserId}) async {}

  @override
  Future<void> submitDayVote({required String roomId, required String targetUserId}) async {}

  @override
  Future<void> toggleReadyToVote(String roomId) async {}

  @override
  Future<void> sendMafiaChatMessage({required String roomId, required String message}) async {}

  @override
  Stream<List<MafiaChatMessageEntity>> getMafiaChatStream(String roomId) => Stream.value([]);

  @override
  Future<void> sendMultiChannelChatMessage({
    required String roomId,
    required String message,
    required String channel,
  }) async {}

  @override
  Stream<List<ChatMessageEntity>> getMultiChannelChatStream({
    required String roomId,
    required String channel,
  }) => Stream.value([]);

  @override
  Stream<Map<String, String>> getRoomVotesStream(String roomId) => Stream.value({});

  @override
  Stream<Map<String, String>> getRoomActionsStream(String roomId) => Stream.value({});

  @override
  Future<void> advanceGamePhase(String roomId) async {}

  @override
  Future<void> resetRoomToLobby(String roomId) async {}

  @override
  Future<Map<String, PlayerRole>> getAllRoomRoles(String roomId) async => {};
}

void main() {
  late ProviderContainer container;
  late FakeGameRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeGameRepository();
    container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('GameController creates room and updates state', () async {
    final controller = container.read(gameControllerProvider.notifier);
    final room = await controller.createRoom();

    expect(room?.code, 'TEST66');
    expect(fakeRepo.mockRoom?.hostId, 'host_uid');
  });

  test('GameController joins room by code', () async {
    final controller = container.read(gameControllerProvider.notifier);
    await controller.createRoom();

    final joinedRoom = await controller.joinRoomByCode('TEST66');
    expect(joinedRoom?.playerCount, 2);
  });
}
