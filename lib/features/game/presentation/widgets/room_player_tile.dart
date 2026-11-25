// Created by Hamza Ali on 2026-11-25.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';
import 'player_state_avatar.dart';

class RoomPlayerTile extends StatelessWidget {
  const RoomPlayerTile(
      {super.key,
      this.player,
      required this.slot,
      this.isMe = false,
      this.speaking = false,
      this.inGame = false,
      this.onTap});
  final RoomPlayerEntity? player;
  final int slot;
  final bool isMe, speaking, inGame;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 20,
      gradient: isMe && player?.isAlive != false
          ? AppGradients.agentHighlight
          : AppGradients.burgundy,
      borderWidth: player == null ? 0 : 1,
      onTap: onTap,
      child: player == null
          ? Center(
              child: Text('Slot ${slot + 1}',
                  style: AppTypography.uiCaption
                      .copyWith(color: AppColors.figmaCyan)))
          : LayoutBuilder(builder: (context, size) {
              final avatarSize = math.min(size.maxWidth * .74, 88.0);
              final status = inGame
                  ? !player!.isAlive
                      ? player!.eliminationType == 'eliminated'
                          ? 'ELIMINATED'
                          : 'KILLED'
                      : speaking
                          ? 'Speaking…'
                          : player!.isAlive
                              ? ''
                              : 'Eliminated'
                  : player!.isReady
                      ? 'Ready'
                      : 'Not Ready';
              return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          PlayerStateAvatar(player: player!, size: avatarSize),
                          if (player!.isHost)
                            Positioned(
                                right: -2,
                                top: 0,
                                child: Semantics(
                                    label: 'Room host',
                                    child: const CircleAvatar(
                                        radius: 11,
                                        backgroundColor: AppColors.figmaWhite,
                                        child: Icon(Icons.star,
                                            color: AppColors.figmaPink,
                                            size: 16))))
                        ]),
                        const SizedBox(height: 4),
                        Text(isMe ? 'You' : player!.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.uiBody.copyWith(
                                fontWeight: FontWeight.w700, height: 1.2)),
                        Text(status,
                            maxLines: 1,
                            style: AppTypography.uiCaption.copyWith(
                                fontSize: 10,
                                height: 1.2,
                                color: !player!.isAlive
                                    ? AppColors.neonCrimson
                                    : speaking || player!.isReady
                                        ? AppColors.figmaYellow
                                        : AppColors.figmaCyan))
                      ]));
            }));
}

class RoomPlayersGrid extends StatelessWidget {
  const RoomPlayersGrid(
      {super.key,
      required this.players,
      required this.currentUid,
      required this.slotCount,
      this.inGame = false,
      this.speakers = const {},
      this.onPlayerTap});
  final List<RoomPlayerEntity> players;
  final String? currentUid;
  final int slotCount;
  final bool inGame;
  final Set<String> speakers;
  final ValueChanged<RoomPlayerEntity>? onPlayerTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final tileWidth = (size.maxWidth - 24) / 3;
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final extent = math.max(
            tileWidth * 1.25, math.min(tileWidth * .74, 88) + 24 + 34 * scale);
        final bySlot = {for (final player in players) player.slotIndex: player};
        final sorted = [...players]
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        return GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: extent),
            itemCount: inGame ? sorted.length : slotCount,
            itemBuilder: (_, index) {
              final player = inGame ? sorted[index] : bySlot[index];
              return RoomPlayerTile(
                  key: ValueKey(player?.userId ?? 'slot_$index'),
                  player: player,
                  slot: index,
                  isMe: player?.userId == currentUid,
                  inGame: inGame,
                  speaking: speakers.contains(player?.userId),
                  onTap: player == null || onPlayerTap == null
                      ? null
                      : () => onPlayerTap!(player));
            });
      });
}
