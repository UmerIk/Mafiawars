// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/design/app_surface.dart';

class DashboardRoomCard extends StatelessWidget {
  const DashboardRoomCard(
      {super.key,
      required this.title,
      required this.artwork,
      required this.onTap,
      this.artworkOnRight = false,
      this.child,
      this.subtitle = 'Enter a 6 digit code to join'});
  final String title, artwork, subtitle;
  final bool artworkOnRight;
  final VoidCallback? onTap;
  final Widget? child;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final artworkWidth = (constraints.maxWidth * .34).clamp(80.0, 130.0);
        final titleSize = (constraints.maxWidth / 380 * 23).clamp(18.0, 23.0);
        final artworkWidget = Image.asset(artwork,
            width: artworkWidth,
            height: child == null ? artworkWidth * 96 / 139 : artworkWidth,
            fit: BoxFit.contain,
            excludeFromSemantics: true);
        return AppSurface(
            onTap: onTap,
            radius: 20,
            child: Row(children: [
              if (!artworkOnRight) artworkWidget,
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(title,
                                style: AppTypography.uiTitle
                                    .copyWith(fontSize: titleSize),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 5),
                            Text(subtitle,
                                style: AppTypography.uiCaption,
                                textAlign: TextAlign.center),
                            if (child != null) ...[
                              const SizedBox(height: 10),
                              child!
                            ],
                          ]))),
              if (artworkOnRight) artworkWidget,
            ]));
      });
}
