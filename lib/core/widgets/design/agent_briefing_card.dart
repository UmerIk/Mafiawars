// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_icon_button.dart';
import 'app_surface.dart';

typedef AgentRoleCount = ({String label, int count, Color color});

/// Figma front/back briefing presentation. State and timing belong to the game.
class AgentBriefingCard extends StatelessWidget {
  const AgentBriefingCard(
      {super.key,
      required this.revealed,
      required this.onFlip,
      required this.roleCard,
      required this.counts});
  final bool revealed;
  final VoidCallback onFlip;
  final Widget roleCard;
  final List<AgentRoleCount> counts;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
            alignment: Alignment.topRight,
            child: AppIconButton(
                icon: Icons.flip,
                label: revealed ? 'Hide secret role' : 'Reveal secret role',
                onPressed: onFlip,
                size: 44)),
        AnimatedSwitcher(
            duration:
                revealed ? const Duration(milliseconds: 220) : Duration.zero,
            child: revealed
                ? KeyedSubtree(key: const ValueKey('role'), child: roleCard)
                : Column(
                    key: const ValueKey('counts'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text(
                            counts
                                .fold<int>(
                                    0, (total, item) => total + item.count)
                                .toString()
                                .padLeft(2, '0'),
                            style: AppTypography.uiTitle.copyWith(
                                fontSize: 42, color: AppColors.figmaPink)),
                        const Text('Agents', style: AppTypography.uiBody),
                        const SizedBox(height: 20),
                        ...counts.map((item) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                                color: AppColors.figmaSecondaryBurgundy,
                                borderRadius: BorderRadius.circular(30)),
                            child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: '${item.count} ',
                                      style: TextStyle(
                                          color: item.color,
                                          fontWeight: FontWeight.w700)),
                                  TextSpan(text: item.label)
                                ]),
                                textAlign: TextAlign.center,
                                style: AppTypography.uiBody)))
                      ])),
      ]));
}
