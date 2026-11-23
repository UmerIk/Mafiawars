import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/presentation/widgets/edit_profile_dialog.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../game/presentation/providers/game_providers.dart';
import '../../social/presentation/providers/social_providers.dart';
import 'widgets/game_invite_sheet.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  StreamSubscription? _inviteSub;

  final List<Map<String, dynamic>> _agentAvatars = const [
    {
      'name': 'AgentX',
      'image': 'assets/images/avatar_agentx.png',
      'online': true
    },
    {
      'name': 'Friday13',
      'image': 'assets/images/avatar_friday13.png',
      'online': true
    },
    {
      'name': 'PandaRed',
      'image': 'assets/images/avatar_pandared.png',
      'online': true
    },
    {
      'name': 'Rayven',
      'image': 'assets/images/avatar_rayven.png',
      'online': true
    },
    {
      'name': 'Cypork',
      'image': 'assets/images/avatar_cypork.png',
      'online': false
    },
  ];

  @override
  void initState() {
    super.initState();
    _listenToIncomingGameInvites();
    _initFcmToken();
  }

  Future<void> _initFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'status': 'online',
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('FCM Token init error: $e');
    }
  }

  void _listenToIncomingGameInvites() {
    Future.microtask(() {
      try {
        final socialRepo = ref.read(socialRepositoryProvider);
        _inviteSub = socialRepo.getGameInvitesStream().listen((invites) {
          if (invites.isNotEmpty && mounted) {
            GameInviteSheet.show(context);
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _inviteSub?.cancel();
    super.dispose();
  }

  void _openEditProfileDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    );
  }

  Future<void> _createRoom() async {
    final room = await ref.read(gameControllerProvider.notifier).createRoom();
    if (mounted && room != null) {
      context.push('/game/${room.roomId}');
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit room code.')),
      );
      return;
    }

    final room =
        await ref.read(gameControllerProvider.notifier).joinRoomByCode(code);
    if (mounted) {
      final gameState = ref.read(gameControllerProvider);
      if (!gameState.hasError && room != null) {
        context.push('/game/${room.roomId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateChangesProvider);
    final gameState = ref.watch(gameControllerProvider);
    final isLoading = gameState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // High-Res Noir Skyline Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF43275A),
                      Color(0xFF341F46),
                      Color(0xFF191024),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          SafeArea(
            child: userAsync.when(
              data: (user) {
                final gamesPlayed = user?.gamesPlayed ?? 50;
                final wins = user?.wins ?? 35;
                final winRate = gamesPlayed > 0
                    ? ((wins / gamesPlayed) * 100).toStringAsFixed(0)
                    : '75';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: [
                      // 1. TOP PROFILE CARD
                      InkWell(
                        onTap: () => user != null
                            ? _openEditProfileDialog(user)
                            : context.push('/profile_setup'),
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xB35C72D3), Color(0xB343275A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: const Color(0xFFED77ED), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF43275A),
                                  border: Border.all(
                                      color: const Color(0xFF7DD6FC), width: 2),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/avatar_raven.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.pets,
                                      color: Color(0xFFFEF0E6),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName ?? 'Agent47',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFEF0E6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      children: [
                                        Text('🔥 ',
                                            style: TextStyle(fontSize: 14)),
                                        Text(
                                          '25 ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFEF0E6),
                                          ),
                                        ),
                                        Text(
                                          'Days',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFFFEF0E6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFFFEF0E6), size: 24),
                                onPressed: () => user != null
                                    ? _openEditProfileDialog(user)
                                    : context.push('/profile_setup'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),

                      // 2. STATS & NEON GRAPH CARD
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xA65C72D3), Color(0xA643275A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                              color: const Color(0xFF7DD6FC), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80000000),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Neon Line Chart Box
                            Container(
                              width: 146,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF191024),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: const Color(0xFFED77ED), width: 1),
                              ),
                              child: CustomPaint(
                                painter: _NeonChartPainter(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Stats Column
                            Expanded(
                              child: Column(
                                children: [
                                  _DashboardStatRow(
                                      label: 'Games Played',
                                      value: '$gamesPlayed'),
                                  const _DashedDivider(),
                                  const _DashboardStatRow(
                                      label: 'Win as Mafia', value: '5'),
                                  const _DashedDivider(),
                                  const _DashboardStatRow(
                                      label: 'Win as Citizen', value: '30'),
                                  const _DashedDivider(),
                                  _DashboardStatRow(
                                      label: 'Win ratio', value: '$winRate%'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 3. AGENTS NETWORK & FLOATING BUTTONS ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Agents Network Card
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/social'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 127,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xAA5B65C0),
                                      Color(0xAA43275A),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(19),
                                  border: Border.all(
                                      color: const Color(0xFF7DD6FC),
                                      width: 1.2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x80000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Avatars Row
                                    SizedBox(
                                      height: 52,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _agentAvatars.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, idx) {
                                          final item = _agentAvatars[idx];
                                          return Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: const Color(
                                                          0xFF43275A),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFF7DD6FC)),
                                                    ),
                                                    child: ClipOval(
                                                      child: Image.asset(
                                                        item['image'] as String,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                const Icon(
                                                          Icons.person,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (item['online'] == true)
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xFF34C759),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['name'] as String,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Agents Network',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFEF0E6),
                                          ),
                                        ),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF7DD6FC),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.black,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right Column Floating Action Buttons
                          Column(
                            children: [
                              // Mail Invite Button (60x60, rounded 20)
                              InkWell(
                                onTap: () => GameInviteSheet.show(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0x8043275A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF7DD6FC)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x80000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_unread,
                                    color: Color(0xFFFEF0E6),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Chat Messages Button (60x60, rounded 20)
                              InkWell(
                                onTap: () => context.push('/social'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0x8043275A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF7DD6FC)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x80000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble,
                                    color: Color(0xFFFEF0E6),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. JOIN ROOM CARD
                      Container(
                        height: 114,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xAA43275A), Color(0xAA301C40)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                              color: const Color(0xFF7DD6FC), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80000000),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 94,
                              height: 100,
                              child: Image.asset(
                                'assets/images/4b992b910e8c455d50a55e831ba0b284f4d1c0d2',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.chair_alt,
                                  color: Color(0xFF7DD6FC),
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Join Room',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFEF0E6),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Enter a 6 digit code to join',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.silverMist,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Code Input Box with embedded Submit Arrow
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.only(
                                        left: 14, right: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF49306C),
                                          Color(0xFF301C40),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFF7DD6FC),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF7DD6FC)
                                              .withOpacity(0.14),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _roomCodeController,
                                            style: const TextStyle(
                                              color: Color(0xFFFEF0E6),
                                              fontSize: 15,
                                              letterSpacing: 2,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              hintText: 'AXDV28',
                                              hintStyle: TextStyle(
                                                  color: Color(0xFF689EEA)),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: isLoading ? null : _joinRoom,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF689EEA),
                                              shape: BoxShape.circle,
                                            ),
                                            child: isLoading
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  )
                                                : const Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. CREATE A ROOM CARD
                      InkWell(
                        onTap: isLoading ? null : _createRoom,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 86,
                          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xAA43275A), Color(0xAA301C40)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                                color: const Color(0xFFED77ED), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Create a Room',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFEF0E6),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Enter a 6 digit code to join',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.silverMist,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/cd33c0515bb930b903caf42d4052da9beb170409',
                                  width: 112,
                                  height: 78,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 112,
                                    height: 78,
                                    child: Icon(
                                      Icons.add_home_work,
                                      color: Color(0xFF7DD6FC),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. IN-PERSON PLAY CARD
                      InkWell(
                        onTap: () => context.push('/in_person'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 86,
                          padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xAA43275A), Color(0xAA301C40)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                                color: const Color(0xFFED77ED), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.asset(
                                  'assets/images/c9c43a001f94212ee7daebf473212798db09260b',
                                  width: 104,
                                  height: 82,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 104,
                                    height: 82,
                                    child: Icon(
                                      Icons.groups,
                                      color: Color(0xFF7DD6FC),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'In-person Play',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFEF0E6),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Enter a 6 digit code to join',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.silverMist,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF7DD6FC)),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading lobby: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFEF0E6),
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFEF0E6),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.maxWidth;
          const dashWidth = 4.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white24),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _NeonChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    // Grid lines
    for (double x = 0; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.7);
    greenPath.lineTo(size.width * 0.22, size.height * 0.28);

    final redPath = Path();
    redPath.moveTo(size.width * 0.22, size.height * 0.28);
    redPath.lineTo(size.width * 0.42, size.height * 0.78);

    final greenPath2 = Path();
    greenPath2.moveTo(size.width * 0.42, size.height * 0.78);
    greenPath2.lineTo(size.width * 0.72, size.height * 0.18);
    greenPath2.lineTo(size.width * 0.88, size.height * 0.38);
    greenPath2.lineTo(size.width, size.height * 0.28);

    final greenPaint = Paint()
      ..color = const Color(0xFF34C759)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final redPaint = Paint()
      ..color = const Color(0xFFFF383C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(redPath, redPaint);
    canvas.drawPath(greenPath2, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
