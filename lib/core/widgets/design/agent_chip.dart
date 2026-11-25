// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_typography.dart';
import 'agent_avatar.dart';
import 'app_surface.dart';

/// Shared targeting/voting chip. The owning feature controls selection/eligibility.
class AgentChip extends StatelessWidget {
  const AgentChip(
      {super.key,
      required this.name,
      required this.avatar,
      this.onTap,
      this.selected = false,
      this.enabled = true,
      this.color = AppColors.figmaPink,
      this.voters = const []});
  final String name, avatar;
  final VoidCallback? onTap;
  final bool selected, enabled;
  final Color color;
  final List<String> voters;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Opacity(
          opacity: enabled ? 1 : .45,
          child: AppSurface(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              onTap: enabled ? onTap : null,
              borderGradient: selected
                  ? LinearGradient(colors: [color, color])
                  : AppGradients.neon,
              borderWidth: selected ? 2 : 1,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AgentAvatar(value: avatar, size: 36),
                const SizedBox(width: 6),
                Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.uiCaption),
                      if (voters.isNotEmpty)
                        Wrap(
                            children: voters
                                .take(4)
                                .map((avatar) =>
                                    AgentAvatar(value: avatar, size: 16))
                                .toList())
                    ]))
              ]))));
}
