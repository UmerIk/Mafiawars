// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';

class GamePhaseHeader extends StatelessWidget {
  const GamePhaseHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.seconds,
      required this.gradient,
      required this.icon,
      this.onAdvance,
      this.clockFormat = false});
  final String title, subtitle;
  final bool clockFormat;
  final int seconds;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback? onAdvance;
  @override
  Widget build(BuildContext context) {
    final clock = seconds >= 60 || clockFormat
        ? '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '${seconds}s';
    final timer = Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Next phase in',
          style: AppTypography.uiCaption.copyWith(fontSize: 10)),
      Text(clock,
          style: AppTypography.uiTitle.copyWith(fontSize: 28, height: 1.2))
    ]);
    final menu = onAdvance == null
        ? const SizedBox.shrink()
        : PopupMenuButton<String>(
            tooltip: 'Host controls',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 18,
            icon: const Icon(Icons.more_vert, color: AppColors.figmaWhite),
            onSelected: (_) => onAdvance!(),
            itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'advance', child: Text('Advance phase (host)'))
                ]);
    return AppSurface(
        radius: 20,
        gradient: gradient,
        borderWidth: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: LayoutBuilder(builder: (context, size) {
          final heading = Text(title,
              textAlign: TextAlign.center,
              style: AppTypography.uiTitle.copyWith(fontSize: 20, height: 1.2));
          final caption = Text(subtitle,
              textAlign: TextAlign.center,
              style:
                  AppTypography.uiCaption.copyWith(fontSize: 10, height: 1.2));
          if (size.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              heading,
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: caption),
                const SizedBox(width: 12),
                timer,
                menu
              ])
            ]);
          }
          return Row(children: [
            Icon(icon,
                color: icon == Icons.wb_sunny_rounded
                    ? AppColors.figmaYellow
                    : AppColors.figmaWhite,
                size: 30),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [heading, caption])),
            const SizedBox(width: 10),
            timer,
            menu
          ]);
        }));
  }
}
