// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../domain/entities/game_room_entity.dart';

class SunriseOutcome {
  const SunriseOutcome(
      {required this.title,
      required this.detail,
      required this.artwork,
      required this.color,
      this.success,
      this.player});
  final String title, detail;
  final String artwork;
  final Color color;
  final bool? success;
  final RoomPlayerEntity? player;
}

/// Legacy night facts have only a summary. Recognize the published templates;
/// unknown summaries remain plain text rather than inventing individual outcomes.
List<SunriseOutcome> sunriseOutcomes(
    String? summary, List<RoomPlayerEntity> players) {
  if (summary == null) return [];
  final saved = RegExp(
          r'^Mafia tried to kill someone but doctor saved that person and detective has made a (right|wrong) guess$')
      .firstMatch(summary);
  final killed = RegExp(
          r'^Mafia killed (\S+) , doctor saved the wrong person and detective has made a (right|wrong) guess$')
      .firstMatch(summary);
  final victim = killed == null
      ? null
      : players.where((p) => p.userId == killed.group(1)).firstOrNull;
  if (saved == null && victim == null) return [];
  final detectiveRight = (saved?.group(1) ?? killed?.group(2)) == 'right';
  return [
    if (victim != null)
      SunriseOutcome(
          title: victim.displayName,
          detail: 'Has been killed by Mafia',
          artwork: '',
          color: AppColors.neonCrimson,
          player: victim)
    else
      const SunriseOutcome(
          title: 'Mafia',
          detail: 'Failed to kill an agent',
          artwork: AppAssets.actionKnife,
          color: AppColors.neonCrimson,
          success: false),
    SunriseOutcome(
        title: 'Doctor',
        detail: saved != null
            ? 'Saved the right agent'
            : 'Failed to save the agent',
        artwork: AppAssets.actionSyringe,
        color: AppColors.publicBlue,
        success: saved != null),
    SunriseOutcome(
        title: 'Detective',
        detail: detectiveRight
            ? 'Made the right deduction'
            : 'Did not identify a Mafia agent',
        artwork: AppAssets.actionSearch,
        color: AppColors.publicBlue,
        success: detectiveRight),
  ];
}

class SunriseOutcomeCard extends StatelessWidget {
  const SunriseOutcomeCard({super.key, required this.outcome});
  final SunriseOutcome outcome;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 20,
      borderGradient: outcome.player != null
          ? LinearGradient(colors: [outcome.color, outcome.color])
          : AppGradients.rimLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(children: [
        if (outcome.player != null)
          AgentAvatar(value: outcome.player!.avatarUrl, size: 48)
        else
          Image.asset(outcome.artwork,
              width: 32, height: 32, excludeFromSemantics: true),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(outcome.title,
              style: AppTypography.uiBody.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: outcome.color)),
          Text(outcome.detail, style: AppTypography.uiBody)
        ])),
        if (outcome.success != null)
          Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(outcome.success! ? Icons.check_circle : Icons.cancel,
                  semanticLabel:
                      outcome.success! ? 'Successful' : 'Unsuccessful',
                  color: outcome.success!
                      ? AppColors.figmaPaletteGreen
                      : AppColors.neonCrimson,
                  size: 24))
      ]));
}
