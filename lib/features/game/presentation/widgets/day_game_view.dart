// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../../audio/providers/audio_providers.dart';
import '../../domain/entities/game_room_entity.dart';
import '../providers/day_game_provider.dart';
import '../providers/game_providers.dart';
import 'day_players_board.dart';
import 'game_floating_controls.dart';
import 'game_phase_header.dart';
import 'phase_action_panel.dart';
import 'player_state_avatar.dart';

class DayGameView extends ConsumerWidget {
  const DayGameView(
      {super.key,
      required this.room,
      required this.players,
      required this.votes,
      required this.currentUid,
      required this.speakers,
      required this.seconds,
      required this.onLeave,
      required this.onChat,
      required this.onRetryPlayers,
      this.onPlayerTap,
      this.onAdvance,
      this.unreadCount = 0,
      this.decision,
      this.onDismissDecision,
      this.actionFailed = false});
  final bool actionFailed;
  final GameRoomEntity room;
  final AsyncValue<List<RoomPlayerEntity>> players;
  final AsyncValue<Map<String, String>> votes;
  final String? currentUid;
  final Set<String> speakers;
  final int seconds, unreadCount;
  final VoidCallback onLeave, onChat, onRetryPlayers;
  final VoidCallback? onAdvance, onDismissDecision;
  final ValueChanged<RoomPlayerEntity>? onPlayerTap;
  final VoteDecision? decision;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voting = room.phase == GamePhase.dayVoting || decision != null;
    final data = players.valueOrNull ?? [];
    final actor = data.where((p) => p.userId == currentUid).firstOrNull;
    final state = ref.watch(dayActionProvider(
        (roomId: room.roomId, phase: room.phase, deadline: room.phaseEndTime)));
    final narration = ref.watch(currentNarrationTextProvider).valueOrNull;
    final ready = actor?.isAlive == true && seconds > 0 && !state.isLoading;
    final controller = ref.read(dayActionProvider((
      roomId: room.roomId,
      phase: room.phase,
      deadline: room.phaseEndTime
    )).notifier);
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(30, 76, 30, 30),
        backgroundOverlay: actor?.isAlive == false
            ? const DecoratedBox(
                decoration:
                    BoxDecoration(gradient: AppGradients.eliminatedVignette))
            : null,
        child: Stack(children: [
          Column(children: [
            GamePhaseHeader(
                title: voting ? 'Final Vote' : 'Agent Discussion',
                subtitle: voting
                    ? 'Players vote to eliminate a suspect'
                    : 'Agents discuss and share suspicions',
                seconds: seconds,
                clockFormat: true,
                gradient:
                    voting ? AppGradients.finalVote : AppGradients.discussion,
                icon: Icons.wb_sunny_rounded,
                onAdvance: onAdvance),
            const SizedBox(height: 24),
            Expanded(
                child: players.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => AsyncFeedback(
                        message: 'Could not load agents.',
                        onRetry: onRetryPlayers),
                    data: (data) => voting
                        ? Stack(fit: StackFit.expand, children: [
                            Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                    height: 140,
                                    child: ExcludeSemantics(
                                        child: AbsorbPointer(
                                            child: DayPlayersBoard(
                                                players: data,
                                                currentUid: currentUid,
                                                speakers: speakers))))),
                            Padding(
                                padding:
                                    const EdgeInsets.only(top: 36, bottom: 40),
                                child: PhaseActionPanel(
                                  title: decision != null
                                      ? 'Final Decision'
                                      : 'Final Vote',
                                  subtitle: decision != null
                                      ? 'The published vote result'
                                      : 'Players vote to eliminate a suspect',
                                  color: AppColors.figmaYellow,
                                  seconds: seconds,
                                  showTimer: decision == null,
                                  child: decision != null
                                      ? VoteDecisionBody(
                                          decision: decision!, players: data)
                                      : votes.when(
                                          loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          error: (_, __) => AsyncFeedback(
                                              message:
                                                  'Votes could not be loaded.',
                                              onRetry: () => ref.invalidate(
                                                  roomVotesStreamProvider(
                                                      room.roomId))),
                                          data: (votes) => _targets(
                                              context,
                                              data,
                                              votes,
                                              actor,
                                              state,
                                              controller)),
                                )),
                            if (decision != null)
                              Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppColors.figmaWhite),
                                      onPressed: onDismissDecision,
                                      child: const Text('Continue to game'))),
                          ])
                        : DayPlayersBoard(
                            players: data,
                            currentUid: currentUid,
                            speakers: speakers,
                            onPlayerTap: onPlayerTap))),
            if (actionFailed)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('The room action failed. Please try again.',
                      style: AppTypography.uiCaption)),
            if (!voting) ...[
              if (narration != null && narration.isNotEmpty)
                Text(narration,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.uiCaption),
              if (state.hasError)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Could not update readiness. Please try again.',
                        style: AppTypography.uiCaption)),
              if (actor?.isAlive == true)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: AppButton(
                        text:
                            '${room.readyToVoteUserIds.contains(currentUid) ? 'Cancel readiness' : 'Ready to vote'} (${room.readyToVoteUserIds.length}/${data.where((p) => p.isAlive).length})',
                        isFullWidth: true,
                        compact: true,
                        variant: AppButtonVariant.secondary,
                        isLoading: state.isLoading,
                        icon: Icons.how_to_vote,
                        onPressed: ready ? controller.ready : null)),
            ],
            if (actor?.isAlive == false)
              const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text('You are out. Watch the game and use Ghost chat.',
                      textAlign: TextAlign.center,
                      style: AppTypography.uiCaption)),
            GameFloatingControls(
                roomId: room.roomId,
                playerCount: data.length,
                isAlive: actor?.isAlive == true,
                onLeave: onLeave,
                onChat: onChat,
                unreadCount: unreadCount)
          ]),
        ]));
  }

  Widget _targets(
      BuildContext context,
      List<RoomPlayerEntity> data,
      Map<String, String> votes,
      RoomPlayerEntity? actor,
      AsyncValue<String?> state,
      DayActionController controller) {
    final canVote = actor?.isAlive == true && seconds > 0 && !state.isLoading;
    final selected = state.valueOrNull ?? votes[currentUid];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (actor?.isAlive != true)
        const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Voting is read only for eliminated agents.',
                style: AppTypography.uiCaption, textAlign: TextAlign.center)),
      LayoutBuilder(builder: (context, size) {
        final columns = size.maxWidth < 250 ||
                MediaQuery.textScalerOf(context).scale(16) > 22
            ? 1
            : 2;
        final width = (size.maxWidth - (columns - 1) * 12) / columns;
        final sorted = [...data]..sort((a, b) => a.isAlive == b.isAlive
            ? a.slotIndex.compareTo(b.slotIndex)
            : a.isAlive
                ? -1
                : 1);
        return Wrap(spacing: 12, runSpacing: 10, children: [
          for (final target in sorted)
            SizedBox(
                width: width,
                child: AgentChip(
                    key: ValueKey('vote_${target.userId}'),
                    name: target.userId == currentUid
                        ? 'You'
                        : target.displayName,
                    avatar: target.avatarUrl,
                    avatarSize: 48,
                    fontSize: 16,
                    color: AppColors.figmaYellow,
                    borderGradient: AppGradients.rimLight,
                    selected: selected == target.userId,
                    enabled: canVote &&
                        target.isAlive &&
                        target.userId != currentUid,
                    voters: [
                      for (final voter in data)
                        if (votes[voter.userId] == target.userId)
                          voter.avatarUrl
                    ],
                    onTap: () => controller.vote(target.userId)))
        ]);
      }),
      if (state.isLoading)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: CircularProgressIndicator()),
      if (state.hasError)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Your vote could not be saved. Tap an agent to retry.',
                style: AppTypography.uiCaption)),
      if (selected != null && !state.hasError)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Vote submitted.', style: AppTypography.uiCaption)),
    ]);
  }
}

