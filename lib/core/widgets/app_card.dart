import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Reusable card component for the Mafia-Wars design system.
/// Supports selection highlight, glowing effects, and customizable padding.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool hasGlow;
  final Color? glowColor;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.hasGlow = false,
    this.glowColor,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.neonCrimson;
    final effectiveBorder = border ??
        (isSelected
            ? BorderSide(color: effectiveGlowColor, width: 2)
            : const BorderSide(color: AppColors.border, width: 1));

    List<BoxShadow> shadows = AppShadows.subtleCard;
    if (hasGlow || isSelected) {
      shadows = [
        BoxShadow(
          color: effectiveGlowColor.withOpacity(0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding ?? AppSpacing.paddingL,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isSelected ? AppColors.surfaceElevated : AppColors.surface),
        borderRadius: AppRadii.radiusL,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusL,
        child: content,
      );
    }

    return content;
  }
}
