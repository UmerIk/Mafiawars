import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'elevenlabs_moderator_service.dart';

class NarratorPlayerService {
  final AudioPlayer _audioPlayer;
  final FlutterTts _flutterTts;

  final StreamController<bool> _isSpeakingController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _currentScriptTextController =
      StreamController<String?>.broadcast();

  bool _isSpeaking = false;
  String? _currentScriptText;

  Stream<bool> get isSpeakingStream => _isSpeakingController.stream;
  Stream<String?> get currentScriptTextStream => _currentScriptTextController.stream;

  bool get isSpeaking => _isSpeaking;
  String? get currentScriptText => _currentScriptText;

  NarratorPlayerService({
    AudioPlayer? audioPlayer,
    FlutterTts? flutterTts,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _flutterTts = flutterTts ?? FlutterTts() {
    _initPlayerListeners();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.45); // Dramatic moderator pace
    _flutterTts.setPitch(0.9);       // Deep dramatic tone

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      if (!_isSpeakingController.isClosed) _isSpeakingController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentScriptText = null;
      if (!_isSpeakingController.isClosed) _isSpeakingController.add(false);
      if (!_currentScriptTextController.isClosed) _currentScriptTextController.add(null);
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _isSpeaking = false;
      if (!_isSpeakingController.isClosed) _isSpeakingController.add(false);
    });
  }

  void _initPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      final speaking =
          playing && (processingState == ProcessingState.ready || processingState == ProcessingState.buffering);

      if (_isSpeaking != speaking) {
        _isSpeaking = speaking;
        if (!_isSpeakingController.isClosed) {
          _isSpeakingController.add(_isSpeaking);
        }
      }

      if (processingState == ProcessingState.completed) {
        _currentScriptText = null;
        if (!_currentScriptTextController.isClosed) {
          _currentScriptTextController.add(null);
        }
      }
    });
  }

  Future<File?> _getCachedAudioFile(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/narration_cache_$id.mp3');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Cache check error: $e');
    }
    return null;
  }

  Future<void> playNarrationScript(NarrationScript script) async {
    _currentScriptText = script.text;
    if (!_currentScriptTextController.isClosed) {
      _currentScriptTextController.add(_currentScriptText);
    }

    try {
      // 1. Check local MP3 file cache
      final cachedFile = await _getCachedAudioFile(script.id);
      if (cachedFile != null) {
        await _audioPlayer.setFilePath(cachedFile.path);
        await _audioPlayer.play();
        return;
      }

      // 2. Stream online audio URL if available
      if (script.audioUrl != null && script.audioUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(script.audioUrl!);
        await _audioPlayer.play();
        return;
      }

      // 3. Fallback to Flutter Text-To-Speech engine
      await _flutterTts.speak(script.text);
    } catch (e) {
      debugPrint('Narration playback error: $e');
      _isSpeaking = false;
      if (!_isSpeakingController.isClosed) _isSpeakingController.add(false);
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      _currentScriptText = null;
      _isSpeaking = false;
      if (!_isSpeakingController.isClosed) _isSpeakingController.add(false);
      if (!_currentScriptTextController.isClosed) _currentScriptTextController.add(null);
    } catch (e) {
      debugPrint('Error stopping narrator player: $e');
    }
  }

  void dispose() {
    stop();
    _audioPlayer.dispose();
    if (!_isSpeakingController.isClosed) _isSpeakingController.close();
    if (!_currentScriptTextController.isClosed) _currentScriptTextController.close();
  }
}
