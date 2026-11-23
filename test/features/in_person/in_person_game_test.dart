import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';
import 'package:my_flutter_app/features/in_person/domain/entities/in_person_game_config.dart';
import 'package:my_flutter_app/features/in_person/domain/entities/in_person_game_state.dart';

void main() {
  group('InPersonGameConfig & State Validation', () {
    test('validates equal player count and role counts', () {
      const config = InPersonGameConfig(
        mode: InPersonGameMode.fullDigital,
        playerNames: ['Alpha', 'Viper', 'Shadow', 'Ghost', 'Spectre', 'Cipher'],
        mafiaCount: 2,
        includeDoctor: true,
        includeDetective: true,
        civilianCount: 2,
      );

      expect(config.totalPlayers, 6);
      expect(config.totalRoles, 6);
      expect(config.isValid, true);
      expect(config.validationError, null);
    });

    test('invalidates config when total roles mismatch total players', () {
      const config = InPersonGameConfig(
        mode: InPersonGameMode.fullDigital,
        playerNames: ['Alpha', 'Viper', 'Shadow', 'Ghost', 'Spectre'],
        mafiaCount: 2,
        includeDoctor: true,
        includeDetective: true,
        civilianCount: 2, // 2 + 1 + 1 + 2 = 6 roles for 5 players
      );

      expect(config.isValid, false);
      expect(config.validationError!.contains('Total players (5) must equal total assigned roles (6)'), true);
    });

    test('InPersonGameState JSON roundtrip serialization', () {
      const config = InPersonGameConfig(
        mode: InPersonGameMode.fullDigital,
        playerNames: ['Alpha', 'Viper', 'Shadow', 'Ghost', 'Spectre'],
        mafiaCount: 1,
        includeDoctor: true,
        includeDetective: true,
        civilianCount: 2,
      );

      final state = InPersonGameState(
        config: config,
        playerRoles: {
          'Alpha': PlayerRole.mafia,
          'Viper': PlayerRole.doctor,
          'Shadow': PlayerRole.detective,
          'Ghost': PlayerRole.civilian,
          'Spectre': PlayerRole.civilian,
        },
        alivePlayerNames: ['Alpha', 'Viper', 'Shadow', 'Ghost', 'Spectre'],
      );

      final json = state.toJson();
      expect(json['alivePlayerNames'], ['Alpha', 'Viper', 'Shadow', 'Ghost', 'Spectre']);

      final deserialized = InPersonGameState.fromJson(json);
      expect(deserialized.config.totalPlayers, 5);
      expect(deserialized.playerRoles['Alpha'], PlayerRole.mafia);
      expect(deserialized.alivePlayerNames.length, 5);
    });
  });
}
