// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';
import '../providers/briefing_providers.dart';
import '../providers/game_providers.dart';

class RoomRoleSheet extends ConsumerWidget {
  const RoomRoleSheet(
      {super.key, required this.roomId, required this.playerCount});
  final String roomId;
  final int playerCount;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(myRoleStreamProvider(roomId));
    final revealed = ref.watch(briefingRevealedProvider(roomId));
    final counts = ref.watch(briefingRoleCountsProvider(playerCount));
    return AppSheet(
        title: 'Agent Briefing',
        child: SingleChildScrollView(
            child: AgentBriefingCard(
                revealed: revealed,
                onFlip: () => ref
                    .read(briefingRevealedProvider(roomId).notifier)
                    .state = !revealed,
                counts: [
                  for (final entry in counts.entries)
                    if (entry.value > 0)
                      (
                        label: entry.key == PlayerRole.civilian
                            ? 'Citizens'
                            : '${entry.key.title[0]}${entry.key.title.substring(1).toLowerCase()}${entry.value > 1 ? 's' : ''}',
                        count: entry.value,
                        color: _color(entry.key)
                      )
                ],
                roleCard: role.when(
                    loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()),
                    error: (_, __) => AsyncFeedback(
                        message: 'Your secret role is unavailable.',
                        onRetry: () =>
                            ref.invalidate(myRoleStreamProvider(roomId))),
                    data: (data) => data == null
                        ? const AsyncFeedback(
                            message: 'Your role has not arrived yet.')
                        : AgentRoleCard(
                            title: data.role.title,
                            artwork: _art(data.role),
                            color: _color(data.role),
                            mission: [
                                _mission(data.role)
                              ],
                            victory: [
                                data.role.faction == 'MAFIA'
                                    ? 'Help the Mafia win under the current game rules.'
                                    : 'Eliminate every Mafia agent and Snitch.'
                              ])))));
  }
}

Color _color(PlayerRole role) => switch (role) {
      PlayerRole.mafia => AppColors.neonCrimson,
      PlayerRole.snitch => AppColors.figmaPaletteGreen,
      PlayerRole.doctor || PlayerRole.detective => AppColors.publicBlue,
      PlayerRole.civilian => AppColors.figmaYellow,
    };
String _art(PlayerRole role) => switch (role) {
      PlayerRole.mafia => AppAssets.mafia,
      PlayerRole.doctor => AppAssets.doctor,
      PlayerRole.detective => AppAssets.detective,
      PlayerRole.snitch => AppAssets.snitch,
      PlayerRole.civilian => AppAssets.civilian,
    };
String _mission(PlayerRole role) => switch (role) {
      PlayerRole.mafia =>
        'Choose a target during the Mafia night phase and keep your identity secret.',
      PlayerRole.doctor =>
        'Choose one agent to protect during the Doctor night phase.',
      PlayerRole.detective =>
        'Investigate an agent during your night phase to learn their faction.',
      PlayerRole.snitch => 'Help the Mafia while keeping your identity hidden.',
      PlayerRole.civilian =>
        'Discuss the evidence and vote to expose the Mafia.',
    };
