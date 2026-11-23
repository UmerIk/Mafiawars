import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../game/domain/entities/game_room_entity.dart';
import '../providers/in_person_providers.dart';

class InPersonAssistantGameScreen extends ConsumerStatefulWidget {
  const InPersonAssistantGameScreen({super.key});

  @override
  ConsumerState<InPersonAssistantGameScreen> createState() =>
      _InPersonAssistantGameScreenState();
}

class _InPersonAssistantGameScreenState
    extends ConsumerState<InPersonAssistantGameScreen> {
  String? _selectedPlayer;

  void _recordElimination(String playerName) {
    final gameState = ref.read(inPersonGameProvider);
    if (gameState == null) return;

    final newAlive = List<String>.from(gameState.alivePlayerNames)..remove(playerName);
    final newDead = List<String>.from(gameState.eliminatedPlayerNames)..add(playerName);

    ref.read(inPersonGameProvider.notifier).state = gameState.copyWith(
      alivePlayerNames: newAlive,
      eliminatedPlayerNames: newDead,
      historyLogs: [
        ...gameState.historyLogs,
        'Moderator marked $playerName eliminated.',
      ],
    );
  }

  void _recordRevive(String playerName) {
    final gameState = ref.read(inPersonGameProvider);
    if (gameState == null) return;

    final newAlive = List<String>.from(gameState.alivePlayerNames)..add(playerName);
    final newDead = List<String>.from(gameState.eliminatedPlayerNames)..remove(playerName);

    ref.read(inPersonGameProvider.notifier).state = gameState.copyWith(
      alivePlayerNames: newAlive,
      eliminatedPlayerNames: newDead,
      historyLogs: [
        ...gameState.historyLogs,
        'Moderator restored $playerName to alive.',
      ],
    );
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
              const Text('No active local game.',
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

    return Scaffold(
      appBar: AppBar(
        title: Text('MODERATOR ASSISTANT',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              ref.read(inPersonGameProvider.notifier).resetGame();
              context.go('/in_person');
            },
            tooltip: 'End Game Session',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MODERATOR CHEAT-SHEET HEADER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODERATOR CONFIDENTIAL DASHBOARD',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                        Text(
                          'Phase: ${gameState.currentPhase.name.toUpperCase()}',
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PLAYERS CHEAT SHEET TABLE
            Text('PLAYERS & SECRET ROLES',
                style: GoogleFonts.cinzel(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: gameState.config.playerNames.length,
                itemBuilder: (context, idx) {
                  final name = gameState.config.playerNames[idx];
                  final isAlive = gameState.alivePlayerNames.contains(name);
                  final role = gameState.playerRoles[name] ?? PlayerRole.civilian;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2833),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAlive ? Colors.white12 : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _getRoleColor(role),
                          child: Icon(_getRoleIcon(role),
                              size: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.cinzel(
                                  fontWeight: FontWeight.bold,
                                  color: isAlive ? Colors.white : Colors.white38,
                                ),
                              ),
                              Text(
                                '${role.title} (${role.faction})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => isAlive
                              ? _recordElimination(name)
                              : _recordRevive(name),
                          child: Text(
                            isAlive ? 'ELIMINATE' : 'RESTORE',
                            style: TextStyle(
                              color: isAlive ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ADVANCE PHASE BUTTON FOR MODERATOR
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(inPersonGameProvider.notifier).advancePhase(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1E56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.fast_forward),
              label: Text(
                'ADVANCE PHASE (${gameState.currentPhase.name.toUpperCase()})',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
              ),
            ),
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
}
