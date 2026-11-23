import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveKitAudioService {
  Room? _room;

  final StreamController<Set<String>> _activeSpeakersController =
      StreamController<Set<String>>.broadcast();
  final StreamController<bool> _isMutedController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _isConnectedController =
      StreamController<bool>.broadcast();

  bool _isMuted = false;
  bool _isConnected = false;
  bool _isSpeakerphoneOn = true;
  final Set<String> _activeSpeakerIds = {};

  Stream<Set<String>> get activeSpeakersStream => _activeSpeakersController.stream;
  Stream<bool> get isMutedStream => _isMutedController.stream;
  Stream<bool> get isConnectedStream => _isConnectedController.stream;

  bool get isMuted => _isMuted;
  bool get isConnected => _isConnected;
  bool get isSpeakerphoneOn => _isSpeakerphoneOn;
  Set<String> get activeSpeakerIds => Set.unmodifiable(_activeSpeakerIds);

  Future<void> joinRoomAudio(String roomId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateLiveKitToken');
      final response = await callable.call({'roomId': roomId});

      final String token = response.data['token'];
      final String livekitUrl = response.data['url'];

      await connect(url: livekitUrl, token: token);
    } catch (e) {
      debugPrint('Error joining room audio via Cloud Function: $e');
      rethrow;
    }
  }

  Future<void> connect({required String url, required String token}) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      // Request runtime microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission denied by user.');
        throw Exception('Microphone permission is required for WebRTC voice communication.');
      }

      const roomOptions = RoomOptions(
        defaultAudioPublishOptions: AudioPublishOptions(
          audioBitrate: 32000,
        ),
      );

      _room = Room(roomOptions: roomOptions);
      _setUpRoomListeners();

      await _room!.connect(url, token);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _isConnected = true;
      if (!_isConnectedController.isClosed) {
        _isConnectedController.add(true);
      }
    } catch (e) {
      debugPrint('LiveKit Connection Error: $e');
      await disconnect();
      rethrow;
    }
  }

  void _setUpRoomListeners() {
    if (_room == null) return;

    // Listen to room events for active speakers & disconnection
    _room!.addListener(() {
      if (_room == null) return;
      _activeSpeakerIds.clear();
      for (final p in _room!.activeSpeakers) {
        _activeSpeakerIds.add(p.identity);
      }
      if (!_activeSpeakersController.isClosed) {
        _activeSpeakersController.add(Set.from(_activeSpeakerIds));
      }
    });
  }

  Future<void> toggleMicrophone() async {
    await toggleMute();
  }

  Future<void> toggleMute() async {
    if (_room == null || _room!.localParticipant == null) return;
    try {
      _isMuted = !_isMuted;
      await _room!.localParticipant!.setMicrophoneEnabled(!_isMuted);
      if (!_isMutedController.isClosed) {
        _isMutedController.add(_isMuted);
      }
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
    }
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_room == null || _room!.localParticipant == null) return;
    try {
      _isMuted = !enabled;
      await _room!.localParticipant!.setMicrophoneEnabled(enabled);
      if (!_isMutedController.isClosed) {
        _isMutedController.add(_isMuted);
      }
    } catch (e) {
      debugPrint('Error setting microphone enabled: $e');
    }
  }

  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    try {
      _isSpeakerphoneOn = enabled;
      // livekit_client handles audio output routing automatically
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
  }

  Future<void> toggleSpeakerphone() async {
    await setSpeakerphoneEnabled(!_isSpeakerphoneOn);
  }

  Future<void> disconnect() async {
    try {
      await _room?.disconnect();
      _room = null;
      _activeSpeakerIds.clear();
      _isConnected = false;
      _isMuted = false;

      if (!_activeSpeakersController.isClosed) {
        _activeSpeakersController.add({});
      }
      if (!_isMutedController.isClosed) {
        _isMutedController.add(false);
      }
      if (!_isConnectedController.isClosed) {
        _isConnectedController.add(false);
      }
    } catch (e) {
      debugPrint('Error disconnecting LiveKit room: $e');
    }
  }

  void dispose() {
    disconnect();
    if (!_activeSpeakersController.isClosed) _activeSpeakersController.close();
    if (!_isMutedController.isClosed) _isMutedController.close();
    if (!_isConnectedController.isClosed) _isConnectedController.close();
  }
}
