import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/audio/elevenlabs_moderator_service.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

void main() {
  group('ElevenLabsModeratorService & Script Generation', () {
    late ElevenLabsModeratorService moderatorService;

    setUp(() {
      moderatorService = ElevenLabsModeratorService();
    });

    test('generates correct script for nightMafia phase', () {
      final script = moderatorService.getPhaseNarrationScript(GamePhase.nightMafia);
      expect(script.id, 'night_mafia');
      expect(script.text.contains('Mafia, wake up'), true);
    });

    test('generates correct script for gameOver Town victory', () {
      final script = moderatorService.getPhaseNarrationScript(
        GamePhase.gameOver,
        winningFaction: 'TOWN',
      );
      expect(script.id, 'game_over_TOWN');
      expect(script.text.contains('TOWN Victory'), true);
    });
  });
}
