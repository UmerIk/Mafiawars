// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Named fills and strokes from the Figma Components library.
abstract final class AppGradients {
  static const button = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.figmaCyan, AppColors.figmaPink],
  );
  static const neon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.figmaCyan, AppColors.figmaPink],
  );
  static const burgundy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC43275A), Color(0xCC301C40)],
  );
  static const profile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x99689EEA), Color(0xCC43275A)],
  );
  static const rimLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEF0E6), Color(0x00FEF0E6)],
  );
  static const splash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF301C40), Color(0xFF220E34)],
  );
}
