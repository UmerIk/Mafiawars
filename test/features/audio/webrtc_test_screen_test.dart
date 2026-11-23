import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/audio/elevenlabs_moderator_service.dart';
import 'package:my_flutter_app/features/game/domain/entities/game_room_entity.dart';

void main() {
  group('WebRTC & Moderator Audio Verification', () {
    test('ElevenLabs Moderator produces valid scripts for all phases', () {
      final service = ElevenLabsModeratorService();

      final nightScript = service.getPhaseNarrationScript(GamePhase.nightMafia);
      expect(nightScript.text.contains('Night falls'), true);

      final dayScript = service.getPhaseNarrationScript(GamePhase.dayDiscussion);
      expect(dayScript.text.contains('sun rises'), true);

      final votingScript = service.getPhaseNarrationScript(GamePhase.dayVoting);
      expect(votingScript.text.contains('Cast your votes'), true);
    });
  });
}
