import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/social/domain/entities/friend_entity.dart';
import 'package:my_flutter_app/features/social/domain/entities/friend_request_entity.dart';

void main() {
  group('FriendEntity & FriendRequestEntity Serialization', () {
    final now = DateTime.now();

    test('FriendEntity json roundtrip', () {
      final friend = FriendEntity(
        uid: 'friend_1',
        displayName: 'Agent Viper',
        avatarUrl: 'https://example.com/viper.png',
        addedAt: now,
      );

      final json = friend.toJson();
      expect(json['uid'], 'friend_1');
      expect(json['displayName'], 'Agent Viper');

      final deserialized = FriendEntity.fromJson(json);
      expect(deserialized.uid, friend.uid);
      expect(deserialized.displayName, friend.displayName);
    });

    test('FriendRequestEntity json roundtrip', () {
      final request = FriendRequestEntity(
        id: 'req_1',
        senderId: 'user_a',
        senderDisplayName: 'Agent Ghost',
        senderAvatarUrl: 'https://example.com/ghost.png',
        receiverId: 'user_b',
        status: FriendRequestStatus.pending,
        createdAt: now,
      );

      final json = request.toJson();
      expect(json['senderId'], 'user_a');
      expect(json['status'], 'pending');

      final deserialized = FriendRequestEntity.fromJson(json);
      expect(deserialized.id, 'req_1');
      expect(deserialized.senderId, 'user_a');
      expect(deserialized.status, FriendRequestStatus.pending);
    });
  });
}
