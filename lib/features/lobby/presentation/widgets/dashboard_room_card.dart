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
  Widget build(BuildContext context) => AppSurface(
      onTap: onTap,
      radius: 20,
      child: Row(children: [
        if (!artworkOnRight) _art(),
        Expanded(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(title,
                          style: AppTypography.uiTitle.copyWith(fontSize: 23),
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
        if (artworkOnRight) _art(),
      ]));
  Widget _art() => LayoutBuilder(
      builder: (context, constraints) => Image.asset(artwork,
          width: 130,
          height: child == null ? 100 : 130,
          fit: BoxFit.contain,
          excludeFromSemantics: true));
}
