import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/in_person_game_config.dart';
import '../providers/in_person_providers.dart';

class InPersonConfigScreen extends ConsumerStatefulWidget {
  final InPersonGameMode mode;

  const InPersonConfigScreen({super.key, required this.mode});

  @override
  ConsumerState<InPersonConfigScreen> createState() => _InPersonConfigScreenState();
}

class _InPersonConfigScreenState extends ConsumerState<InPersonConfigScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  final List<String> _playerNames = [
    'Agent Alpha',
    'Agent Viper',
    'Agent Shadow',
    'Agent Ghost',
    'Agent Spectre',
    'Agent Cipher',
  ];

  int _mafiaCount = 2;
  bool _includeDoctor = true;
  bool _includeDetective = true;
  int _civilianCount = 2;
  int _discussionMinutes = 4;
  int _votingSeconds = 45;
  bool _revealRoleOnElimination = true;

  void _addPlayer() {
    final name = _playerNameController.text.trim();
    if (name.isNotEmpty && !_playerNames.contains(name)) {
      setState(() {
        _playerNames.add(name);
        _playerNameController.clear();
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerNames.length > 5) {
      setState(() {
        _playerNames.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 5 players are required.')),
      );
    }
  }

  InPersonGameConfig _buildConfig() {
    return InPersonGameConfig(
      mode: widget.mode,
      playerNames: _playerNames,
      mafiaCount: _mafiaCount,
      includeDoctor: _includeDoctor,
      includeDetective: _includeDetective,
      civilianCount: _civilianCount,
      discussionSeconds: _discussionMinutes * 60,
      votingSeconds: _votingSeconds,
      revealRoleOnElimination: _revealRoleOnElimination,
    );
  }

  void _startGame() {
    final config = _buildConfig();
    if (!config.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(config.validationError ?? 'Invalid game setup.')),
      );
      return;
    }

    ref.read(inPersonGameProvider.notifier).startNewGame(config);

    if (widget.mode == InPersonGameMode.fullDigital) {
      context.push('/in_person/pass_reveal');
    } else {
      context.push('/in_person/assistant_game');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _buildConfig();
    final isValid = config.isValid;
    final validationMsg = config.validationError;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == InPersonGameMode.fullDigital
              ? 'DIGITAL MODERATOR SETUP'
              : 'ASSISTANT SETUP',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // VALIDATION SUMMARY BANNER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValid ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.warning,
                    color: isValid ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isValid
                          ? 'Valid Setup: ${config.totalPlayers} Players = ${config.totalRoles} Roles'
                          : validationMsg ?? 'Invalid game setup.',
                      style: TextStyle(
                        color: isValid ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PLAYER NAMES SETUP
            Text('PLAYERS (${_playerNames.length})',
                style: GoogleFonts.cinzel(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Player Name',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1F2833),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E56),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_playerNames.length, (idx) {
                return Chip(
                  backgroundColor: const Color(0xFF1F2833),
                  label: Text(_playerNames[idx],
                      style: const TextStyle(color: Colors.white)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                  onDeleted: () => _removePlayer(idx),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ROLE DISTRIBUTION SETUP
            Text('ROLE DISTRIBUTION',
                style: GoogleFonts.cinzel(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),

            // MAFIA COUNT
            ListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Mafia Team Size',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white70),
                    onPressed: () {
                      if (_mafiaCount > 1) {
                        setState(() => _mafiaCount--);
                      }
                    },
                  ),
                  Text('$_mafiaCount',
                      style: GoogleFonts.cinzel(
                          fontSize: 18, color: const Color(0xFFFF1E56))),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white70),
                    onPressed: () {
                      if (_mafiaCount < 5) {
                        setState(() => _mafiaCount++);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // DOCTOR TOGGLE
            SwitchListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Include Doctor Role',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              activeColor: Colors.greenAccent,
              value: _includeDoctor,
              onChanged: (val) => setState(() => _includeDoctor = val),
            ),
            const SizedBox(height: 8),

            // DETECTIVE TOGGLE
            SwitchListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Include Detective Role',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              activeColor: Colors.amberAccent,
              value: _includeDetective,
              onChanged: (val) => setState(() => _includeDetective = val),
            ),
            const SizedBox(height: 8),

            // CIVILIAN COUNT
            ListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Civilian Count',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white70),
                    onPressed: () {
                      if (_civilianCount > 1) {
                        setState(() => _civilianCount--);
                      }
                    },
                  ),
                  Text('$_civilianCount',
                      style: GoogleFonts.cinzel(fontSize: 18, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white70),
                    onPressed: () {
                      setState(() => _civilianCount++);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TIMERS & RULES SETUP
            Text('TIMER & GAME RULES',
                style: GoogleFonts.cinzel(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),

            // DISCUSSION TIMER
            ListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text('Discussion Timer: $_discussionMinutes mins',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Slider(
                value: _discussionMinutes.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: const Color(0xFFFF1E56),
                onChanged: (val) => setState(() => _discussionMinutes = val.toInt()),
              ),
            ),
            const SizedBox(height: 8),

            // REVEAL ROLE ON DEATH
            SwitchListTile(
              tileColor: const Color(0xFF1F2833),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Reveal Role on Death',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              activeColor: const Color(0xFFFF1E56),
              value: _revealRoleOnElimination,
              onChanged: (val) => setState(() => _revealRoleOnElimination = val),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: isValid ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1E56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.mode == InPersonGameMode.fullDigital
                    ? 'PROCEED TO ROLE REVEAL'
                    : 'START MODERATOR DASHBOARD',
                style: GoogleFonts.cinzel(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
