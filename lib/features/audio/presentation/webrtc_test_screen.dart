import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../game/domain/entities/game_room_entity.dart';
import '../../game/presentation/widgets/floating_audio_controls.dart';
import '../../game/presentation/widgets/google_meet_player_card.dart';
import '../providers/audio_providers.dart';

class WebRtcTestScreen extends ConsumerStatefulWidget {
  const WebRtcTestScreen({super.key});

  @override
  ConsumerState<WebRtcTestScreen> createState() => _WebRtcTestScreenState();
}

class _WebRtcTestScreenState extends ConsumerState<WebRtcTestScreen> {
  static const String testRoomId = 'webrtc_test_room';

  @override
  void initState() {
    super.initState();
    _connectTestAudio();
  }

  void _connectTestAudio() {
    Future.microtask(() async {
      try {
        await ref.read(liveKitAudioServiceProvider).joinRoomAudio(testRoomId);
      } catch (e) {
        debugPrint('WebRTC Test Room connection error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSpeakersAsync = ref.watch(activeSpeakersProvider);
    final isConnectedAsync = ref.watch(isAudioConnectedProvider);
    final activeSpeakerIds = activeSpeakersAsync.value ?? {};
    final isConnected = isConnectedAsync.value ?? false;

    final dummyTestPlayers = [
      RoomPlayerEntity(
        userId: 'test_user_1',
        displayName: 'Test Agent 1 (You)',
        avatarUrl: '',
        slotIndex: 0,
        isHost: true,
        joinedAt: DateTime.now(),
      ),
      RoomPlayerEntity(
        userId: 'test_user_2',
        displayName: 'Test Agent 2',
        avatarUrl: '',
        slotIndex: 1,
        joinedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('WEBRTC AUDIO TEST',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await ref.read(liveKitAudioServiceProvider).disconnect();
            if (context.mounted) {
              context.go('/lobby');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_protected_setup,
                        color: isConnected ? Colors.greenAccent : Colors.orangeAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected
                                  ? 'WEBRTC AUDIO CONNECTED'
                                  : 'CONNECTING WEBRTC AUDIO...',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isConnected
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isConnected
                                  ? 'Speak into microphone to test active speaker ring.'
                                  : 'Connecting to LiveKit SFU server room: $testRoomId',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'TEST PARTICIPANTS',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: dummyTestPlayers.length,
                    itemBuilder: (context, index) {
                      final p = dummyTestPlayers[index];
                      final isSpeaking = activeSpeakerIds.contains(p.userId);

                      return GoogleMeetPlayerCard(
                        player: p,
                        isSpeaking: isSpeaking,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingAudioControls(
                onDisconnect: () async {
                  await ref.read(liveKitAudioServiceProvider).disconnect();
                  if (context.mounted) {
                    context.go('/lobby');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
