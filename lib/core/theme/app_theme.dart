import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_radii.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Central theme provider for the Mafia-Wars Flutter Design System.
class AppTheme {
  AppTheme._();

  // Backward compatibility alias constants
  static const Color obsidianBlack = AppColors.obsidianBlack;
  static const Color darkSlate = AppColors.darkSlate;
  static const Color bloodRed = AppColors.bloodRed;
  static const Color neonCrimson = AppColors.neonCrimson;
  static const Color silverMist = AppColors.silverMist;
  static const Color pureWhite = AppColors.pureWhite;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        shape: AppRadii.shapeL,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCrimson,
          foregroundColor: AppColors.pureWhite,
          shape: AppRadii.shapeM,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.m,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.obsidianBlack,
        border: OutlineInputBorder(
          borderRadius: AppRadii.radiusM,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusM,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusM,
          borderSide: BorderSide(color: AppColors.neonCrimson, width: 1.5),
        ),
      ),
    );
  }
}