class VoteDecisionBody extends StatelessWidget {
  const VoteDecisionBody(
      {super.key, required this.decision, required this.players});
  final VoteDecision decision;
  final List<RoomPlayerEntity> players;
  @override
  Widget build(BuildContext context) {
    final target =
        players.where((p) => p.userId == decision.playerId).firstOrNull;
    if (decision.playerId == null) {
      return const Text('No agent was eliminated in this vote.',
          textAlign: TextAlign.center, style: AppTypography.uiBody);
    }
    if (target == null) {
      return const Text(
          'An agent was eliminated. Their profile is unavailable.',
          textAlign: TextAlign.center,
          style: AppTypography.uiBody);
    }
    final voters = players
        .where((p) => decision.voters[p.userId] == target.userId)
        .toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      PlayerStateAvatar(
          player:
              target.copyWith(isAlive: false, eliminationType: 'eliminated'),
          size: 100),
      const SizedBox(height: 12),
      Text(target.displayName,
          style: AppTypography.uiTitle.copyWith(color: AppColors.neonCrimson)),
      const SizedBox(height: 12),
      Text(
          decision.count == 0
              ? 'Has been eliminated by vote. Vote totals are unavailable.'
              : 'Has been eliminated due to ${decision.count} votes against them',
          textAlign: TextAlign.center,
          style: AppTypography.uiBody),
      if (voters.isNotEmpty) ...[
        const SizedBox(height: 32),
        Text('Voted against them',
            style: AppTypography.uiBody.copyWith(
                color: AppColors.figmaPink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final voter in voters)
                SizedBox(
                    width: 54,
                    child: Column(children: [
                      AgentAvatar(value: voter.avatarUrl, size: 46),
                      const SizedBox(height: 4),
                      Text(voter.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.uiCaption.copyWith(fontSize: 10))
                    ]))
            ])
      ]
    ]);
  }
}
