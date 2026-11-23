import 'package:flutter/foundation.dart';
import '../../domain/entities/game_room_entity.dart';

class GamePhaseResult {
  final GamePhase nextPhase;
  final Duration phaseDuration;
  final List<String> alivePlayerIds;
  final List<String> eliminatedPlayerIds;
  final String? winningFaction;
  final Map<String, String>? nightFacts;

  const GamePhaseResult({
    required this.nextPhase,
    required this.phaseDuration,
    required this.alivePlayerIds,
    required this.eliminatedPlayerIds,
    this.winningFaction,
    this.nightFacts,
  });
}

class GameStateMachine {
  static const Duration nightPhaseDuration = Duration(seconds: 20);
  static const Duration dayDiscussionDuration = Duration(minutes: 4);
  static const Duration dayVotingDuration = Duration(seconds: 45);

  static String? checkVictory({
    required Map<String, PlayerRole> playerRoles,
    required List<String> alivePlayerIds,
  }) {
    int mafiaCount = 0;
    int doctorCount = 0;
    int detectiveCount = 0;
    int civilianCount = 0;

    for (final uid in alivePlayerIds) {
      final role = playerRoles[uid] ?? PlayerRole.civilian;
      switch (role) {
        case PlayerRole.mafia:
        case PlayerRole.snitch:
          mafiaCount++;
          break;
        case PlayerRole.doctor:
          doctorCount++;
          break;
        case PlayerRole.detective:
          detectiveCount++;
          break;
        case PlayerRole.civilian:
          civilianCount++;
          break;
      }
    }

    final totalAlive = alivePlayerIds.length;

    if (mafiaCount == 0) {
      return 'TOWN';
    }

    // 2 players left: 1 Doctor + 1 Mafia/Snitch -> Mafia wins
    if (totalAlive == 2 && mafiaCount == 1 && doctorCount == 1) {
      debugPrint('[GameStateMachine] Victory: MAFIA wins (2 players left: 1 Doctor + 1 Mafia/Snitch)');
      return 'MAFIA';
    }

    // 3 players left: If Doctor is ALIVE (doctorCount == 1), game CONTINUES so Doctor can save target
    if (totalAlive == 3 && mafiaCount == 1 && doctorCount == 1) {
      debugPrint('[GameStateMachine] 3 players left (1 Mafia/Snitch + 1 Doctor + 1 Town): Doctor is alive, game CONTINUES.');
      return null;
    }

    // 3 players left: If Doctor is DEAD (doctorCount == 0) -> Mafia wins
    if (totalAlive == 3 && mafiaCount == 1 && doctorCount == 0) {
      debugPrint('[GameStateMachine] Victory: MAFIA wins (3 players left: 1 Mafia/Snitch + 2 Town, Doctor is dead)');
      return 'MAFIA';
    }

    if (mafiaCount >= (totalAlive - mafiaCount)) {
      return 'MAFIA';
    }

    return null;
  }

