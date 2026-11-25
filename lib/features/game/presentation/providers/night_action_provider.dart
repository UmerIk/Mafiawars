// Created by Hamza Ali on 2026-11-25.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_room_entity.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_providers.dart';

typedef NightActionSession = ({
  String roomId,
  GamePhase phase,
  DateTime? deadline
});
final sunriseDismissedProvider = StateProvider.autoDispose
    .family<bool, NightActionSession>((ref, session) => false);

bool canChooseNightTarget(
    {required GamePhase phase,
    required PlayerRole? role,
    required RoomPlayerEntity? actor,
    required RoomPlayerEntity target}) {
  if (actor == null ||
      actor.userId.isEmpty ||
      target.userId.isEmpty ||
      !actor.isAlive ||
      !target.isAlive) {
    return false;
  }
  final eligible = switch (phase) {
    GamePhase.nightMafia => role == PlayerRole.mafia,
    GamePhase.nightDoctor => role == PlayerRole.doctor,
    GamePhase.nightDetective => role == PlayerRole.detective,
    _ => false,
  };
  return eligible &&
      (phase == GamePhase.nightDoctor || actor.userId != target.userId);
}

/// Scoped to the phase deadline so selections/errors cannot leak into another round.
class NightActionController extends StateNotifier<AsyncValue<String?>> {
  NightActionController(this.repository, this.roomId)
      : super(const AsyncData(null));
  final GameRepository repository;
  final String roomId;
  Future<void> submit(String target) async {
    if (state.isLoading) return;
    final previous = state;
    state = const AsyncLoading<String?>().copyWithPrevious(previous);
    try {
      await repository.submitPhaseAction(roomId: roomId, targetUserId: target);
      if (mounted) state = AsyncData(target);
    } catch (error, stack) {
      if (mounted) {
        state = AsyncError<String?>(error, stack).copyWithPrevious(previous);
      }
    }
  }
}

final nightActionProvider = StateNotifierProvider.autoDispose
    .family<NightActionController, AsyncValue<String?>, NightActionSession>(
        (ref, session) => NightActionController(
            ref.watch(gameRepositoryProvider), session.roomId));
