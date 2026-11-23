import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/game_repository_impl.dart';
import '../../domain/entities/game_room_entity.dart';
import '../../domain/repositories/game_repository.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl();
});

final activeRoomStreamProvider =
    StreamProvider.family<GameRoomEntity?, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getRoomStream(roomId);
});

final roomPlayersStreamProvider =
    StreamProvider.family<List<RoomPlayerEntity>, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getRoomPlayersStream(roomId);
});

final myRoleStreamProvider =
    StreamProvider.family<PlayerRoleEntity?, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getMyRoleStream(roomId);
});

final mafiaChatStreamProvider =
    StreamProvider.family<List<MafiaChatMessageEntity>, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getMafiaChatStream(roomId);
});

final roomVotesStreamProvider =
    StreamProvider.family<Map<String, String>, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getRoomVotesStream(roomId);
});

final roomActionsStreamProvider =
    StreamProvider.family<Map<String, String>, String>((ref, roomId) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  return gameRepo.getRoomActionsStream(roomId);
});

class GameController extends StateNotifier<AsyncValue<void>> {
  final GameRepository _gameRepository;

  GameController(this._gameRepository) : super(const AsyncValue.data(null));

  Future<GameRoomEntity?> createRoom({int maxPlayers = 12}) async {
    state = const AsyncValue.loading();
    GameRoomEntity? room;
    state = await AsyncValue.guard(() async {
      room = await _gameRepository.createRoom(maxPlayers: maxPlayers);
    });
    return room;
  }

  Future<GameRoomEntity?> joinRoomByCode(String code) async {
    state = const AsyncValue.loading();
    GameRoomEntity? room;
    state = await AsyncValue.guard(() async {
      room = await _gameRepository.joinRoomByCode(code);
    });
    return room;
  }

  Future<void> leaveRoom(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.leaveRoom(roomId));
  }

  Future<void> toggleReadyStatus(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.toggleReadyStatus(roomId));
  }

  Future<void> startGame(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.startGame(roomId));
  }

  Future<void> submitPhaseAction({
    required String roomId,
    required String targetUserId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _gameRepository.submitPhaseAction(roomId: roomId, targetUserId: targetUserId));
  }

  Future<void> submitDayVote({
    required String roomId,
    required String targetUserId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _gameRepository.submitDayVote(roomId: roomId, targetUserId: targetUserId));
  }

  Future<void> toggleReadyToVote(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.toggleReadyToVote(roomId));
  }

  Future<void> sendMafiaChatMessage({
    required String roomId,
    required String message,
  }) async {
    state = await AsyncValue.guard(() =>
        _gameRepository.sendMafiaChatMessage(roomId: roomId, message: message));
  }

  Future<void> advanceGamePhase(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.advanceGamePhase(roomId));
  }

  Future<void> resetRoomToLobby(String roomId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _gameRepository.resetRoomToLobby(roomId));
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, AsyncValue<void>>((ref) {
  return GameController(ref.watch(gameRepositoryProvider));
});