  static GamePhaseResult advancePhase({
    required GamePhase currentPhase,
    required Map<String, PlayerRole> playerRoles,
    required List<String> currentAliveIds,
    required List<String> currentEliminatedIds,
    required Map<String, String> phaseActions, // actorId/key -> targetId
    required Map<String, String> dayVotes,     // voterId -> targetId
  }) {
    debugPrint('🛡️ [GameStateMachine] advancePhase called. currentPhase: ${currentPhase.name}, alive: $currentAliveIds, actions: $phaseActions, votes: $dayVotes');

    List<String> newAlive = List<String>.from(currentAliveIds);
    List<String> newEliminated = List<String>.from(currentEliminatedIds);

    switch (currentPhase) {
      case GamePhase.lobby:
        return GamePhaseResult(
          nextPhase: GamePhase.nightMafia,
          phaseDuration: nightPhaseDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );

      case GamePhase.nightMafia:
        return GamePhaseResult(
          nextPhase: GamePhase.nightDoctor,
          phaseDuration: nightPhaseDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );

      case GamePhase.nightDoctor:
        return GamePhaseResult(
          nextPhase: GamePhase.nightDetective,
          phaseDuration: nightPhaseDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );

      case GamePhase.nightDetective:
        // Collect all Mafia votes to verify consensus
        final mafiaVotes = <String>{};
        phaseActions.forEach((key, target) {
          if (key.startsWith('nightMafia') && target.isNotEmpty) {
            mafiaVotes.add(target);
          }
        });

        String? mafiaKillTarget;
        if (mafiaVotes.length == 1) {
          mafiaKillTarget = mafiaVotes.first;
        } else if (phaseActions.containsKey('nightMafia') && phaseActions['nightMafia']!.isNotEmpty) {
          mafiaKillTarget = phaseActions['nightMafia'];
        }

        final doctorSaveTarget = phaseActions['nightDoctor'];
        final detectiveTarget = phaseActions['nightDetective'];

        bool mafiaActed = mafiaKillTarget != null && mafiaKillTarget.isNotEmpty;
        bool doctorActed = doctorSaveTarget != null && doctorSaveTarget.isNotEmpty;
        bool detectiveActed = detectiveTarget != null && detectiveTarget.isNotEmpty;

        if (!mafiaActed && !doctorActed && !detectiveActed) {
          debugPrint('🛡️ [GameStateMachine] No actions found during nightDetective resolution. Preserving existing nightFacts.');
          return GamePhaseResult(
            nextPhase: GamePhase.dayDiscussion,
            phaseDuration: dayDiscussionDuration,
            alivePlayerIds: newAlive,
            eliminatedPlayerIds: newEliminated,
            nightFacts: null,
          );
        }

        bool doctorSaved = false;
        if (mafiaActed && doctorActed && mafiaKillTarget == doctorSaveTarget) {
          doctorSaved = true;
          debugPrint('💉 [GameStateMachine] Doctor successfully saved target: $doctorSaveTarget');
        } else if (mafiaActed) {
          if (newAlive.contains(mafiaKillTarget)) {
            newAlive.remove(mafiaKillTarget);
            newEliminated.add(mafiaKillTarget);
            debugPrint('💀 [GameStateMachine] Mafia successfully killed target: $mafiaKillTarget');
          }
        }

        final killedUsername = mafiaKillTarget ?? 'Someone';

        // Detective guess right or wrong (Snitch investigates as citizen -> guessRight is false)
        bool detectiveRight = false;
        if (detectiveActed) {
          final targetRole = playerRoles[detectiveTarget] ?? PlayerRole.civilian;
          detectiveRight = (targetRole == PlayerRole.mafia); // Snitch is not Mafia role, so detective sees citizen
        }

        // Construct briefing string
        String briefingText = '';
        if (doctorSaved && detectiveRight) {
          briefingText = 'Mafia tried to kill someone but doctor saved that person and detective has made a right guess';
        } else if (doctorSaved && !detectiveRight) {
          briefingText = 'Mafia tried to kill someone but doctor saved that person and detective has made a wrong guess';
        } else if (!doctorSaved && mafiaActed && detectiveRight) {
          briefingText = 'Mafia killed $killedUsername , doctor saved the wrong person and detective has made a right guess';
        } else if (!doctorSaved && mafiaActed && !detectiveRight) {
          briefingText = 'Mafia killed $killedUsername , doctor saved the wrong person and detective has made a wrong guess';
        } else {
          briefingText = 'Mafia killed $killedUsername , doctor saved the wrong person and detective has made a wrong guess';
        }

        debugPrint('☀️ [GameStateMachine] Sunrise Briefing Summary Generated: "$briefingText"');

        final nightFacts = {
          'summary': briefingText,
        };

        final victory = checkVictory(
          playerRoles: playerRoles,
          alivePlayerIds: newAlive,
        );

        if (victory != null) {
          return GamePhaseResult(
            nextPhase: GamePhase.gameOver,
            phaseDuration: Duration.zero,
            alivePlayerIds: newAlive,
            eliminatedPlayerIds: newEliminated,
            winningFaction: victory,
            nightFacts: nightFacts,
          );
        }

        return GamePhaseResult(
          nextPhase: GamePhase.dayDiscussion,
          phaseDuration: dayDiscussionDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
          nightFacts: nightFacts,
        );

      case GamePhase.dayDiscussion:
        return GamePhaseResult(
          nextPhase: GamePhase.dayVoting,
          phaseDuration: dayVotingDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );

      case GamePhase.dayVoting:
        // Tally Votes
        if (dayVotes.isNotEmpty) {
          final Map<String, int> voteCounts = {};
          for (final target in dayVotes.values) {
            voteCounts[target] = (voteCounts[target] ?? 0) + 1;
          }

          String? highestTarget;
          int highestCount = 0;
          bool isTie = false;

          voteCounts.forEach((target, count) {
            if (count > highestCount) {
              highestCount = count;
              highestTarget = target;
              isTie = false;
            } else if (count == highestCount) {
              isTie = true;
            }
          });

          if (!isTie && highestTarget != null && newAlive.contains(highestTarget!)) {
            final target = highestTarget!;
            newAlive.remove(target);
            newEliminated.add(target);
          }
        }

        final victory = checkVictory(
          playerRoles: playerRoles,
          alivePlayerIds: newAlive,
        );

        if (victory != null) {
          return GamePhaseResult(
            nextPhase: GamePhase.gameOver,
            phaseDuration: Duration.zero,
            alivePlayerIds: newAlive,
            eliminatedPlayerIds: newEliminated,
            winningFaction: victory,
          );
        }

        return GamePhaseResult(
          nextPhase: GamePhase.nightMafia,
          phaseDuration: nightPhaseDuration,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );

      case GamePhase.gameOver:
        return GamePhaseResult(
          nextPhase: GamePhase.gameOver,
          phaseDuration: Duration.zero,
          alivePlayerIds: newAlive,
          eliminatedPlayerIds: newEliminated,
        );
    }
  }
}
