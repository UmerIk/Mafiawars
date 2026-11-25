// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'app_surface.dart';

/// Shared floating action tray; features provide their actions and state.
class AppFloatingControls extends StatelessWidget {
  const AppFloatingControls({super.key, required this.actions});
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 32,
      padding: const EdgeInsets.all(8),
      child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: actions));
}
