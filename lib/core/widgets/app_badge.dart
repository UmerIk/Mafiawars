import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppBadgeVariant { primary, secondary, success, warning, danger, ghost, public }

/// Reusable badge / chip component for the Mafia-Wars design system.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final Color? customColor;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.primary,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor = AppColors.pureWhite;

    if (customColor != null) {
      badgeColor = customColor!;
    } else {
      switch (variant) {
        case AppBadgeVariant.primary:
          badgeColor = AppColors.neonCrimson;
          break;
        case AppBadgeVariant.secondary:
          badgeColor = AppColors.darkSlate;
          textColor = AppColors.silverMist;
          break;
        case AppBadgeVariant.success:
          badgeColor = AppColors.success;
          break;
        case AppBadgeVariant.warning:
          badgeColor = AppColors.warning;
          textColor = AppColors.obsidianBlack;
          break;
        case AppBadgeVariant.danger:
          badgeColor = AppColors.bloodRed;
          break;
        case AppBadgeVariant.ghost:
          badgeColor = AppColors.ghostPurple;
          break;
        case AppBadgeVariant.public:
          badgeColor = AppColors.publicBlue;
          textColor = AppColors.obsidianBlack;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: AppRadii.radiusS,
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: badgeColor),
            AppSpacing.gapXs,
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: textColor == AppColors.pureWhite ? badgeColor : textColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
