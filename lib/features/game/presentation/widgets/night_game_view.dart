// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../../audio/providers/audio_providers.dart';
import '../../domain/entities/game_room_entity.dart';
import '../providers/game_providers.dart';
import '../providers/night_action_provider.dart';
import 'game_floating_controls.dart';
import 'game_phase_header.dart';
import 'phase_action_panel.dart';
import 'room_player_tile.dart';
import 'sunrise_outcomes.dart';

/// One gameplay screen, driven by the existing phase and public room streams.
class NightGameView extends ConsumerWidget {
  const NightGameView(
      {super.key,
      required this.room,
      required this.players,
      required this.role,
      required this.actions,
      required this.currentUid,
      required this.speakers,
      required this.seconds,
      required this.onLeave,
      required this.onChat,
      required this.onRetryPlayers,
      this.onContinue,
      this.onAdvance,
      this.unreadCount = 0});
  final GameRoomEntity room;
  final AsyncValue<List<RoomPlayerEntity>> players;
  final AsyncValue<PlayerRoleEntity?> role;
  final AsyncValue<Map<String, String>> actions;
  final String? currentUid;
  final Set<String> speakers;
  final int seconds, unreadCount;
  final VoidCallback onLeave, onChat, onRetryPlayers;
  final VoidCallback? onContinue, onAdvance;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
        (roomId: room.roomId, phase: room.phase, deadline: room.phaseEndTime);
    final action = ref.watch(nightActionProvider(session));
    final sunrise = room.phase == GamePhase.dayDiscussion;
    final mafia = room.phase == GamePhase.nightMafia;
    final protection = room.phase == GamePhase.nightDoctor;
    final title = sunrise
        ? 'Sunrise Briefing'
        : mafia
            ? 'Secret Attack'
            : protection
                ? 'Agent Protection'
                : 'Investigation';
    final subtitle = sunrise
        ? 'Learn what happened during the night'
        : mafia
            ? 'Mafia chooses a player to kill'
            : protection
                ? 'Doctor chooses a player to save'
                : "Detective checks a player's identity";
    final color = mafia ? AppColors.neonCrimson : AppColors.publicBlue;
    final data = players.valueOrNull ?? [];
    final actor =
        data.where((player) => player.userId == currentUid).firstOrNull;
    final narration = ref.watch(currentNarrationTextProvider).valueOrNull;
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(20, 76, 20, 30),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GamePhaseHeader(
                  title: title,
                  subtitle: subtitle,
                  seconds: seconds,
                  clockFormat: sunrise,
                  gradient: sunrise
                      ? AppGradients.briefing
                      : mafia
                          ? AppGradients.secretAttack
                          : AppGradients.night,
                  icon:
                      sunrise ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  onAdvance: onAdvance)),
          const SizedBox(height: 24),
          Expanded(
              child: Stack(fit: StackFit.expand, children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                        height: 140,
                        child: ExcludeSemantics(
                            child: AbsorbPointer(
                                child: RoomPlayersGrid(
                                    players: data,
                                    currentUid: currentUid,
                                    slotCount: data.length,
                                    inGame: true,
                                    speakers: speakers)))))),
            Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 50),
                child: PhaseActionPanel(
                    title: title,
                    subtitle: sunrise
                        ? 'The night results are in'
                        : mafia
                            ? 'Select a player to kill secretly'
                            : subtitle,
                    color: color,
                    seconds: seconds,
                    footer: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (narration != null && narration.isNotEmpty)
                        Semantics(
                            liveRegion: true,
                            child: Text(narration,
                                textAlign: TextAlign.center,
                                style: AppTypography.uiCaption)),
                    ]),
                    child: players.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => AsyncFeedback(
                            message: 'Could not load agents.',
                            onRetry: onRetryPlayers),
                        data: (data) => sunrise
                            ? _sunrise(data)
                            : role.when(
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (_, __) => AsyncFeedback(
                                    message: 'Your role could not be loaded.',
                                    onRetry: () => ref.invalidate(
                                        myRoleStreamProvider(room.roomId))),
                                data: (role) => _targets(context, ref, session,
                                    data, actor, role?.role, action, color))))),
            if (sunrise && onContinue != null)
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: TextButton(
                      onPressed: onContinue,
                      child: const Text('Continue to discussion'))),
          ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GameFloatingControls(
                  roomId: room.roomId,
                  playerCount: data.length,
                  isAlive: actor?.isAlive == true,
                  onLeave: onLeave,
                  onChat: onChat,
                  unreadCount: unreadCount))
        ]));
  }

  Widget _targets(
      BuildContext context,
      WidgetRef ref,
      NightActionSession session,
      List<RoomPlayerEntity> data,
      RoomPlayerEntity? actor,
      PlayerRole? role,
      AsyncValue<String?> submission,
      Color color) {
    final eligible = data
        .where((target) => canChooseNightTarget(
            phase: room.phase, role: role, actor: actor, target: target))
        .toList();
    if (role == null) {
      return const AsyncFeedback(message: 'Waiting for your secret role…');
    }
    if (actor == null) {
      return const AsyncFeedback(message: 'Your agent is not in this room.');
    }
    if (!actor.isAlive) {
      return const AsyncFeedback(
          message: 'You are eliminated. Watch while the remaining agents act.');
    }
    if (eligible.isEmpty) {
      return AsyncFeedback(
          message:
              'Wait while the ${room.phase == GamePhase.nightMafia ? 'Mafia' : room.phase == GamePhase.nightDoctor ? 'Doctor' : 'Detective'} acts.');
    }
    return actions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AsyncFeedback(
            message: 'Selections could not be loaded.',
            onRetry: () =>
                ref.invalidate(roomActionsStreamProvider(room.roomId))),
        data: (actions) {
          final mine = room.phase == GamePhase.nightMafia
              ? actions['nightMafia_$currentUid']
              : actions[room.phase.name];
          final selected = submission.valueOrNull ?? mine;
          final mafiaTargets = role == PlayerRole.mafia &&
                  room.phase == GamePhase.nightMafia
              ? actions.entries
                  .where((e) =>
                      e.key.startsWith('nightMafia_') || e.key == 'nightMafia')
                  .map((e) => e.value)
                  .where((id) => id.isNotEmpty)
                  .toSet()
              : <String>{};
          return Column(mainAxisSize: MainAxisSize.min, children: [
            LayoutBuilder(builder: (context, size) {
              final narrow = size.maxWidth < 220 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22;
              final columns = narrow ? 1 : 2;
              final width = (size.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(spacing: 12, runSpacing: 10, children: [
                for (final target in eligible)
                  SizedBox(
                      width: width,
                      child: AgentChip(
                          key: ValueKey('target_${target.userId}'),
                          name: target.displayName,
                          avatar: target.avatarUrl,
                          avatarSize: narrow ? 44 : 56,
                          fontSize: 16,
                          color: color,
                          borderGradient: AppGradients.rimLight,
                          selected: selected == target.userId ||
                              mafiaTargets.contains(target.userId),
                          selectedMarker: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                              child: Center(
                                  child: Image.asset(
                                      room.phase == GamePhase.nightMafia
                                          ? AppAssets.actionKnife
                                          : room.phase == GamePhase.nightDoctor
                                              ? AppAssets.actionStethoscope
                                              : AppAssets.actionSearch,
                                      width: 14,
                                      height: 14,
                                      excludeFromSemantics: true))),
                          enabled: !submission.isLoading && seconds > 0,
                          onTap: () => ref
                              .read(nightActionProvider(session).notifier)
                              .submit(target.userId)))
              ]);
            }),
            if (submission.isLoading)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator()),
            if (submission.hasError)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                      'Selection could not be saved. Tap an agent to retry.',
                      style: AppTypography.uiCaption,
                      textAlign: TextAlign.center)),
            if (!submission.hasError && selected != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Selection submitted.',
                      style: AppTypography.uiCaption.copyWith(color: color))),
            if (role == PlayerRole.mafia && room.phase == GamePhase.nightMafia)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                      mafiaTargets.length > 1
                          ? 'Mafia selections differ. Coordinate on one target.'
                          : 'Coordinate with the other Mafia agents on one target.',
                      style: AppTypography.uiCaption.copyWith(color: color),
                      textAlign: TextAlign.center)),
          ]);
        });
  }

  Widget _sunrise(List<RoomPlayerEntity> data) {
    final summary = room.nightFacts?['summary'];
    final outcomes = sunriseOutcomes(summary, data);
    if (outcomes.isEmpty) {
      var text = summary ?? 'No night results were reported.';
      final byId = {
        for (final player in data) player.userId: player.displayName
      };
      final ids = byId.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      if (ids.isNotEmpty) {
        text = text.replaceAllMapped(RegExp(ids.map(RegExp.escape).join('|')),
            (match) => byId[match.group(0)]!);
      }
      return Text(text,
          style: AppTypography.uiBody, textAlign: TextAlign.center);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final outcome in outcomes)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SunriseOutcomeCard(outcome: outcome))
    ]);
  }
}
