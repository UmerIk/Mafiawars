// Created by Hamza Ali on 2026-11-25.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';
import 'room_player_tile.dart';

/// Living agents stay at the top, with the eliminated roster below them.
class DayPlayersBoard extends StatelessWidget {
  const DayPlayersBoard(
      {super.key,
      required this.players,
      required this.currentUid,
      required this.speakers,
      this.onPlayerTap});
  final List<RoomPlayerEntity> players;
  final String? currentUid;
  final Set<String> speakers;
  final ValueChanged<RoomPlayerEntity>? onPlayerTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final sorted = [...players]
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        final alive = sorted.where((p) => p.isAlive).toList();
        final dead = sorted.where((p) => !p.isAlive).toList();
        final width = (size.maxWidth - 24) / 3;
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final height =
            math.max(width * 1.25, math.min(width * .74, 88) + 24 + 34 * scale);
        Widget grid(List<RoomPlayerEntity> data) =>
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final player in data)
                SizedBox(
                    width: width,
                    height: height,
                    child: RoomPlayerTile(
                        key: ValueKey(player.userId),
                        player: player,
                        slot: player.slotIndex,
                        isMe: player.userId == currentUid,
                        speaking:
                            player.isAlive && speakers.contains(player.userId),
                        inGame: true,
                        onTap: onPlayerTap == null
                            ? null
                            : () => onPlayerTap!(player)))
            ]);
        final available = size.maxHeight -
            (alive.length / 3).ceil() * (height + 12) -
            (dead.length / 3).ceil() * (height + 12);
        return SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          grid(alive),
          if (dead.isNotEmpty) ...[
            SizedBox(height: math.max(20, available)),
            Semantics(
                header: true,
                child: const Text('Eliminated agents',
                    style: AppTypography.uiCaption)),
            const SizedBox(height: 8),
            grid(dead)
          ]
        ]));
      });
}
