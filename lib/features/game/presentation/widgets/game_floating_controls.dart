// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../../audio/providers/audio_providers.dart';
import '../providers/briefing_providers.dart';
import 'room_role_sheet.dart';

/// Shared voice, leave, private-role and chat controls for every game state.
class GameFloatingControls extends ConsumerWidget {
  const GameFloatingControls(
      {super.key,
      required this.roomId,
      required this.playerCount,
      required this.isAlive,
      required this.onLeave,
      required this.onChat,
      this.unreadCount = 0});
  final String roomId;
  final int playerCount, unreadCount;
  final bool isAlive;
  final VoidCallback onLeave, onChat;
  Future<void> _audio(BuildContext context, WidgetRef ref,
      Future<void> Function() action) async {
    if (ref.read(briefingAudioBusyProvider(roomId))) return;
    ref.read(briefingAudioBusyProvider(roomId).notifier).state = true;
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Audio could not be updated. Please try again.')));
      }
    } finally {
      if (context.mounted) {
        ref.read(briefingAudioBusyProvider(roomId).notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(liveKitAudioServiceProvider);
    final connected =
        ref.watch(isAudioConnectedProvider).valueOrNull ?? audio.isConnected;
    final muted = ref.watch(isMicMutedProvider).valueOrNull ?? audio.isMuted;
    final speakerOverride = ref.watch(briefingSpeakerProvider(roomId));
    final speaker = speakerOverride ?? audio.isSpeakerphoneOn;
    final busy = ref.watch(briefingAudioBusyProvider(roomId));
    return LayoutBuilder(builder: (context, size) {
      final buttonSize = ((size.maxWidth - 40) / 5).clamp(44.0, 60.0);
      return AppSurface(
          radius: 40,
          padding: const EdgeInsets.all(10),
          borderWidth: 0,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            AppIconButton(
                size: buttonSize,
                icon: Icons.logout,
                label: 'Leave room',
                onPressed: onLeave,
                child: const Icon(Icons.logout, color: AppColors.neonCrimson)),
            AppIconButton(
                size: buttonSize,
                icon: muted ? Icons.mic_off : Icons.mic,
                label: !connected
                    ? 'Audio disconnected'
                    : !isAlive
                        ? 'Microphone unavailable while eliminated'
                        : muted
                            ? 'Unmute microphone'
                            : 'Mute microphone',
                onPressed: connected && isAlive && !busy
                    ? () => _audio(context, ref, audio.toggleMicrophone)
                    : null),
            AppIconButton(
                size: buttonSize,
                icon: speaker ? Icons.volume_up : Icons.hearing,
                label: speaker ? 'Switch to earpiece' : 'Switch to speaker',
                onPressed: !connected || busy
                    ? null
                    : () => _audio(context, ref, () async {
                          await audio.setSpeakerphoneEnabled(!speaker);
                          if (context.mounted) {
                            ref
                                .read(briefingSpeakerProvider(roomId).notifier)
                                .state = audio.isSpeakerphoneOn;
                          }
                        })),
            AppIconButton(
                size: buttonSize,
                icon: Icons.badge,
                label: 'Secret role',
                onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.figmaTextFieldBg,
                    builder: (_) => RoomRoleSheet(
                        roomId: roomId, playerCount: playerCount))),
            AppIconButton(
                size: buttonSize,
                icon: Icons.chat_bubble_rounded,
                label:
                    'Game chat${unreadCount > 0 ? ', $unreadCount unread' : ''}',
                onPressed: onChat,
                child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.chat_bubble_rounded,
                        color: AppColors.figmaWhite)))
          ]));
    });
  }
}
