// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'app_icon_button.dart';

class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key, required this.onBack, this.title, this.trailing});
  final VoidCallback onBack;
  final String? title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        AppIconButton(icon: Icons.arrow_back, label: 'Back', onPressed: onBack),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(title ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.uiTitle))),
        trailing ?? const SizedBox(width: 60),
      ]);
}
