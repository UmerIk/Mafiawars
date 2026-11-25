// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'app_surface.dart';

/// Presentation-only role card; role/team information is supplied by the feature.
class AgentRoleCard extends StatelessWidget {
  const AgentRoleCard(
      {super.key,
      required this.title,
      required this.artwork,
      required this.color,
      required this.mission,
      required this.victory,
      this.teammates = const []});
  final String title, artwork;
  final Color color;
  final List<String> mission, victory;
  final List<Widget> teammates;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(artwork,
            height: 210, fit: BoxFit.contain, excludeFromSemantics: true),
        AppSurface(
            radius: 16,
            borderGradient: LinearGradient(colors: [color, color]),
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppTypography.uiTitle
                          .copyWith(color: color, fontSize: 30)),
                  if (teammates.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Wrap(spacing: 8, children: teammates)),
                  const SizedBox(height: 12),
                  _bullets('Your mission', mission),
                  const SizedBox(height: 12),
                  _bullets('Victory condition', victory)
                ])),
      ]);
  Widget _bullets(String heading, List<String> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading,
            style: AppTypography.uiBody
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        ...items.map((text) => Text('• $text', style: AppTypography.uiCaption))
      ]);
}
