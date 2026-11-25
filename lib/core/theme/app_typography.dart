import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design tokens for typography in the Mafia-Wars design system.
class AppTypography {
  AppTypography._();

  // Bundled Inter makes the Figma UI deterministic and available offline.
  static const TextStyle uiTitle = TextStyle(
      fontFamily: 'MafiaInter',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.figmaWhite);
  static const TextStyle uiBody = TextStyle(
      fontFamily: 'MafiaInter', fontSize: 16, color: AppColors.figmaWhite);
  static const TextStyle uiCaption = TextStyle(
      fontFamily: 'MafiaInter', fontSize: 12, color: AppColors.figmaWhite);

  // --- Display & Headers (Cinzel) ---
  static TextStyle displayLarge = GoogleFonts.cinzel(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.cinzel(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle titleLarge = GoogleFonts.cinzel(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
  );

  static TextStyle titleMedium = GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle titleSmall = GoogleFonts.cinzel(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // --- Body & Content (Inter) ---
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // --- UI Components ---
  static TextStyle button = GoogleFonts.cinzel(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
    letterSpacing: 1.5,
  );
}
