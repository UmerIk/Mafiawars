import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/design/agent_avatar.dart';
import '../../../core/widgets/design/app_icon_button.dart';
import '../../../core/widgets/design/app_surface.dart';
import '../../../core/widgets/design/mafia_page.dart';
import '../../../core/widgets/design/profile_header.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../game/presentation/providers/game_providers.dart';
import '../../social/presentation/providers/social_providers.dart';
import 'widgets/game_invite_sheet.dart';
import 'widgets/dashboard_room_card.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});
  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _roomCodeController = TextEditingController();
  StreamSubscription? _inviteSub;
  bool _inviteSheetOpen = false;
  @override
  void initState() {
    super.initState();
    _initFcmToken();
    Future.microtask(() {
      if (!mounted) return;
      _inviteSub =
          ref.read(socialRepositoryProvider).getGameInvitesStream().listen(
              (invites) {
        if (mounted && invites.isNotEmpty && !_inviteSheetOpen) _showInvites();
      },
              onError: (Object error) =>
                  debugPrint('Invite listener failed: $error'));
    });
  }

  Future<void> _initFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (!mounted) return;
      final user = ref.read(authRepositoryProvider).currentUser;
      if (token != null && user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'fcmToken': token, 'status': 'online'}, SetOptions(merge: true));
      }
    } catch (error) {
      debugPrint('FCM token initialization failed: $error');
    }
  }

  Future<void> _showInvites() async {
    if (_inviteSheetOpen) return;
    _inviteSheetOpen = true;
    await GameInviteSheet.show(context);
    _inviteSheetOpen = false;
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _inviteSub?.cancel();
    super.dispose();
  }

  void _edit(UserEntity user) =>
      context.push('/profile_setup?edit=true', extra: user);
  Future<void> _createRoom() async {
    final room = await ref.read(gameControllerProvider.notifier).createRoom();
    if (mounted && room != null) context.push('/game/${room.roomId}');
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a 6-character room code.')));
      return;
    }
    final room =
        await ref.read(gameControllerProvider.notifier).joinRoomByCode(code);
    if (mounted && room != null) context.push('/game/${room.roomId}');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider);
    final game = ref.watch(gameControllerProvider);
    ref.listen(gameControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(next.error.toString().replaceFirst('Exception: ', ''))));
      }
    });
    return MafiaPage(
        child: user.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Column(children: [
                  const Text('Couldn’t load your profile.',
                      style: AppTypography.uiBody),
                  TextButton(
                      onPressed: () => ref.invalidate(authStateChangesProvider),
                      child: const Text('Try again'))
                ]),
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                        name: profile.displayName,
                        avatar: profile.avatarUrl,
                        onEdit: () => _edit(profile)),
                    const SizedBox(height: 30),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _NetworkPreview(
                                  onTap: () => context.push('/social'))),
                          const SizedBox(width: 12),
                          Column(children: [
                            AppIconButton(
                                icon: Icons.mark_email_unread_outlined,
                                label: 'Active invitations',
                                onPressed: _showInvites),
                            const SizedBox(height: 12),
                            AppIconButton(
                                icon: Icons.chat_bubble_rounded,
                                label: 'Messages',
                                onPressed: () => context.push('/new_chat'))
                          ]),
                        ]),
                    const SizedBox(height: 30),
                    DashboardRoomCard(
                        title: 'Join Room',
                        artwork: AppAssets.joinRoom,
                        onTap: null,
                        child: AppTextField(
                            controller: _roomCodeController,
                            hintText: 'Room code',
                            maxLength: 6,
                            enabled: !game.isLoading,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[a-zA-Z0-9]'))
                            ],
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) {
                              if (!game.isLoading) _joinRoom();
                            },
                            suffixIcon: game.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)))
                                : IconButton(
                                    tooltip: 'Join room',
                                    onPressed: _joinRoom,
                                    icon: const Icon(
                                        Icons.arrow_circle_right_rounded,
                                        color: AppColors.figmaPink)))),
                    const SizedBox(height: 12),
                    DashboardRoomCard(
                        title: 'Create a Room',
                        artwork: AppAssets.createRoom,
                        artworkOnRight: true,
                        onTap: game.isLoading ? null : _createRoom),
                    const SizedBox(height: 12),
                    DashboardRoomCard(
                        title: 'In-person Play',
                        artwork: AppAssets.party,
                        onTap: () => context.push('/in_person')),
                    const SizedBox(height: 24),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Sign out'))),
                  ]);
            }));
  }
}

class _NetworkPreview extends ConsumerWidget {
  const _NetworkPreview({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsStreamProvider);
    return AppSurface(
        radius: 20,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              height: 65,
              child: friends.when(
                  data: (items) => items.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Find your fellow agents',
                              style: AppTypography.uiCaption))
                      : Row(
                          children: items
                              .take(5)
                              .map((friend) => Expanded(
                                      child: Column(children: [
                                    AgentAvatar(
                                        key: ValueKey(friend.uid),
                                        value: friend.avatarUrl,
                                        size: 40,
                                        online: friend.status != 'offline'),
                                    const SizedBox(height: 3),
                                    Text(friend.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.uiCaption
                                            .copyWith(fontSize: 9))
                                  ])))
                              .toList()),
                  loading: () => const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('Open your network',
                      style: AppTypography.uiCaption))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: Text('Agents Network',
                    style: AppTypography.uiTitle.copyWith(fontSize: 22))),
            const Icon(Icons.arrow_circle_right_rounded, size: 22)
          ]),
        ]));
  }
}
