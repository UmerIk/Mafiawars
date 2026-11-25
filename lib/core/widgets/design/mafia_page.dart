// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../design/app_assets.dart';
import '../../theme/app_colors.dart';

/// Phone-width content stays readable on tablets; short screens can scroll.
/// Artwork fills the screen while layout respects system/keyboard insets.
class MafiaPage extends StatelessWidget {
  const MafiaPage(
      {super.key,
      required this.child,
      this.scrollable = true,
      this.padding = const EdgeInsets.fromLTRB(30, 80, 30, 32),
      this.background = true,
      this.backgroundOverlay});
  final Widget child;
  final bool scrollable;
  final EdgeInsets padding;
  final bool background;
  final Widget? backgroundOverlay;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.figmaTextFieldBg,
        body: Stack(fit: StackFit.expand, children: [
          if (background)
            Image.asset(AppAssets.background,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true),
          if (backgroundOverlay != null)
            IgnorePointer(child: backgroundOverlay!),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final scale = (constraints.maxWidth / 440).clamp(.8, 1.15);
            final content = Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 506),
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            padding.left * scale,
                            padding.top * scale,
                            padding.right * scale,
                            padding.bottom * scale),
                        child: child)));
            return scrollable
                ? SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: content)
                : content;
          })),
        ]),
      );
}
