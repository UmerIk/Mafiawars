import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  Future<void> _handleSignIn() async {
    await ref.read(authControllerProvider.notifier).signInAnonymously(
          displayName: 'Agent47',
        );

    if (mounted) {
      final state = ref.read(authControllerProvider);
      if (!state.hasError) {
        context.go('/lobby');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF43275A),
                      Color(0xFF341F46),
                      Color(0xFF191024),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.04),
                    const Color(0x22301C40),
                    const Color(0x55301C40),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final compact = height < 740;
                final logoHeight = (height * 0.16).clamp(104.0, 130.0);

                return Column(
                  children: [
                    SizedBox(height: (height * 0.055).clamp(24.0, 48.0)),
                    Image.asset(
                      'assets/images/mafia_wars_logo.png',
                      width: constraints.maxWidth * 0.72,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'MAFIA WARS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFEF0E6),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    const Text(
                      'Welcome back agent!',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFEF0E6),
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Time to take new assignments',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFEF0E6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: compact ? 12 : 17),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.065,
                      ),
                      child: Column(
                        children: [
                          _SocialSignInButton(
                            label: 'Sign In With Google',
                            icon: Icons.g_mobiledata_rounded,
                            onPressed: isLoading ? null : _handleSignIn,
                          ),
                          const SizedBox(height: 9),
                          const _SocialSignInButton(
                            label: 'Sign In With Apple',
                            icon: Icons.apple_rounded,
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, artConstraints) {
                          final artHeight = artConstraints.maxHeight;
                          return SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: constraints.maxWidth * 0.12,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/images/character_cigar_boss.png',
                                    height: artHeight * 0.70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                                Positioned(
                                  right: constraints.maxWidth * 0.10,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/images/character_detective.png',
                                    height: artHeight * 0.70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                                Positioned(
                                  left: -constraints.maxWidth * 0.02,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/images/character_doctor.png',
                                    height: artHeight * 0.79,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                                Positioned(
                                  right: -constraints.maxWidth * 0.02,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/images/character_femme_fatale.png',
                                    height: artHeight * 0.79,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/images/character_noble_portrait.png',
                                    height: artHeight * 0.93,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialSignInButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SocialSignInButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7DD6FC), Color(0xFFED77ED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC493B8E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFFB88CFF), size: 23),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFFEF0E6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
