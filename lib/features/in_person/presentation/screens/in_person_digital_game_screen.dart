import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../audio/providers/audio_providers.dart';
import '../../../game/domain/entities/game_room_entity.dart';
import '../providers/in_person_providers.dart';

class InPersonDigitalGameScreen extends ConsumerStatefulWidget {
  const InPersonDigitalGameScreen({super.key});

  @override
  ConsumerState<InPersonDigitalGameScreen> createState() =>
      _InPersonDigitalGameScreenState();
}

class _InPersonDigitalGameScreenState
    extends ConsumerState<InPersonDigitalGameScreen> {
  String? _selectedTarget;
  Timer? _phaseTimer;
  int _secondsRemaining = 20;

  @override
  void initState() {
    super.initState();
    _resetPhaseTimer();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _resetPhaseTimer() {
    _phaseTimer?.cancel();
    final gameState = ref.read(inPersonGameProvider);
    if (gameState == null) return;

    if (gameState.currentPhase == GamePhase.dayDiscussion) {
      _secondsRemaining = gameState.config.discussionSeconds;
    } else if (gameState.currentPhase == GamePhase.dayVoting) {
      _secondsRemaining = gameState.config.votingSeconds;
    } else {
      _secondsRemaining = 20;
    }

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _phaseTimer?.cancel();
        // Auto-advance phase when timer expires
        ref.read(inPersonGameProvider.notifier).advancePhase();
        _resetPhaseTimer();
      }
    });
  }

  void _playPhaseNarration(GamePhase phase, String? winner) {
    final moderator = ref.read(elevenLabsModeratorServiceProvider);
    final script = moderator.getPhaseNarrationScript(phase, winningFaction: winner);
    ref.read(narratorPlayerServiceProvider).playNarrationScript(script);
  }

  void _confirmTargetAction(String phaseName) {
    if (_selectedTarget == null) return;

    ref.read(inPersonGameProvider.notifier).submitNightAction(
          actionType: phaseName,
          targetName: _selectedTarget!,
        );

    setState(() => _selectedTarget = null);
    ref.read(inPersonGameProvider.notifier).advancePhase();
    _resetPhaseTimer();
  }

  void _confirmDayVote() {
    if (_selectedTarget == null) return;

    ref.read(inPersonGameProvider.notifier).submitDayVote(
          voterName: 'GroupVote',
          targetName: _selectedTarget!,
        );

    setState(() => _selectedTarget = null);
    ref.read(inPersonGameProvider.notifier).advancePhase();
    _resetPhaseTimer();
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

    // GAME OVER VIEW
    if (gameState.currentPhase == GamePhase.gameOver ||
        gameState.winningFaction != null) {
      final winner = gameState.winningFaction ?? 'TOWN';
      return Scaffold(
        appBar: AppBar(title: Text('GAME OVER', style: GoogleFonts.cinzel())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  winner == 'MAFIA' ? Icons.security : Icons.stars,
                  size: 80,
                  color: winner == 'MAFIA'
                      ? const Color(0xFFFF1E56)
                      : Colors.amberAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  '$winner VICTORY!',
                  style: GoogleFonts.cinzel(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: winner == 'MAFIA'
                        ? const Color(0xFFFF1E56)
                        : Colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Survivors: ${gameState.alivePlayerNames.join(", ")}',
                  style: GoogleFonts.inter(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    ref.read(inPersonGameProvider.notifier).resetGame();
                    context.go('/in_person');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E56),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('START NEW GAME'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentPhase = gameState.currentPhase;

    return Scaffold(
      appBar: AppBar(
        title: Text('FULL DIGITAL MODERATOR',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              ref.read(inPersonGameProvider.notifier).resetGame();
              context.go('/in_person');
            },
            tooltip: 'End Local Game',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // PHASE BANNER & TIMER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2833),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF1E56)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT PHASE',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: Colors.white54)),
                        Text(
                          _getPhaseTitle(currentPhase),
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF1E56),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1E56).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_secondsRemaining}s',
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // GUIDED PROMPT
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0C10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up,
                      color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getPhasePrompt(currentPhase),
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AGENTS GRID
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: gameState.config.playerNames.length,
                itemBuilder: (context, idx) {
                  final name = gameState.config.playerNames[idx];
                  final isAlive = gameState.alivePlayerNames.contains(name);
                  final isSelected = _selectedTarget == name;

                  return GestureDetector(
                    onTap: isAlive
                        ? () => setState(() => _selectedTarget = name)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2833),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF1E56)
                              : isAlive
                                  ? Colors.white24
                                  : Colors.red.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isAlive
                                ? const Color(0xFFC70039)
                                : Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: GoogleFonts.cinzel(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAlive ? Colors.white : Colors.white38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAlive ? 'ALIVE' : 'DEAD 💀',
                            style: TextStyle(
                              fontSize: 9,
                              color: isAlive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ACTION / PHASE ADVANCE BUTTONS
            if (currentPhase == GamePhase.dayDiscussion) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(inPersonGameProvider.notifier).advancePhase();
                    _resetPhaseTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E56),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('END DISCUSSION & VOTE NOW'),
                ),
              ),
            ] else if (currentPhase == GamePhase.dayVoting) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _selectedTarget != null ? () => _confirmDayVote() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E56),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.gavel),
                  label: Text(
                    _selectedTarget != null
                        ? 'CONFIRM ELIMINATE $_selectedTarget'
                        : 'SELECT SUSPECT TO ELIMINATE',
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedTarget != null
                      ? () => _confirmTargetAction(currentPhase.name)
                      : () {
                          ref
                              .read(inPersonGameProvider.notifier)
                              .advancePhase();
                          _resetPhaseTimer();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E56),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _selectedTarget != null
                        ? 'CONFIRM TARGET $_selectedTarget'
                        : 'SKIP ACTION & NEXT PHASE',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPhaseTitle(GamePhase phase) {
    switch (phase) {
      case GamePhase.nightMafia:
        return 'NIGHT: MAFIA HUNT';
      case GamePhase.nightDoctor:
        return 'NIGHT: DOCTOR SAVE';
      case GamePhase.nightDetective:
        return 'NIGHT: DETECTIVE CHECK';
      case GamePhase.dayDiscussion:
        return 'DAY: CITY DISCUSSION';
      case GamePhase.dayVoting:
        return 'DAY: VOTING ELIMINATION';
      default:
        return 'IN-PERSON GAME';
    }
  }

  String _getPhasePrompt(GamePhase phase) {
    switch (phase) {
      case GamePhase.nightMafia:
        return 'Night falls over the city. Mafia, wake up secretly and select your target to eliminate.';
      case GamePhase.nightDoctor:
        return 'Doctor, wake up secretly and select one agent to protect tonight.';
      case GamePhase.nightDetective:
        return 'Detective, wake up secretly and select one agent to investigate.';
      case GamePhase.dayDiscussion:
        return 'The sun rises over the city. Open your eyes and discuss the night events!';
      case GamePhase.dayVoting:
        return 'City discussion closed. Select the suspect to eliminate by vote.';
      default:
        return 'Follow app instructions for current phase.';
    }
  }
}
