import 'package:flutter/material.dart';

/// Design tokens for colors in the Mafia-Wars Figma design system.
class AppColors {
  AppColors._();

  // --- Core Palette ---
  static const Color obsidianBlack = Color(0xFF0B0C10);
  static const Color darkSlate = Color(0xFF1F2833);
  static const Color bloodRed = Color(0xFFC70039);
  static const Color neonCrimson = Color(0xFFFF1E56);
  static const Color silverMist = Color(0xFFC5C6C7);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color ghostPurple = Color(0xFFAB47BC);
  static const Color publicBlue = Color(0xFF4FC3F7);

  // --- Figma Noir Design Tokens ---
  static const Color figmaWhite = Color(0xFFFEF0E6);
  static const Color figmaBurgundy = Color(0xFF43275A);
  static const Color figmaTextFieldBg = Color(0xFF301C40);
  static const Color figmaCyan = Color(0xFF7DD6FC);
  static const Color figmaBlue = Color(0xFF689EEA);
  static const Color figmaPink = Color(0xFFED77ED);
  static const Color figmaDisabledBg = Color(0xFF44395E);
  static const Color figmaDisabledFg = Color(0xFF4F5D70);
  static const Color figmaGreen = Color(0xFF34C759);

  // Additional named swatches from the Figma component palette.
  static const Color figmaPaletteGreen = Color(0xFF54CC54);
  static const Color figmaYellow = Color(0xFFFFCC33);
  static const Color figmaPurple = Color(0xFF44398D);
  static const Color figmaSecondaryBurgundy = Color(0x8043275A);

  // --- Semantic Tokens ---
  static const Color background = obsidianBlack;
  static const Color surface = darkSlate;
  static const Color surfaceElevated = Color(0xFF2B3746);
  static const Color surfaceLight = Color(0xFF354458);

  static const Color primary = neonCrimson;
  static const Color primaryDark = bloodRed;
  static const Color secondary = bloodRed;
  static const Color accent = neonCrimson;

  static const Color onPrimary = pureWhite;
  static const Color onSurface = silverMist;
  static const Color onSurfaceHighlight = pureWhite;

  static const Color textPrimary = pureWhite;
  static const Color textSecondary = silverMist;
  static const Color textMuted = Color(0xFF7A8B9E);
  static const Color textDisabled = figmaDisabledFg;

  static const Color border = Color(0xFF2C3848);
  static const Color borderFocus = neonCrimson;

  static const Color error = Color(0xFFFF3344);
  static const Color success = figmaGreen;
  static const Color warning = Color(0xFFFFC107);
  static const Color info = publicBlue;

  // Channel Specific Colors
  static const Color mafiaChannel = neonCrimson;
  static const Color ghostChannel = ghostPurple;
  static const Color publicChannel = publicBlue;
}
