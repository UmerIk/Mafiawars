import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/design/mafia_page.dart';
import 'providers/auth_providers.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    await ref
        .read(authControllerProvider.notifier)
        .signInAnonymously(displayName: '');
    if (context.mounted && !ref.read(authControllerProvider).hasError) {
      context.go('/profile_setup');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return MafiaPage(
        scrollable: false,
        padding: EdgeInsets.zero,
        child: LayoutBuilder(builder: (context, constraints) {
          final height = math.max(constraints.maxHeight, 600.0);
          final scale = (height / 956).clamp(.65, 1.0);
          final buttonHeight = math.max(48.0, 60 * scale);
          final titleSize = (constraints.maxWidth / 440 * 24).clamp(20.0, 24.0);
          return SingleChildScrollView(
              child: SizedBox(
                  height: height,
                  child: Column(children: [
                    SizedBox(height: 80 * scale),
                    Image.asset(AppAssets.logo,
                        width: 240 * scale,
                        height: 120 * scale,
                        fit: BoxFit.contain,
                        semanticLabel: 'Mafia Wars'),
                    SizedBox(height: 54 * scale),
                    Text('Welcome back agent!',
                        style:
                            AppTypography.uiTitle.copyWith(fontSize: titleSize),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 3),
                    const Text('Time to take new assignments',
                        style: AppTypography.uiCaption),
                    SizedBox(height: 24 * scale),
                    Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 30 *
                                (constraints.maxWidth / 440).clamp(.8, 1.15)),
                        child: Column(children: [
                          AppButton(
                              text: 'Sign In With Google',
                              variant: AppButtonVariant.secondary,
                              leading: const Icon(Icons.g_mobiledata_rounded,
                                  size: 26, color: AppColors.figmaWhite),
                              height: buttonHeight,
                              isFullWidth: true,
                              isLoading: auth.isLoading,
                              onPressed: auth.isLoading
                                  ? null
                                  : () => _signIn(context, ref)),
                          const SizedBox(height: 10),
                          AppButton(
                              text: 'Sign In With Apple',
                              variant: AppButtonVariant.secondary,
                              leading: const Icon(Icons.apple,
                                  color: AppColors.figmaWhite, size: 23),
                              height: buttonHeight,
                              isFullWidth: true),
                          if (auth.hasError)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    'Couldn’t sign in. Please try again.',
                                    style: AppTypography.uiCaption
                                        .copyWith(color: AppColors.error))),
                        ])),
                    SizedBox(height: 35 * scale),
                    Expanded(
                        child: ClipRect(
                            child: OverflowBox(
                                maxWidth: constraints.maxWidth * 509 / 440,
                                minWidth: constraints.maxWidth * 509 / 440,
                                alignment: Alignment.bottomCenter,
                                child: Image.asset(AppAssets.characters,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter,
                                    excludeFromSemantics: true)))),
                  ])));
        }));
  }
}
