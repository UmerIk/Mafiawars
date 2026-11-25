// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import 'game_floating_controls.dart';
import 'game_phase_header.dart';
import '../../domain/entities/game_room_entity.dart';
import 'room_player_tile.dart';

class RoomBriefingView extends ConsumerWidget {
  const RoomBriefingView(
      {super.key,
      required this.room,
      required this.players,
      required this.currentUid,
      required this.speakers,
      required this.seconds,
      required this.onLeave,
      required this.onChat,
      required this.onContinue,
      required this.onRetry,
      this.unreadCount = 0});
  final GameRoomEntity room;
  final AsyncValue<List<RoomPlayerEntity>> players;
  final String? currentUid;
  final Set<String> speakers;
  final int seconds, unreadCount;
  final VoidCallback onLeave, onChat, onContinue, onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me =
        players.valueOrNull?.where((p) => p.userId == currentUid).firstOrNull;
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(30, 76, 30, 30),
        child: Column(children: [
          GamePhaseHeader(
              clockFormat: true,
              title: 'Agent Briefing',
              subtitle: 'Read your secret role and mission',
              seconds: seconds,
              gradient: AppGradients.briefing,
              icon: Icons.wb_sunny_rounded),
          const SizedBox(height: 26),
          Expanded(
              child: players.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => AsyncFeedback(
                      message: 'Could not load agents.', onRetry: onRetry),
                  data: (data) => RoomPlayersGrid(
                      players: data,
                      currentUid: currentUid,
                      slotCount: data.length,
                      inGame: true,
                      speakers: speakers))),
          TextButton(
              onPressed: onContinue, child: const Text('Continue to game')),
          GameFloatingControls(
              roomId: room.roomId,
              playerCount: players.valueOrNull?.length ?? 0,
              isAlive: me?.isAlive == true,
              onLeave: onLeave,
              onChat: onChat,
              unreadCount: unreadCount)
        ]));
  }
}
