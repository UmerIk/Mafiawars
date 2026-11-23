import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/data/logic/game_state_machine.dart';
import '../../../game/data/logic/role_allocator.dart';
import '../../../game/domain/entities/game_room_entity.dart';
import '../../data/services/in_person_persistence_service.dart';
import '../../domain/entities/in_person_game_config.dart';
import '../../domain/entities/in_person_game_state.dart';

class InPersonGameNotifier extends StateNotifier<InPersonGameState?> {
  InPersonGameNotifier() : super(null) {
    loadPersistedGame();
  }

  Future<void> loadPersistedGame() async {
    final persisted = await InPersonPersistenceService.loadActiveGame();
    if (persisted != null) {
      state = persisted;
    }
  }

  void startNewGame(InPersonGameConfig config) {
    if (!config.isValid) return;

    final roleMap = RoleAllocator.allocateRoles(config.playerNames);

    state = InPersonGameState(
      config: config,
      playerRoles: roleMap,
      alivePlayerNames: List<String>.from(config.playerNames),
      eliminatedPlayerNames: [],
      currentPhase: GamePhase.lobby,
      historyLogs: ['Game setup complete with ${config.totalPlayers} agents.'],
      currentPassIndex: 0,
    );

    _persistCurrentState();
  }

  void advancePassReveal() {
    if (state == null) return;

    final nextIndex = state!.currentPassIndex + 1;
    if (nextIndex >= state!.config.totalPlayers) {
      // Pass-the-phone role reveal complete, start game at nightMafia
      state = state!.copyWith(
        currentPhase: GamePhase.nightMafia,
        historyLogs: [...state!.historyLogs, 'All agents revealed their roles. Night 1 begins.'],
      );
    } else {
      state = state!.copyWith(currentPassIndex: nextIndex);
    }

    _persistCurrentState();
  }

  void submitNightAction({required String actionType, required String targetName}) {
    if (state == null) return;

    final updatedActions = Map<String, String>.from(state!.nightActions);
    updatedActions[actionType] = targetName;

    state = state!.copyWith(
      nightActions: updatedActions,
      historyLogs: [...state!.historyLogs, 'Action submitted for $actionType.'],
    );

    _persistCurrentState();
  }

  void toggleReadyToVote(String playerName) {
    if (state == null) return;

    final currentReady = List<String>.from(state!.readyToVotePlayerNames);
    if (currentReady.contains(playerName)) {
      currentReady.remove(playerName);
    } else {
      currentReady.add(playerName);
    }

    // Check if all alive players agreed to vote
    if (currentReady.length >= state!.alivePlayerNames.length && state!.alivePlayerNames.isNotEmpty) {
      state = state!.copyWith(
        readyToVotePlayerNames: [],
        currentPhase: GamePhase.dayVoting,
        historyLogs: [...state!.historyLogs, 'All agents agreed to vote. Moving to Day Voting.'],
      );
    } else {
      state = state!.copyWith(readyToVotePlayerNames: currentReady);
    }

    _persistCurrentState();
  }

  void submitDayVote({required String voterName, required String targetName}) {
    if (state == null) return;

    final updatedVotes = Map<String, String>.from(state!.dayVotes);
    updatedVotes[voterName] = targetName;

    state = state!.copyWith(dayVotes: updatedVotes);
    _persistCurrentState();
  }

  void advancePhase() {
    if (state == null) return;

    final result = GameStateMachine.advancePhase(
      currentPhase: state!.currentPhase,
      playerRoles: state!.playerRoles,
      currentAliveIds: state!.alivePlayerNames,
      currentEliminatedIds: state!.eliminatedPlayerNames,
      phaseActions: state!.nightActions,
      dayVotes: state!.dayVotes,
    );

    final newLog = 'Advanced from ${state!.currentPhase.name} to ${result.nextPhase.name}.';

    state = state!.copyWith(
      currentPhase: result.nextPhase,
      alivePlayerNames: result.alivePlayerIds,
      eliminatedPlayerNames: result.eliminatedPlayerIds,
      winningFaction: result.winningFaction,
      nightActions: {},
      dayVotes: {},
      readyToVotePlayerNames: [],
      historyLogs: [...state!.historyLogs, newLog],
    );

    _persistCurrentState();
  }

  void resetGame() {
    state = null;
    InPersonPersistenceService.clearActiveGame();
  }

  void _persistCurrentState() {
    if (state != null) {
      InPersonPersistenceService.saveActiveGame(state!);
    }
  }
}

final inPersonGameProvider =
    StateNotifierProvider<InPersonGameNotifier, InPersonGameState?>((ref) {
  return InPersonGameNotifier();
});
