import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_assets.dart';
import '../../../core/theme/app_gradients.dart';
import 'providers/auth_providers.dart';
import 'providers/profile_form_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () async {
      final repository = ref.read(authRepositoryProvider);
      final current = repository.currentUser;
      if (current == null) {
        if (mounted) context.go('/');
        return;
      }
      final user = await repository.getUserProfile(current.uid);
      if (!mounted) return;
      context.go(user != null && hasCompletedProfile(user)
          ? '/lobby'
          : '/profile_setup');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.splash),
          child: Center(
              child: FractionallySizedBox(
                  widthFactor: .6, child: _SplashLogo()))));
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Image.asset(AppAssets.logo, semanticLabel: 'Mafia Wars'));
}
