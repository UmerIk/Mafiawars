// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';

/// The same panel hosts targeting, waiting, and sunrise outcome states.
class PhaseActionPanel extends StatelessWidget {
  const PhaseActionPanel(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.seconds,
      required this.child,
      this.footer,
      this.showTimer = true});
  final String title, subtitle;
  final Color color;
  final int seconds;
  final bool showTimer;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 20,
      gradient: AppGradients.phasePanel,
      borderGradient: LinearGradient(colors: [color, color]),
      child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 28),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                style: AppTypography.uiTitle,
                                textAlign: TextAlign.center),
                            Text(subtitle,
                                style:
                                    AppTypography.uiBody.copyWith(fontSize: 14),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 38),
                            child,
                            if (showTimer) ...[
                              const SizedBox(height: 38),
                              Text(
                                  seconds > 0
                                      ? '${seconds}s'
                                      : 'Awaiting next phase…',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.uiTitle.copyWith(
                                      fontSize: seconds > 0 ? 42 : 18,
                                      color: color)),
                            ],
                            if (footer != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: footer),
                          ]))))));
}
