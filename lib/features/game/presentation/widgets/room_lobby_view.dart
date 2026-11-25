// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';
import 'room_player_tile.dart';

class RoomLobbyView extends StatelessWidget {
  const RoomLobbyView(
      {super.key,
      required this.room,
      required this.players,
      required this.currentUid,
      required this.action,
      required this.onLeave,
      required this.onCopy,
      required this.onInvite,
      required this.onChat,
      required this.onStart,
      required this.onReady,
      required this.onRetry,
      required this.onPlayerTap,
      this.unreadCount = 0});
  final GameRoomEntity room;
  final AsyncValue<List<RoomPlayerEntity>> players;
  final String? currentUid;
  final AsyncValue<void> action;
  final VoidCallback onLeave,
      onCopy,
      onInvite,
      onChat,
      onStart,
      onReady,
      onRetry;
  final ValueChanged<RoomPlayerEntity> onPlayerTap;
  final int unreadCount;
  @override
  Widget build(BuildContext context) {
    final data = players.valueOrNull ?? [];
    final isHost = room.hostId == currentUid;
    final mine =
        data.where((player) => player.userId == currentUid).firstOrNull;
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(30, 76, 30, 34),
        child: Column(children: [
          RoomCodePanel(
              code: room.code,
              count: data.length,
              capacity: room.maxPlayers,
              onCopy: onCopy),
          const SizedBox(height: 10),
          Row(children: [
            AppIconButton(
                icon: Icons.arrow_back,
                label: 'Leave room',
                onPressed: onLeave),
            const SizedBox(width: 10),
            Expanded(
                child: AppButton(
                    text: MediaQuery.sizeOf(context).width < 380
                        ? 'Invite'
                        : 'Invite Friends',
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    variant: AppButtonVariant.secondary,
                    icon: Icons.mark_email_unread_rounded,
                    onPressed: onInvite)),
            const SizedBox(width: 10),
            AppIconButton(
                icon: Icons.chat_bubble_rounded,
                label:
                    'Game chat${unreadCount > 0 ? ', $unreadCount unread' : ''}',
                onPressed: onChat,
                child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.chat_bubble_rounded,
                        color: AppColors.figmaWhite, size: 30)))
          ]),
          const SizedBox(height: 20),
          Expanded(
              child: players.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => AsyncFeedback(
                      message: 'Could not load the room agents.',
                      onRetry: onRetry),
                  data: (data) => RoomPlayersGrid(
                      players: data,
                      currentUid: currentUid,
                      slotCount: room.maxPlayers,
                      onPlayerTap: onPlayerTap))),
          if (action.hasError)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Could not update the room. Please try again.',
                    style: AppTypography.uiCaption)),
          if (isHost && data.length < 5 && !players.isLoading)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('At least 5 agents are needed to start.',
                    style: AppTypography.uiCaption)),
          const SizedBox(height: 12),
          AppButton(
              text: isHost
                  ? 'Start Game'
                  : mine?.isReady == true
                      ? 'Mark As Not Ready'
                      : 'Mark As Ready',
              icon: isHost ? null : Icons.check_circle_outline,
              isFullWidth: true,
              variant: isHost
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              isLoading: action.isLoading,
              onPressed: action.isLoading ||
                      players.hasError ||
                      players.isLoading ||
                      (isHost ? data.length < 5 : mine == null)
                  ? null
                  : isHost
                      ? onStart
                      : onReady)
        ]));
  }
}

class RoomCodePanel extends StatelessWidget {
  const RoomCodePanel(
      {super.key,
      required this.code,
      required this.count,
      required this.capacity,
      required this.onCopy});
  final String code;
  final int count, capacity;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 20,
      borderWidth: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Room Code',
              style: AppTypography.uiCaption
                  .copyWith(fontSize: 10, color: AppColors.figmaPink)),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(code,
                  style: AppTypography.uiTitle
                      .copyWith(fontSize: 30, color: AppColors.neonCrimson)))
        ])),
        IconButton(
            tooltip: 'Copy room code',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, color: AppColors.figmaWhite)),
        Container(
            height: 36,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.figmaPurple),
        Column(children: [
          Text('$count/$capacity',
              style: AppTypography.uiBody.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.figmaPink)),
          Text('Agents',
              style: AppTypography.uiCaption
                  .copyWith(fontSize: 10, color: AppColors.figmaPink))
        ])
      ]));
}
