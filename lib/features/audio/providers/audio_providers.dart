import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../elevenlabs_moderator_service.dart';
import '../livekit_audio_service.dart';
import '../narrator_player_service.dart';

final liveKitAudioServiceProvider = Provider<LiveKitAudioService>((ref) {
  final service = LiveKitAudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final activeSpeakersProvider = StreamProvider<Set<String>>((ref) {
  final audioService = ref.watch(liveKitAudioServiceProvider);
  return audioService.activeSpeakersStream;
});

final isMicMutedProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(liveKitAudioServiceProvider);
  return audioService.isMutedStream;
});

final isAudioConnectedProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(liveKitAudioServiceProvider);
  return audioService.isConnectedStream;
});

final elevenLabsModeratorServiceProvider =
    Provider<ElevenLabsModeratorService>((ref) {
  return ElevenLabsModeratorService();
});

final narratorPlayerServiceProvider = Provider<NarratorPlayerService>((ref) {
  final service = NarratorPlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final isNarratorSpeakingProvider = StreamProvider<bool>((ref) {
  final narrator = ref.watch(narratorPlayerServiceProvider);
  return narrator.isSpeakingStream;
});

final currentNarrationTextProvider = StreamProvider<String?>((ref) {
  final narrator = ref.watch(narratorPlayerServiceProvider);
  return narrator.currentScriptTextStream;
});
