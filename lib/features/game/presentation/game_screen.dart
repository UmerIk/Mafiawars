import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../audio/providers/audio_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../social/presentation/providers/social_providers.dart';
import '../../social/presentation/widgets/invite_friends_dialog.dart';
import '../data/models/game_room_model.dart';
import '../domain/entities/game_room_entity.dart';
import 'providers/game_providers.dart';
import 'widgets/animated_unread_badge.dart';
import 'widgets/floating_audio_controls.dart';
import 'widgets/game_chat_drawer.dart';
import 'widgets/google_meet_player_card.dart';
import 'widgets/moderator_narration_banner.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _revealRole = false;
  String? _selectedActionTargetId;
  String? _investigationResult;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  int _unreadChatCount = 0;
  bool _isChatDrawerOpen = false;
  final List<StreamSubscription?> _chatSubs = [];
  Set<String> _activeSubChannels = {};

  @override
  void initState() {
    super.initState();
    _startTimerTicker();
    _joinAudioSession();
    _updateInGamePresence();
  }

  void _updateInGamePresence() {
    Future.microtask(() {
      try {
        ref.read(socialRepositoryProvider).updateUserPresence('in_game');
      } catch (_) {}
    });
  }

  void _updateChatSubscriptions(PlayerRole? myRole, bool isAlive) {
    // Unread message badge eligibility matrix:
    // 1. Ghost chat (dead person):
    //    - Mafia chat: True (if player is Mafia)
    //    - Public chat: True
    //    - Ghost chat: True
    // 2. Mafia chat (alive mafias):
    //    - Mafia chat: True
    //    - Public chat: True
    //    - Ghost chat: False
    // 3. Civilians / Detective / Doctors (alive non-mafia):
    //    - Mafia chat: False
    //    - Public chat: True
    //    - Ghost chat: False
    final Set<String> targetChannels = {'public'};
    if (myRole == PlayerRole.mafia) {
      targetChannels.add('mafia');
    }
    if (!isAlive) {
      targetChannels.add('ghost');
    }

    if (_activeSubChannels.length == targetChannels.length &&
        _activeSubChannels.containsAll(targetChannels)) {
      return;
    }

    for (final sub in _chatSubs) {
      sub?.cancel();
    }
    _chatSubs.clear();
    _activeSubChannels = Set.from(targetChannels);

    try {
      final chatRepo = ref.read(gameRepositoryProvider);

      for (final channel in targetChannels) {
        int lastCount = -1;
        _chatSubs.add(
          chatRepo
              .getMultiChannelChatStream(
                  roomId: widget.gameId, channel: channel)
              .listen((msgs) {
            if (lastCount >= 0) {
              if (!_isChatDrawerOpen && msgs.length > lastCount) {
                if (mounted) {
                  setState(() {
                    _unreadChatCount += (msgs.length - lastCount);
                  });
                }
              }
            }
            lastCount = msgs.length;
          }),
        );
      }
    } catch (_) {}
  }

  void _joinAudioSession() {
    Future.microtask(() async {
      try {
        await ref
            .read(liveKitAudioServiceProvider)
            .joinRoomAudio(widget.gameId);
      } catch (e) {
        debugPrint('LiveKit connection error: $e');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final sub in _chatSubs) {
      sub?.cancel();
    }
    try {
      ref.read(socialRepositoryProvider).updateUserPresence('online');
    } catch (_) {}
    super.dispose();
  }

  void _startTimerTicker() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final room = ref.read(activeRoomStreamProvider(widget.gameId)).value;
      if (room != null && room.phaseEndTime != null) {
        final diff = room.phaseEndTime!.difference(DateTime.now()).inSeconds;
        setState(() {
          _remainingSeconds = diff > 0 ? diff : 0;
        });

        final currentUser = ref.read(authRepositoryProvider).currentUser;
        if (diff <= 0 &&
            room.hostId == currentUser?.uid &&
            room.status == GameRoomStatus.inGame) {
          ref
              .read(gameControllerProvider.notifier)
              .advanceGamePhase(widget.gameId);
        }
      }
    });
  }

  void _playPhaseNarration(GamePhase phase, String? winningFaction) {
    final moderator = ref.read(elevenLabsModeratorServiceProvider);
    final script = moderator.getPhaseNarrationScript(phase,
        winningFaction: winningFaction);
    ref.read(narratorPlayerServiceProvider).playNarrationScript(script);

    if (phase == GamePhase.nightMafia) {
      _showPhasePopup('IT\'S NIGHT TIME 🌙',
          'Close your eyes. Secret night actions begin now.');
    } else if (phase == GamePhase.dayDiscussion) {
      _showPhasePopup('DAY HAS ARRIVED ☀️',
          'Open your eyes. City discussion & 3 Night Facts revealed!');
    }
  }

  void _showPhasePopup(String title, String subtitle) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F2833),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFFF1E56)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cinzel(
                          color: const Color(0xFFFF1E56),
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSelectTarget(PlayerRole? myRole, GamePhase phase, bool isAlive) {
    if (!isAlive) return false;

    switch (phase) {
      case GamePhase.nightMafia:
        return myRole == PlayerRole.mafia;
      case GamePhase.nightDoctor:
        return myRole == PlayerRole.doctor;
      case GamePhase.nightDetective:
        return myRole == PlayerRole.detective;
      case GamePhase.dayDiscussion:
      case GamePhase.dayVoting:
        return true;
      default:
        return false;
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2833),
        title: const Text('Leave Room?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to exit this game lobby?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1E56)),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(liveKitAudioServiceProvider).disconnect();
      await ref.read(gameControllerProvider.notifier).leaveRoom(widget.gameId);
      if (mounted) {
        context.go('/lobby');
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room code $code copied to clipboard!')),
    );
  }

  void _openMultiChannelChatDrawer(PlayerRole? myRole, bool isAlive) {
    setState(() {
      _unreadChatCount = 0;
      _isChatDrawerOpen = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: GameChatDrawer(
          roomId: widget.gameId,
          myRole: myRole,
          isAlive: isAlive,
        ),
      ),
    ).whenComplete(() {
      setState(() => _isChatDrawerOpen = false);
    });
  }

  void _showPlayerActionDialog(RoomPlayerEntity player, PlayerRole? role) {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    final isMe = player.userId == currentUser?.uid;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2833),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFC70039),
              backgroundImage: player.avatarUrl.isNotEmpty
                  ? NetworkImage(player.avatarUrl)
                  : null,
              child: player.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.displayName,
                      style: GoogleFonts.cinzel(
                          color: Colors.white, fontSize: 16)),
                  if (role != null)
                    Text(
                      'Role: ${role.title}',
                      style: TextStyle(
                          color: _getRoleColor(role),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          isMe
              ? 'This is your profile card.'
              : 'Send a friend request to ${player.displayName}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
          ),
          if (!isMe)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(socialRepositoryProvider)
                      .sendFriendRequestToPlayer(player);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Friend request sent to ${player.displayName}!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E56)),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('ADD FRIEND'),
            ),
        ],
      ),
    );
  }

  void _showInviteFriendsSheet(GameRoomEntity room) {
    InviteFriendsDialog.show(context, roomId: room.roomId, roomCode: room.code);
  }

  Future<void> _handleTargetAction(
      String targetUserId, PlayerRole? myRole, GamePhase phase) async {
    setState(() => _selectedActionTargetId = targetUserId);

    if (phase == GamePhase.dayVoting || phase == GamePhase.dayDiscussion) {
      await ref.read(gameControllerProvider.notifier).submitDayVote(
            roomId: widget.gameId,
            targetUserId: targetUserId,
          );
    } else {
      if (phase == GamePhase.nightDetective && myRole == PlayerRole.detective) {
        final targetDoc = await ref
            .read(gameRepositoryProvider)
            .getRoomPlayersStream(widget.gameId)
            .first;
        final targetPlayer =
            targetDoc.firstWhere((p) => p.userId == targetUserId);

        final targetRole =
            await ref.read(gameRepositoryProvider).getMyRole(widget.gameId);
        final isMafia = targetRole?.role == PlayerRole.mafia;

        setState(() {
          _investigationResult =
              '${targetPlayer.displayName} investigation submitted.';
        });
      }

      await ref.read(gameControllerProvider.notifier).submitPhaseAction(
            roomId: widget.gameId,
            targetUserId: targetUserId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<GameRoomEntity?>>(
      activeRoomStreamProvider(widget.gameId),
      (prev, next) {
        final prevPhase = prev?.value?.phase;
        final nextPhase = next.value?.phase;
        if (nextPhase != null && prevPhase != nextPhase) {
          setState(() {
            _selectedActionTargetId = null;
            _investigationResult = null;
          });
          _playPhaseNarration(nextPhase, next.value?.winningFaction);
        }
      },
    );

    final roomAsync = ref.watch(activeRoomStreamProvider(widget.gameId));
    final playersAsync = ref.watch(roomPlayersStreamProvider(widget.gameId));
    final myRoleAsync = ref.watch(myRoleStreamProvider(widget.gameId));
    final votesAsync = ref.watch(roomVotesStreamProvider(widget.gameId));
    final actionsAsync = ref.watch(roomActionsStreamProvider(widget.gameId));
    final activeSpeakersAsync = ref.watch(activeSpeakersProvider);
    final activeSpeakerIds = activeSpeakersAsync.value ?? {};
    final votesMap = votesAsync.value ?? {};
    final actionsMap = actionsAsync.value ?? {};
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    final myRoleObj = myRoleAsync.value;
    final myRole = myRoleObj?.role;

    final players = playersAsync.value ?? [];
    final myPlayer = players.cast<RoomPlayerEntity?>().firstWhere(
          (p) => p?.userId == currentUser?.uid,
          orElse: () => null,
        );
    final isAlive = myPlayer?.isAlive ?? true;

    // Dynamically update chat subscriptions based on myRole and isAlive
    _updateChatSubscriptions(myRole, isAlive);

    return Scaffold(
      appBar: AppBar(
        title: Text('MAFIA GAME',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveRoom,
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFFFF1E56)),
                onPressed: () {
                  _openMultiChannelChatDrawer(myRole, isAlive);
                },
                tooltip: 'Game Chat',
              ),
              if (_unreadChatCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedUnreadBadge(
                    count: _unreadChatCount,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Room closed or no longer exists.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/lobby'),
                    child: const Text('RETURN TO LOBBY'),
                  ),
                ],
              ),
            );
          }

          if (room.status == GameRoomStatus.lobby) {
            return _buildLobbyView(
                context, ref, room, playersAsync, currentUser);
          }

          if (room.status == GameRoomStatus.completed ||
              room.phase == GamePhase.gameOver) {
            return _buildGameOverView(context, room, playersAsync);
          }

          return playersAsync.when(
            data: (players) {
              final myPlayer = players.cast<RoomPlayerEntity?>().firstWhere(
                    (p) => p?.userId == currentUser?.uid,
                    orElse: () => null,
                  );
              final isAlive = myPlayer?.isAlive ?? false;

              if (!isAlive) {
                Future.microtask(() async {
                  try {
                    final audioService = ref.read(liveKitAudioServiceProvider);
                    if (audioService.isConnected) {
                      await audioService.setMicrophoneEnabled(false);
                    }
                  } catch (_) {}
                });
              }

              final canSelect = _canSelectTarget(myRole, room.phase, isAlive);

              final activeSpeakerNames = players
                  .where((p) => activeSpeakerIds.contains(p.userId))
                  .map((p) => p.displayName)
                  .join(', ');

              final sortedPlayers = List<RoomPlayerEntity>.from(players)
                ..sort((a, b) {
                  if (a.isAlive == b.isAlive) return 0;
                  return a.isAlive ? -1 : 1;
                });

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 12, bottom: 80),
                    child: Column(
                      children: [
                        const ModeratorNarrationBanner(),

                        // 3 NIGHT FACTS BANNER (DISPLAYED UPON SUNRISE / DAY PHASES)
                        if (room.phase == GamePhase.dayDiscussion ||
                            room.phase == GamePhase.dayVoting) ...[
                          _buildNightFactsBanner(players, room),
                          const SizedBox(height: 8),
                        ],

                        if (activeSpeakerNames.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.volume_up,
                                    color: Colors.greenAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🔊 $activeSpeakerNames is speaking...',
                                    style: GoogleFonts.inter(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // SECRET ROLE CARD
                        GestureDetector(
                          onTap: () =>
                              setState(() => _revealRole = !_revealRole),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2833),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRoleColor(myRole).withOpacity(0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _revealRole
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _getRoleColor(myRole),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'YOUR SECRET ROLE (Tap to ${_revealRole ? "Hide" : "Reveal"})',
                                        style: GoogleFonts.inter(
                                            fontSize: 9,
                                            color: Colors.white54,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _revealRole
                                            ? '${myRole?.title ?? "CIVILIAN"} (${myRole?.faction ?? "TOWN"})'
                                            : '•••••••••••••••••',
                                        style: GoogleFonts.cinzel(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _revealRole
                                              ? _getRoleColor(myRole)
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // PHASE STATUS & COUNTDOWN BANNER
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0C10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF1E56)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT PHASE',
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: Colors.white54,
                                        letterSpacing: 1),
                                  ),
                                  Text(
                                    _getPhaseTitle(room.phase),
                                    style: GoogleFonts.cinzel(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF1E56),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF1E56).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_remainingSeconds}s',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // GOOGLE MEET STYLE GRID
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: sortedPlayers.length,
                            itemBuilder: (context, idx) {
                              final p = sortedPlayers[idx];
                              final isSpeaking =
                                  activeSpeakerIds.contains(p.userId);
                              final isTargetable = canSelect &&
                                  p.isAlive &&
                                  (room.phase == GamePhase.nightDoctor ||
                                      p.userId != currentUser?.uid);

                              // Find voters for player p
                              final voterNames = votesMap.entries
                                  .where((e) => e.value == p.userId)
                                  .map((e) {
                                final voter = players.firstWhere(
                                  (pl) => pl.userId == e.key,
                                  orElse: () => RoomPlayerModel(
                                    userId: e.key,
                                    displayName: 'Agent',
                                    avatarUrl: '',
                                    slotIndex: 0,
                                    joinedAt: DateTime.now(),
                                  ),
                                );
                                return voter.displayName;
                              }).toList();

                              // Find mafia targeters for player p if I am mafia during nightMafia
                              List<String> mafiaNames = [];
                              if (myRole == PlayerRole.mafia &&
                                  room.phase == GamePhase.nightMafia) {
                                actionsMap.forEach((key, target) {
                                  if (key.startsWith('nightMafia') &&
                                      target == p.userId) {
                                    final actorUid =
                                        key.replaceFirst('nightMafia_', '');
                                    final mafiaPlayer = players.firstWhere(
                                      (pl) => pl.userId == actorUid,
                                      orElse: () => RoomPlayerModel(
                                        userId: actorUid,
                                        displayName: 'Mafia',
                                        avatarUrl: '',
                                        slotIndex: 0,
                                        joinedAt: DateTime.now(),
                                      ),
                                    );
                                    mafiaNames.add(mafiaPlayer.displayName);
                                  }
                                });
                              }

                              return GoogleMeetPlayerCard(
                                player: p,
                                isSpeaking: isSpeaking,
                                isSelected: _selectedActionTargetId == p.userId,
                                voterNames: voterNames,
                                mafiaTargeterNames: mafiaNames,
                                onTap: () {
                                  if (isTargetable) {
                                    _handleTargetAction(
                                        p.userId, myRole, room.phase);
                                  } else {
                                    _showPlayerActionDialog(p, null);
                                  }
                                },
                              );
                            },
                          ),
                        ),

                        if (room.phase == GamePhase.dayDiscussion &&
                            isAlive) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .toggleReadyToVote(widget.gameId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: room.readyToVoteUserIds
                                        .contains(currentUser?.uid)
                                    ? Colors.green
                                    : const Color(0xFF1F2833),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.how_to_vote),
                              label: Text(
                                'LET\'S VOTE (${room.readyToVoteUserIds.length}/${room.alivePlayerIds.length})',
                              ),
                            ),
                          ),
                        ],

                        if (room.hostId == currentUser?.uid) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .advanceGamePhase(widget.gameId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF1E56),
                                side:
                                    const BorderSide(color: Color(0xFFFF1E56)),
                              ),
                              icon: const Icon(Icons.fast_forward),
                              label: const Text('ADVANCE PHASE (HOST)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingAudioControls(
                        onDisconnect: _leaveRoom,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF1E56))),
            error: (err, _) => Center(
                child: Text('Error loading players: $err',
                    style: const TextStyle(color: Colors.redAccent))),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF1E56))),
        error: (err, _) => Center(
            child: Text('Error loading room: $err',
                style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildNightFactsBanner(
      List<RoomPlayerEntity> players, GameRoomEntity room) {
    final facts = room.nightFacts;
    final summary =
        facts?['summary'] ?? 'Sun rises over the city. No incident reported.';

    String displaySummary = summary;
    for (final p in players) {
      displaySummary = displaySummary.replaceAll(p.userId, p.displayName);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2833),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'SUNRISE NIGHT BRIEFING',
                style: GoogleFonts.cinzel(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displaySummary,
            style:
                const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(PlayerRole? role) {
    switch (role) {
      case PlayerRole.mafia:
        return const Color(0xFFFF1E56);
      case PlayerRole.doctor:
        return Colors.greenAccent;
      case PlayerRole.detective:
        return Colors.amberAccent;
      case PlayerRole.civilian:
      default:
        return Colors.lightBlueAccent;
    }
  }

  String _getPhaseTitle(GamePhase phase) {
    switch (phase) {
      case GamePhase.nightMafia:
        return 'NIGHT: MAFIA HUNT';
      case GamePhase.nightDoctor:
        return 'NIGHT: DOCTOR SAVE';
      case GamePhase.nightDetective:
        return 'NIGHT: DETECTIVE CHECK';
      case GamePhase.dayDiscussion:
        return 'DAY: DISCUSSION';
      case GamePhase.dayVoting:
        return 'DAY: VOTING ELIMINATION';
      case GamePhase.gameOver:
        return 'GAME OVER';
      case GamePhase.lobby:
      default:
        return 'LOBBY';
    }
  }

  Widget _buildLobbyView(
      BuildContext context,
      WidgetRef ref,
      GameRoomEntity room,
      AsyncValue<List<RoomPlayerEntity>> playersAsync,
      dynamic currentUser) {
    return playersAsync.when(
      data: (players) {
        final isHost = room.hostId == currentUser?.uid;
        final myPlayer = players.cast<RoomPlayerEntity?>().firstWhere(
              (p) => p?.userId == currentUser?.uid,
              orElse: () => null,
            );

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF689EEA), Color(0x8043275A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: const Color(0xFF7DD6FC), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black38,
                        blurRadius: 12,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ROOM CODE',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white54,
                                letterSpacing: 1.5)),
                        Text(
                          room.code,
                          style: GoogleFonts.cinzel(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF1E56),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('${players.length}/${room.maxPlayers}',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.white70)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () => _copyCode(room.code),
                          tooltip: 'Copy Room Code',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // INVITE FRIENDS BUTTON (AVAILABLE TO ALL PLAYERS)
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: () => _showInviteFriendsSheet(room),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFEF0E6),
                    backgroundColor: const Color(0x80689EEA),
                    side:
                        const BorderSide(color: Color(0xFF7DD6FC), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 24),
                  label: const Text('Invite Friends',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: room.maxPlayers,
                  itemBuilder: (context, index) {
                    final player = players.cast<RoomPlayerEntity?>().firstWhere(
                          (p) => p?.slotIndex == index,
                          orElse: () => null,
                        );

                    if (player == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0x8043275A).withOpacity(0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFF7DD6FC).withOpacity(0.55)),
                        ),
                        child: Center(
                          child: Text('Slot ${index + 1}',
                              style: GoogleFonts.inter(
                                  color: Colors.white24, fontSize: 12)),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _showPlayerActionDialog(player, null),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: player.isReady
                                ? const [Color(0xFF7DD6FC), Color(0x80689EEA)]
                                : const [Color(0x8043275A), Color(0x80301C40)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: player.isReady
                                ? const Color(0xFF7DD6FC)
                                : const Color(0xFFED77ED).withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFC70039),
                                  backgroundImage: player.avatarUrl.isNotEmpty
                                      ? NetworkImage(player.avatarUrl)
                                      : null,
                                  child: player.avatarUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white)
                                      : null,
                                ),
                                if (player.isHost)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.amber,
                                      child: Icon(Icons.star,
                                          size: 12, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              player.displayName,
                              style: GoogleFonts.cinzel(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: player.isReady
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                player.isReady ? 'READY' : 'WAITING',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: player.isReady
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (isHost)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(gameControllerProvider.notifier)
                        .startGame(widget.gameId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED77ED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START GAME'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(gameControllerProvider.notifier)
                        .toggleReadyStatus(widget.gameId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myPlayer?.isReady == true
                          ? const Color(0xFF689EEA)
                          : const Color(0x8043275A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                            color: Color(0xFF7DD6FC), width: 1.5),
                      ),
                    ),
                    icon: Icon(myPlayer?.isReady == true
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked),
                    label: Text(myPlayer?.isReady == true
                        ? 'I AM READY'
                        : 'MARK READY'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF1E56))),
      error: (err, _) => Center(
          child: Text('Error loading players: $err',
              style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Widget _buildGameOverView(BuildContext context, GameRoomEntity room,
      AsyncValue<List<RoomPlayerEntity>> playersAsync) {
    final winner = room.winningFaction ?? 'TOWN';

    return playersAsync.when(
      data: (players) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                winner == 'MAFIA' ? Icons.security : Icons.stars,
                size: 60,
                color: winner == 'MAFIA'
                    ? const Color(0xFFFF1E56)
                    : Colors.amberAccent,
              ),
              const SizedBox(height: 8),
              Text(
                '$winner VICTORY!',
                style: GoogleFonts.cinzel(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: winner == 'MAFIA'
                      ? const Color(0xFFFF1E56)
                      : Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                winner == 'MAFIA'
                    ? 'The Shadows took control of the city.'
                    : 'Law and order restored in the city.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text('SECRET ROLES REVEALED',
                  style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
              const SizedBox(height: 8),

              // REVEALED ROLES GRID
              Expanded(
                child: FutureBuilder<Map<String, PlayerRole>>(
                  future: _fetchAllPlayerRoles(room.roomId, players),
                  builder: (context, snapshot) {
                    final roleMap = snapshot.data ?? {};

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: players.length,
                      itemBuilder: (context, idx) {
                        final p = players[idx];
                        final role = roleMap[p.userId];
                        return GestureDetector(
                          onTap: () => _showPlayerActionDialog(p, role),
                          child: GoogleMeetPlayerCard(
                            player: p,
                            revealedRole: role,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(gameControllerProvider.notifier)
                          .resetRoomToLobby(widget.gameId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1E56),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.replay),
                      label: const Text('REMATCH'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/lobby'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('LOBBY'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF1E56))),
      error: (err, _) => Center(
          child: Text('Error loading results: $err',
              style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Future<Map<String, PlayerRole>> _fetchAllPlayerRoles(
      String roomId, List<RoomPlayerEntity> players) async {
    try {
      final gameRepo = ref.read(gameRepositoryProvider);
      return await gameRepo.getAllRoomRoles(roomId);
    } catch (e) {
      debugPrint('Error fetching all room roles: $e');
      return {};
    }
  }
}
