// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';

/// Shared elevation, glow, and inset shading for the Figma component family.
abstract final class AppEffects {
  static const button = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const glow = <BoxShadow>[
    BoxShadow(color: Color(0x557DD6FC), blurRadius: 8),
    BoxShadow(color: Color(0x33ED77ED), blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const fieldInnerShadow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x50000000), Colors.transparent],
    stops: [0, 0.25],
  );
}
