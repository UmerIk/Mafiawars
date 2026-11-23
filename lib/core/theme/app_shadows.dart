import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design tokens for elevations and glowing shadow effects in the Mafia-Wars design system.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> subtleCard = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowingRed = [
    BoxShadow(
      color: AppColors.neonCrimson.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowingPurple = [
    BoxShadow(
      color: AppColors.ghostPurple.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowingBlue = [
    BoxShadow(
      color: AppColors.publicBlue.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}
