import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../audio/providers/audio_providers.dart';

class FloatingAudioControls extends ConsumerWidget {
  final VoidCallback? onDisconnect;

  const FloatingAudioControls({super.key, this.onDisconnect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMutedAsync = ref.watch(isMicMutedProvider);
    final isConnectedAsync = ref.watch(isAudioConnectedProvider);
    final isMuted = isMutedAsync.value ?? false;
    final isConnected = isConnectedAsync.value ?? false;
    final audioService = ref.watch(liveKitAudioServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2833).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF1E56).withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MIC MUTE / UNMUTE BUTTON
          IconButton(
            icon: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted ? Colors.redAccent : Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isMuted
                  ? Colors.redAccent.withOpacity(0.2)
                  : const Color(0xFF0B0C10),
            ),
            onPressed: () => audioService.toggleMicrophone(),
            tooltip: isMuted ? 'Unmute Microphone' : 'Mute Microphone',
          ),
          const SizedBox(width: 12),

          // SPEAKERPHONE / EARPIECE TOGGLE
          IconButton(
            icon: Icon(
              audioService.isSpeakerphoneOn
                  ? Icons.volume_up
                  : Icons.hearing,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0B0C10),
            ),
            onPressed: () => audioService
                .setSpeakerphoneEnabled(!audioService.isSpeakerphoneOn),
            tooltip: audioService.isSpeakerphoneOn
                ? 'Switch to Earpiece'
                : 'Switch to Speakerphone',
          ),
          const SizedBox(width: 12),

          // DISCONNECT / LEAVE AUDIO BUTTON
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFF1E56),
            ),
            onPressed: () {
              audioService.disconnect();
              if (onDisconnect != null) onDisconnect!();
            },
            tooltip: isConnected ? 'Disconnect Audio' : 'Audio Disconnected',
          ),
        ],
      ),
    );
  }
}
