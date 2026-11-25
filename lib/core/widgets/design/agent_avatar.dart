// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../design/app_assets.dart';
import '../../theme/app_colors.dart';

/// Renders the original 5×5 avatar atlas without resampling/exporting its cells.
/// Existing remote and asset-path profile values remain supported.
class AgentAvatar extends StatelessWidget {
  const AgentAvatar(
      {super.key,
      this.value = '',
      this.size = 56,
      this.online,
      this.selected = false,
      this.label});
  final String value;
  final double size;
  final bool? online;
  final bool selected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final index = AppAssets.avatarIndex(value);
    Widget image;
    if (index != null) {
      image = ClipRect(
          child: FittedBox(
              fit: BoxFit.none,
              alignment: Alignment((index % 5) / 2 - 1, (index ~/ 5) / 2 - 1),
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                  width: size * 5,
                  height: size * 5,
                  child: Image.asset(AppAssets.avatars, fit: BoxFit.fill))));
    } else if (value.startsWith('assets/')) {
      image = Image.asset(value,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    } else if (Uri.tryParse(value)?.scheme == 'https' &&
        !value.toLowerCase().contains('.svg')) {
      image = Image.network(value,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    } else {
      image = _fallback();
    }
    return Semantics(
        label: label,
        image: true,
        child: SizedBox(
            width: size,
            height: size,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.figmaSecondaryBurgundy,
                          border: selected
                              ? Border.all(color: AppColors.figmaCyan, width: 2)
                              : null),
                      child: Padding(
                          padding: EdgeInsets.all(selected ? 2 : 0),
                          child: image))),
              if (online != null)
                Positioned(
                    right: 1,
                    bottom: 2,
                    child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online!
                                ? AppColors.figmaGreen
                                : AppColors.textMuted,
                            border:
                                Border.all(color: AppColors.figmaBurgundy)))),
            ])));
  }

  Widget _fallback() => DecoratedBox(
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.figmaBurgundy),
      child: Icon(Icons.person_rounded,
          color: AppColors.figmaDisabledBg, size: size * .7));
}
