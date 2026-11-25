// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_typography.dart';
import 'app_surface.dart';

class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl(
      {super.key,
      required this.labels,
      required this.selectedIndex,
      required this.onSelected,
      this.icons});
  final List<String> labels;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: Row(
          children: List.generate(
              labels.length,
              (index) => Expanded(
                  child: Semantics(
                      selected: selectedIndex == index,
                      button: true,
                      child: InkWell(
                          onTap: () => onSelected(index),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: selectedIndex == index
                                      ? AppGradients.button
                                      : null),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 14),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (icons != null) ...[
                                      Icon(icons![index], size: 18),
                                      const SizedBox(width: 6)
                                    ],
                                    Flexible(
                                        child: Text(labels[index],
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.uiCaption)),
                                  ]))))))));
}
