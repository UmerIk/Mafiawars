import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

void main() {
  group('GameRoomEntity & RoomPlayerEntity', () {
    final now = DateTime.now();

    test('GameRoomEntity JSON serialization & deserialization', () {
      final room = GameRoomEntity(
        roomId: 'room_123',
        code: 'MAFIA7',
        hostId: 'host_456',
        status: GameRoomStatus.lobby,
        maxPlayers: 12,
        playerCount: 4,
        createdAt: now,
      );

      final json = room.toJson();
      expect(json['roomId'], 'room_123');
      expect(json['code'], 'MAFIA7');
      expect(json['status'], 'lobby');

      final deserialized = GameRoomEntity.fromJson(json);
      expect(deserialized.roomId, 'room_123');
      expect(deserialized.code, 'MAFIA7');
      expect(deserialized.status, GameRoomStatus.lobby);
    });

    test('RoomPlayerEntity JSON serialization & deserialization', () {
      final player = RoomPlayerEntity(
        userId: 'user_789',
        displayName: 'Agent Spectre',
        avatarUrl: 'https://example.com/avatar.png',
        slotIndex: 2,
        isHost: true,
        isReady: true,
        joinedAt: now,
      );

      final json = player.toJson();
      expect(json['userId'], 'user_789');
      expect(json['slotIndex'], 2);
      expect(json['isHost'], true);

      final deserialized = RoomPlayerEntity.fromJson(json);
      expect(deserialized.userId, 'user_789');
      expect(deserialized.slotIndex, 2);
      expect(deserialized.isReady, true);
    });
  });
}
