import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/game_room_entity.dart';
import '../providers/game_providers.dart';
import 'animated_unread_badge.dart';

final activeChatChannelProvider = StateProvider.family<String, String>((ref, roomId) => 'public');

class GameChatDrawer extends ConsumerStatefulWidget {
  final String roomId;
  final PlayerRole? myRole;
  final bool isAlive;

  const GameChatDrawer({
    super.key,
    required this.roomId,
    this.myRole,
    this.isAlive = true,
  });

  @override
  ConsumerState<GameChatDrawer> createState() => _GameChatDrawerState();
}

class _GameChatDrawerState extends ConsumerState<GameChatDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  final List<String> _availableChannels = [];
  final Map<String, int> _channelUnreadCounts = {};
  final List<StreamSubscription?> _channelSubs = [];

  @override
  void initState() {
    super.initState();
    if (widget.isAlive) {
      _availableChannels.add('public');
      if (widget.myRole == PlayerRole.mafia) {
        _availableChannels.add('mafia');
      }
    } else {
      // Dead players: Read-only public & mafia (if mafia), but ACTIVE chat in ghost channel
      _availableChannels.add('public');
      _availableChannels.add('ghost');
      if (widget.myRole == PlayerRole.mafia) {
        _availableChannels.add('mafia');
      }
    }

    _tabController =
        TabController(length: _availableChannels.length, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index < _availableChannels.length) {
        final activeChannel = _availableChannels[_tabController.index];
        if ((_channelUnreadCounts[activeChannel] ?? 0) > 0) {
          setState(() {
            _channelUnreadCounts[activeChannel] = 0;
          });
        }
      }
    });

    _subscribeToChannelUnread();
  }

  void _subscribeToChannelUnread() {
    final chatRepo = ref.read(gameRepositoryProvider);
    for (final channel in _availableChannels) {
      _channelUnreadCounts[channel] = 0;
      int lastCount = -1;
      final sub = chatRepo
          .getMultiChannelChatStream(roomId: widget.roomId, channel: channel)
          .listen((msgs) {
        if (lastCount >= 0) {
          final activeChannel = _availableChannels[_tabController.index];
          if (channel != activeChannel && msgs.length > lastCount) {
            if (mounted) {
              setState(() {
                _channelUnreadCounts[channel] =
                    (_channelUnreadCounts[channel] ?? 0) + (msgs.length - lastCount);
              });
            }
          }
        }
        lastCount = msgs.length;
      });
      _channelSubs.add(sub);
    }
  }

  @override
  void dispose() {
    for (final sub in _channelSubs) {
      sub?.cancel();
    }
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'mafia':
        return const Color(0xFFFF1E56);
      case 'ghost':
        return Colors.purpleAccent;
      case 'public':
      default:
        return Colors.lightBlueAccent;
    }
  }

  Future<void> _sendMessage(String channel) async {
    // If dead, only allow typing in 'ghost' channel
    if (!widget.isAlive && channel != 'ghost') return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await ref.read(gameRepositoryProvider).sendMultiChannelChatMessage(
          roomId: widget.roomId,
          message: text,
          channel: channel,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: Color(0xFF1F2833),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.chat, color: Color(0xFFFF1E56)),
              const SizedBox(width: 10),
              Text(
                widget.isAlive ? 'AGENT CHAT' : 'AGENT CHAT (💀 GHOST CHAT ACTIVE)',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CHANNEL TABS WITH UNREAD ANIMATED BADGES
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFF1E56),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: _availableChannels.map((channel) {
              final title = channel.toUpperCase();
              final unread = _channelUnreadCounts[channel] ?? 0;
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      channel == 'mafia'
                          ? Icons.security
                          : channel == 'ghost'
                              ? Icons.visibility_off
                              : Icons.public,
                      size: 16,
                      color: _getChannelColor(channel),
                    ),
                    const SizedBox(width: 6),
                    Text(title, style: const TextStyle(fontSize: 11)),
                    if (unread > 0) ...[
                      const SizedBox(width: 4),
                      AnimatedUnreadBadge(
                        count: unread,
                        fontSize: 8,
                        padding: const EdgeInsets.all(4),
                        badgeColor: _getChannelColor(channel),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _availableChannels.map((channel) {
                return _buildChannelChatView(context, ref, channel, currentUser?.uid);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelChatView(
      BuildContext context, WidgetRef ref, String channel, String? currentUid) {
    final chatRepo = ref.watch(gameRepositoryProvider);
    final canType = widget.isAlive || channel == 'ghost';

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessageEntity>>(
            stream: chatRepo.getMultiChannelChatStream(
                roomId: widget.roomId, channel: channel),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF1E56)));
              }

              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages in $channel channel.',
                    style: const TextStyle(color: Colors.white38),
                  ),
                );
              }

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];
                  final isMe = msg.senderId == currentUid;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? _getChannelColor(channel).withOpacity(0.8)
                            : const Color(0xFF0B0C10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.senderDisplayName,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.message,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // INPUT FIELD OR READ-ONLY BANNER
        if (canType) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: channel == 'ghost'
                        ? 'Type message in Ghost chat...'
                        : 'Type message in $channel channel...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0B0C10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: _getChannelColor(channel)),
                onPressed: () => _sendMessage(channel),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  '💀 Dead agents have read-only access to this channel.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
