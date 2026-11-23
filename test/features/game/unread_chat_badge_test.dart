import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

/// Unread chat badge matrix rule evaluator
Set<String> getEligibleUnreadChatChannels({
  required PlayerRole? role,
  required bool isAlive,
}) {
  final Set<String> channels = {'public'};
  if (role == PlayerRole.mafia) {
    channels.add('mafia');
  }
  if (!isAlive) {
    channels.add('ghost');
  }
  return channels;
}

void main() {
  group('Unread Message Animated Badge Matrix Tests', () {
    test('Ghost chat (dead person) - Mafia role: Mafia True, Public True, Ghost True', () {
      final channels = getEligibleUnreadChatChannels(
        role: PlayerRole.mafia,
        isAlive: false,
      );

      expect(channels.contains('mafia'), isTrue);
      expect(channels.contains('public'), isTrue);
      expect(channels.contains('ghost'), isTrue);
    });

    test('Ghost chat (dead person) - Non-mafia role: Mafia False, Public True, Ghost True', () {
      final channels = getEligibleUnreadChatChannels(
        role: PlayerRole.civilian,
        isAlive: false,
      );

      expect(channels.contains('mafia'), isFalse);
      expect(channels.contains('public'), isTrue);
      expect(channels.contains('ghost'), isTrue);
    });

    test('Mafia chat (alive mafias): Mafia True, Public True, Ghost False', () {
      final channels = getEligibleUnreadChatChannels(
        role: PlayerRole.mafia,
        isAlive: true,
      );

      expect(channels.contains('mafia'), isTrue);
      expect(channels.contains('public'), isTrue);
      expect(channels.contains('ghost'), isFalse);
    });

    test('Civilians / Detective / Doctors (alive non-mafia): Mafia False, Public True, Ghost False', () {
      for (final role in [
        PlayerRole.civilian,
        PlayerRole.detective,
        PlayerRole.doctor,
      ]) {
        final channels = getEligibleUnreadChatChannels(
          role: role,
          isAlive: true,
        );

        expect(channels.contains('mafia'), isFalse, reason: 'Mafia unread badge must be false for $role');
        expect(channels.contains('public'), isTrue, reason: 'Public unread badge must be true for $role');
        expect(channels.contains('ghost'), isFalse, reason: 'Ghost unread badge must be false for $role');
      }
    });
  });
}
