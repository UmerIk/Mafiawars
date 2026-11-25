// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';

/// Shared empty/error state with an optional retry action.
class AsyncFeedback extends StatelessWidget {
  const AsyncFeedback({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message,
                textAlign: TextAlign.center, style: AppTypography.uiBody),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry'))
          ])));
}
