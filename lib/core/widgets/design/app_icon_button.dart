// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import 'app_surface.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.size = 60,
      this.child});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: label,
      child: Semantics(
          button: true,
          label: label,
          enabled: onPressed != null,
          child: SizedBox(
              width: size,
              height: size,
              child: AppSurface(
                  radius: 15,
                  gradient: AppGradients.profile,
                  onTap: onPressed,
                  child: Center(
                      child: child ??
                          Icon(icon,
                              size: size * .45,
                              color: AppColors.figmaWhite))))));
}
