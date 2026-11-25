// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_surface.dart';

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .85,
              maxWidth: 520),
          child: AppSurface(
              radius: 32,
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                        color: AppColors.figmaPink,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 20),
                Text(title, style: AppTypography.uiTitle),
                const SizedBox(height: 24),
                Flexible(child: child),
              ]))));
}
