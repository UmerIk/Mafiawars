import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/game/data/logic/game_state_machine.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

void main() {
  group('GameStateMachine', () {
    final playerRoles = {
      'p1': PlayerRole.mafia,
      'p2': PlayerRole.doctor,
      'p3': PlayerRole.detective,
      'p4': PlayerRole.civilian,
      'p5': PlayerRole.civilian,
    };

    test('Night Actions resolution: Mafia kills p4 when Doctor saves p2', () {
      final result = GameStateMachine.advancePhase(
        currentPhase: GamePhase.nightDetective,
        playerRoles: playerRoles,
        currentAliveIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
        currentEliminatedIds: [],
        phaseActions: {
          'nightMafia': 'p4',
          'nightDoctor': 'p2',
        },
        dayVotes: {},
      );

      expect(result.alivePlayerIds, containsAll(['p1', 'p2', 'p3', 'p5']));
      expect(result.alivePlayerIds.contains('p4'), false);
      expect(result.eliminatedPlayerIds, contains('p4'));
      expect(result.nextPhase, GamePhase.dayDiscussion);
    });

    test('Night Actions resolution: Doctor saves p4 when Mafia targets p4', () {
      final result = GameStateMachine.advancePhase(
        currentPhase: GamePhase.nightDetective,
        playerRoles: playerRoles,
        currentAliveIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
        currentEliminatedIds: [],
        phaseActions: {
          'nightMafia': 'p4',
          'nightDoctor': 'p4',
        },
        dayVotes: {},
      );

      expect(result.alivePlayerIds.length, 5);
      expect(result.eliminatedPlayerIds.isEmpty, true);
    });

    test('Victory Check: Town wins when Mafia eliminated', () {
      final victory = GameStateMachine.checkVictory(
        playerRoles: playerRoles,
        alivePlayerIds: ['p2', 'p3', 'p4', 'p5'], // p1 Mafia eliminated
      );

      expect(victory, 'TOWN');
    });

    test('Victory Check: Mafia wins when 3 players left (1 Mafia + 1 Detective + 1 Citizen)', () {
      final victory = GameStateMachine.checkVictory(
        playerRoles: playerRoles,
        alivePlayerIds: ['p1', 'p3', 'p4'], // p1 Mafia, p3 Detective, p4 Citizen
      );

      expect(victory, 'MAFIA');
    });
  });
}
