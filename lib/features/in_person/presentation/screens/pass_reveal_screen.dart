import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../game/domain/entities/game_room_entity.dart';
import '../providers/in_person_providers.dart';

class PassRevealScreen extends ConsumerStatefulWidget {
  const PassRevealScreen({super.key});

  @override
  ConsumerState<PassRevealScreen> createState() => _PassRevealScreenState();
}

class _PassRevealScreenState extends ConsumerState<PassRevealScreen> {
  bool _isRevealed = false;

  void _handleReveal() {
    setState(() => _isRevealed = true);
  }

  void _handleNextPlayer() {
    setState(() => _isRevealed = false);
    final gameState = ref.read(inPersonGameProvider);
    if (gameState == null) return;

    final nextIndex = gameState.currentPassIndex + 1;
    if (nextIndex >= gameState.config.totalPlayers) {
      ref.read(inPersonGameProvider.notifier).advancePassReveal();
      context.go('/in_person/digital_game');
    } else {
      ref.read(inPersonGameProvider.notifier).advancePassReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(inPersonGameProvider);

    if (gameState == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active game session found.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/lobby'),
                child: const Text('RETURN TO LOBBY'),
              ),
            ],
          ),
        ),
      );
    }

    final currentIndex = gameState.currentPassIndex;
    final totalPlayers = gameState.config.totalPlayers;
    final currentName = gameState.config.playerNames[currentIndex];
    final currentRole = gameState.playerRoles[currentName] ?? PlayerRole.civilian;

    return Scaffold(
      appBar: AppBar(
        title: Text('PASS & REVEAL (${currentIndex + 1}/$totalPlayers)',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PRIVACY PASS PROMPT (BEFORE REVEAL)
            if (!_isRevealed) ...[
              const Icon(Icons.phonelink_setup,
                  size: 80, color: Color(0xFFFF1E56)),
              const SizedBox(height: 24),
              Text(
                'PASS DEVICE TO',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white54, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                currentName,
                style: GoogleFonts.cinzel(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Ensure other agents are not looking before tapping reveal!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _handleReveal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E56),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.visibility),
                label: Text(
                  'I AM $currentName - REVEAL ROLE',
                  style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ] else ...[
              // SECRET ROLE VIEW (AFTER REVEAL)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2833),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _getRoleColor(currentRole), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getRoleIcon(currentRole),
                      size: 64,
                      color: _getRoleColor(currentRole),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentName,
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentRole.title} (${currentRole.faction})',
                      style: GoogleFonts.cinzel(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(currentRole),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getRoleDescription(currentRole),
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _handleNextPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2833),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF1E56)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.visibility_off),
                label: Text(
                  currentIndex + 1 < totalPlayers
                      ? 'HIDE ROLE & PASS TO NEXT AGENT'
                      : 'HIDE ROLE & START NIGHT 1',
                  style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(PlayerRole role) {
    switch (role) {
      case PlayerRole.mafia:
        return const Color(0xFFFF1E56);
      case PlayerRole.doctor:
        return Colors.greenAccent;
      case PlayerRole.detective:
        return Colors.amberAccent;
      case PlayerRole.civilian:
      default:
        return Colors.lightBlueAccent;
    }
  }

  IconData _getRoleIcon(PlayerRole role) {
    switch (role) {
      case PlayerRole.mafia:
        return Icons.security;
      case PlayerRole.doctor:
        return Icons.local_hospital;
      case PlayerRole.detective:
        return Icons.search;
      case PlayerRole.civilian:
      default:
        return Icons.person;
    }
  }

  String _getRoleDescription(PlayerRole role) {
    switch (role) {
      case PlayerRole.mafia:
        return 'Eliminate Town agents during the night and blend in during day discussions.';
      case PlayerRole.doctor:
        return 'Choose one agent each night to protect from Mafia elimination.';
      case PlayerRole.detective:
        return 'Investigate one agent each night to discover if they belong to the Mafia.';
      case PlayerRole.civilian:
      default:
        return 'Participate in day discussions and vote to eliminate the Mafia suspects.';
    }
  }
}
