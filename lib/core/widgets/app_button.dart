import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'design/app_surface.dart';

enum AppButtonVariant { primary, secondary, outlined, danger, success }

/// Figma button variants with optional leading/trailing content and busy states.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final bool compact;
  final double height;

  const AppButton(
      {super.key,
      required this.text,
      this.onPressed,
      this.variant = AppButtonVariant.primary,
      this.icon,
      this.leading,
      this.trailing,
      this.isLoading = false,
      this.isFullWidth = false,
      this.padding,
      this.compact = false,
      this.height = 60});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;
    final color = disabled ? AppColors.figmaDisabledFg : AppColors.figmaWhite;
    final gradient = disabled
        ? const LinearGradient(
            colors: [AppColors.figmaDisabledBg, AppColors.figmaDisabledBg])
        : switch (variant) {
            AppButtonVariant.primary => AppGradients.button,
            AppButtonVariant.danger =>
              const LinearGradient(colors: [AppColors.error, AppColors.error]),
            AppButtonVariant.success => const LinearGradient(colors: [
                AppColors.figmaPaletteGreen,
                AppColors.figmaPaletteGreen
              ]),
            AppButtonVariant.outlined => const LinearGradient(
                colors: [Colors.transparent, Colors.transparent]),
            AppButtonVariant.secondary => AppGradients.burgundy,
          };
    final content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null || icon != null) ...[
            leading ?? Icon(icon, size: compact ? 14 : 22, color: color),
            SizedBox(width: compact ? 4 : 10)
          ],
          Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.uiBody
                      .copyWith(color: color, fontSize: compact ? 12 : 16))),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]);
    return Semantics(
        button: true,
        enabled: onPressed != null && !isLoading,
        child: SizedBox(
            width: isFullWidth ? double.infinity : null,
            height: compact ? 40 : height,
            child: AppSurface(
                radius: compact ? 24 : 15,
                gradient: gradient,
                borderGradient: disabled
                    ? const LinearGradient(colors: [
                        AppColors.figmaDisabledFg,
                        AppColors.figmaDisabledFg
                      ])
                    : variant == AppButtonVariant.primary
                        ? AppGradients.rimLight
                        : AppGradients.neon,
                onTap: isLoading ? null : onPressed,
                padding: padding ??
                    EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
                child: Center(
                    widthFactor: isFullWidth ? null : 1,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.figmaWhite))
                        : content))));
  }
}
