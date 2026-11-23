import '../game/domain/entities/game_room_entity.dart';

class NarrationScript {
  final String id;
  final String text;
  final String? audioUrl;

  const NarrationScript({
    required this.id,
    required this.text,
    this.audioUrl,
  });
}

class ElevenLabsModeratorService {
  NarrationScript getPhaseNarrationScript(GamePhase phase, {String? winningFaction}) {
    switch (phase) {
      case GamePhase.nightMafia:
        return const NarrationScript(
          id: 'night_mafia',
          text: 'Night falls over the city of shadows. All agents close your eyes. Mafia, wake up and choose your target.',
        );
      case GamePhase.nightDoctor:
        return const NarrationScript(
          id: 'night_doctor',
          text: 'Doctor, wake up and choose an agent to protect tonight.',
        );
      case GamePhase.nightDetective:
        return const NarrationScript(
          id: 'night_detective',
          text: 'Detective, wake up and choose an agent to investigate.',
        );
      case GamePhase.dayDiscussion:
        return const NarrationScript(
          id: 'day_discussion',
          text: 'The sun rises over the city. City discussion has begun. Debate and identify the suspects.',
        );
      case GamePhase.dayVoting:
        return const NarrationScript(
          id: 'day_voting',
          text: 'Town discussion has ended. Cast your votes now to eliminate a suspect.',
        );
      case GamePhase.gameOver:
        final winner = winningFaction ?? 'TOWN';
        return NarrationScript(
          id: 'game_over_$winner',
          text: 'The assignment is complete. $winner Victory has been declared!',
        );
      case GamePhase.lobby:
      default:
        return const NarrationScript(
          id: 'lobby_welcome',
          text: 'Welcome agents. Assemble in the lobby and prepare for the assignment.',
        );
    }
  }
}
