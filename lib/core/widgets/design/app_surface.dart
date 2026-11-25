// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_effects.dart';

/// Translucent panel with an independent gradient stroke (no opaque border fill).
class AppSurface extends StatelessWidget {
  const AppSurface(
      {super.key,
      required this.child,
      this.radius = 15,
      this.padding = EdgeInsets.zero,
      this.gradient = AppGradients.burgundy,
      this.borderGradient = AppGradients.neon,
      this.shadows = AppEffects.button,
      this.onTap,
      this.borderWidth = 1});
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;
  final Gradient borderGradient;
  final List<BoxShadow> shadows;
  final VoidCallback? onTap;
  final double borderWidth;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius), boxShadow: shadows),
        child: CustomPaint(
          foregroundPainter:
              _GradientStroke(borderGradient, radius, borderWidth),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gradient),
                  child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(radius),
                          child: Padding(padding: padding, child: child))))),
        ),
      );
}

class _GradientStroke extends CustomPainter {
  const _GradientStroke(this.gradient, this.radius, this.width);
  final Gradient gradient;
  final double radius;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..shader = gradient.createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(_GradientStroke old) =>
      old.gradient != gradient || old.radius != radius || old.width != width;
}
