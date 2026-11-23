import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/in_person_game_config.dart';
import '../providers/in_person_providers.dart';

class InPersonSelectScreen extends ConsumerWidget {
  const InPersonSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(inPersonGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('IN-PERSON GAMEPLAY',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lobby'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activeState != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ACTIVE LOCAL GAME IN PROGRESS',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (activeState.config.mode ==
                            InPersonGameMode.fullDigital) {
                          context.push('/in_person/digital_game');
                        } else {
                          context.push('/in_person/assistant_game');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('RESUME GAME'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'SELECT GAMEPLAY MODE',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Designed for playing together physically in the same room.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // MODE A: FULL DIGITAL MODERATOR
            GestureDetector(
              onTap: () => context.push(
                '/in_person/config',
                extra: InPersonGameMode.fullDigital,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2833),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF1E56), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology,
                            size: 32, color: Color(0xFFFF1E56)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'FULL DIGITAL MODERATOR',
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The app acts as the game moderator. Guides secret pass-the-phone role reveals, night audio prompts, and automated day discussion/voting timers.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // MODE B: MODERATOR ASSISTANT
            GestureDetector(
              onTap: () => context.push(
                '/in_person/config',
                extra: InPersonGameMode.moderatorAssistant,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2833),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_ind,
                            size: 32, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'MODERATOR ASSISTANT',
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Designed for a human moderator sitting with the group. Provides a control dashboard to record night kills, doctor saves, voting results, and game logs.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
