// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../app_button.dart';
import 'agent_avatar.dart';
import 'app_surface.dart';

class AgentNetworkRow extends StatelessWidget {
  const AgentNetworkRow(
      {super.key,
      required this.name,
      required this.avatar,
      required this.action,
      this.onAction,
      this.onProfile,
      this.subtitle,
      this.online,
      this.busy = false,
      this.icon});
  final String name, avatar, action;
  final String? subtitle;
  final bool? online;
  final bool busy;
  final VoidCallback? onAction, onProfile;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Expanded(
            child: InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(12),
                child: Row(children: [
                  AgentAvatar(value: avatar, size: 48, online: online),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.uiTitle.copyWith(fontSize: 20)),
                        if (subtitle != null)
                          Text(subtitle!, style: AppTypography.uiCaption)
                      ]))
                ]))),
        const SizedBox(width: 8),
        AppButton(
            text: action,
            icon: icon,
            onPressed: onAction,
            isLoading: busy,
            variant: AppButtonVariant.secondary,
            compact: true),
      ]));
}
