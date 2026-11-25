// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';

/// Dynamic agent identity remains recognizable in killed and jailed states.
class PlayerStateAvatar extends StatelessWidget {
  const PlayerStateAvatar({super.key, required this.player, this.size = 88});
  final RoomPlayerEntity player;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (player.isAlive) return AgentAvatar(value: player.avatarUrl, size: size);
    final jailed = player.eliminationType == 'eliminated';
    return Semantics(
        label: jailed ? 'Eliminated by vote' : 'Killed at night',
        child: SizedBox(
            width: size,
            height: size,
            child: ClipOval(
                child: Stack(fit: StackFit.expand, children: [
              ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    .2126,
                    .7152,
                    .0722,
                    0,
                    0,
                    .2126,
                    .7152,
                    .0722,
                    0,
                    0,
                    .2126,
                    .7152,
                    .0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0
                  ]),
                  child: AgentAvatar(value: player.avatarUrl, size: size)),
              Image.asset(
                  jailed
                      ? AppAssets.eliminationJail
                      : AppAssets.eliminationBlood,
                  fit: BoxFit.fill,
                  excludeFromSemantics: true),
            ]))));
  }
}
