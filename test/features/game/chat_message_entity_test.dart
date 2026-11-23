import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/domain/entities/chat_message_entity.dart';

void main() {
  group('ChatMessageEntity Serialization', () {
    final now = DateTime.now();

    test('serializes to JSON and deserializes correctly for public channel', () {
      final msg = ChatMessageEntity(
        id: 'msg_101',
        senderId: 'user_1',
        senderDisplayName: 'Agent Alpha',
        senderAvatarUrl: 'https://example.com/alpha.png',
        message: 'I think Agent Beta is suspicious!',
        channelType: 'public',
        timestamp: now,
      );

      final json = msg.toJson();
      expect(json['id'], 'msg_101');
      expect(json['channelType'], 'public');

      final deserialized = ChatMessageEntity.fromJson(json);
      expect(deserialized.id, 'msg_101');
      expect(deserialized.senderDisplayName, 'Agent Alpha');
      expect(deserialized.channelType, 'public');
    });

    test('serializes to JSON and deserializes correctly for mafia channel', () {
      final msg = ChatMessageEntity(
        id: 'msg_102',
        senderId: 'user_2',
        senderDisplayName: 'Agent Shadow',
        senderAvatarUrl: '',
        message: 'Let\'s target Agent Gamma tonight.',
        channelType: 'mafia',
        timestamp: now,
      );

      final json = msg.toJson();
      expect(json['channelType'], 'mafia');

      final deserialized = ChatMessageEntity.fromJson(json);
      expect(deserialized.channelType, 'mafia');
      expect(deserialized.message, 'Let\'s target Agent Gamma tonight.');
    });
  });
}
