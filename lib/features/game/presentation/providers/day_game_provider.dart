// Created by Hamza Ali on 2026-11-25.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_room_entity.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_providers.dart';
import 'night_action_provider.dart';

class DayActionController extends StateNotifier<AsyncValue<String?>> {
  DayActionController(this.repository, this.roomId)
      : super(const AsyncData(null));
  final GameRepository repository;
  final String roomId;
  Future<void> vote(String target) => _perform(
      () => repository.submitDayVote(roomId: roomId, targetUserId: target),
      target);
  Future<void> ready() =>
      _perform(() => repository.toggleReadyToVote(roomId), state.valueOrNull);
  Future<void> _perform(Future<void> Function() action, String? target) async {
    if (state.isLoading) return;
    final previous = state;
    state = const AsyncLoading<String?>().copyWithPrevious(previous);
    try {
      await action();
      if (mounted) state = AsyncData(target);
    } catch (error, stack) {
      if (mounted) {
        state = AsyncError<String?>(error, stack).copyWithPrevious(previous);
      }
    }
  }
}

final dayActionProvider = StateNotifierProvider.autoDispose
    .family<DayActionController, AsyncValue<String?>, NightActionSession>((ref,
            session) =>
        DayActionController(ref.watch(gameRepositoryProvider), session.roomId));

/// Captures the observed voting transition; never guesses an outcome from tallies.
class VoteDecision {
  const VoteDecision({required this.playerId, required this.voters});
  final String? playerId;
  final Map<String, String> voters;
  int get count => voters.values.where((target) => target == playerId).length;
}

VoteDecision? decisionFromTransition(
    GameRoomEntity previous, GameRoomEntity next, Map<String, String> votes) {
  if (previous.roomId != next.roomId ||
      previous.phase != GamePhase.dayVoting ||
      next.phase == GamePhase.dayVoting ||
      next.status == GameRoomStatus.lobby) {
    return null;
  }
  final eliminated = next.eliminatedPlayerIds
      .where((id) => !previous.eliminatedPlayerIds.contains(id))
      .toList();
  return VoteDecision(
      playerId: eliminated.length == 1 ? eliminated.single : null,
      voters: Map.unmodifiable(votes));
}

final voteDecisionProvider = StateProvider.autoDispose
    .family<VoteDecision?, String>((ref, roomId) => null);

final lastVotingSnapshotProvider = StateProvider.autoDispose
    .family<Map<String, String>, String>((ref, roomId) => const {});
