import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    final now = DateTime.now();
    final testUser = UserEntity(
      uid: 'user123',
      displayName: 'Agent 47',
      avatarUrl: 'https://example.com/avatar.png',
      createdAt: now,
      gamesPlayed: 10,
      wins: 7,
    );

    test('should properly serialize to JSON and deserialize from JSON', () {
      final json = testUser.toJson();
      expect(json['uid'], 'user123');
      expect(json['displayName'], 'Agent 47');
      expect(json['avatarUrl'], 'https://example.com/avatar.png');
      expect(json['gamesPlayed'], 10);
      expect(json['wins'], 7);

      final deserialized = UserEntity.fromJson(json);
      expect(deserialized.uid, testUser.uid);
      expect(deserialized.displayName, testUser.displayName);
      expect(deserialized.avatarUrl, testUser.avatarUrl);
      expect(deserialized.gamesPlayed, testUser.gamesPlayed);
      expect(deserialized.wins, testUser.wins);
    });

    test('copyWith should copy properties correctly', () {
      final updated = testUser.copyWith(
        displayName: 'Shadow',
        wins: 8,
      );

      expect(updated.uid, 'user123');
      expect(updated.displayName, 'Shadow');
      expect(updated.avatarUrl, 'https://example.com/avatar.png');
      expect(updated.wins, 8);
      expect(updated.gamesPlayed, 10);
    });
  });
}
