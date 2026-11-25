// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Named fills and strokes from the Figma Components library.
abstract final class AppGradients {
  static const discussion = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.figmaYellow, Color(0xFF114C97)]);
  static const finalVote = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFC75A), Color(0xFFD95600)]);
  static const eliminatedVignette = RadialGradient(
      radius: .8,
      colors: [Color(0x0043275A), Color(0xA8FF1E56)],
      stops: [.48, 1]);
  static const secretAttack = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA8414F), Color(0xFF190B5C)]);
  static const night = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3D6994), Color(0xFF191432)]);
  static const phasePanel = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF301C40), Color(0xFF43275A), Color(0xFF301C40)]);
  static const agentHighlight =
      LinearGradient(colors: [AppColors.publicBlue, AppColors.publicBlue]);
  static const briefing = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.publicBlue, Color(0xFF008BB4)]);
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
    colors: [Color(0x8043275A), Color(0x8043275A)],
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
