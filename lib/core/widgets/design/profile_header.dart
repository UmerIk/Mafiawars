// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_typography.dart';
import 'agent_avatar.dart';
import 'app_surface.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader(
      {super.key,
      required this.name,
      required this.avatar,
      required this.onEdit,
      this.subtitle});
  final String name, avatar;
  final String? subtitle;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 32,
      gradient: AppGradients.profile,
      padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
      onTap: onEdit,
      child: Row(children: [
        AgentAvatar(value: avatar, size: 56),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.uiTitle.copyWith(fontSize: 24)),
          if (subtitle != null) Text(subtitle!, style: AppTypography.uiCaption)
        ])),
        IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 28)),
      ]));
}
