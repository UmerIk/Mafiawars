import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/audio/livekit_audio_service.dart';

void main() {
  group('LiveKitAudioService initial state & disconnection', () {
    late LiveKitAudioService audioService;

    setUp(() {
      audioService = LiveKitAudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('initial state has default values', () {
      expect(audioService.isConnected, false);
      expect(audioService.isMuted, false);
      expect(audioService.activeSpeakerIds.isEmpty, true);
    });

    test('disconnect resets audio streams and state', () async {
      await audioService.disconnect();

      expect(audioService.isConnected, false);
      expect(audioService.activeSpeakerIds.isEmpty, true);
    });
  });
}
