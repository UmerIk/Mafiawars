// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';

/// Shared friend identity used by the inbox and conversation picker.
class ChatContactRow extends StatelessWidget {
  const ChatContactRow(
      {super.key,
      required this.name,
      required this.avatar,
      required this.online,
      required this.onTap,
      this.preview,
      this.sender,
      this.outlined = true});
  final String name, avatar;
  final bool online, outlined;
  final VoidCallback onTap;
  final String? preview, sender;
  @override
  Widget build(BuildContext context) {
    final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          AgentAvatar(value: avatar, size: 50, online: online),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.uiTitle),
                if (preview != null)
                  Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '${sender ?? ''}: ',
                            style: const TextStyle(
                                color: AppColors.figmaCyan,
                                fontWeight: FontWeight.w700)),
                        TextSpan(text: preview)
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.uiBody.copyWith(fontSize: 14))
              ]))
        ]));
    return outlined
        ? AppSurface(onTap: onTap, radius: 20, child: content)
        : InkWell(onTap: onTap, child: content);
  }
}
