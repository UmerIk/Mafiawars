import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../game/domain/entities/chat_message_entity.dart';
import 'providers/social_providers.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  final String friendUid;
  final String friendName;

  const FriendChatScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await ref.read(socialRepositoryProvider).sendDirectMessage(
          friendUid: widget.friendUid,
          message: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final socialRepo = ref.watch(socialRepositoryProvider);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7D75D9),
                      Color(0xFF43275A),
                      Color(0xFF191024)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.12))),
          Container(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0x8043275A),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF7DD6FC)),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFFFEF0E6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.friendName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFEF0E6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        StreamBuilder<UserEntity?>(
                          stream: socialRepo.getUserStream(widget.friendUid),
                          builder: (context, snapshot) {
                            final isOnline =
                                snapshot.data?.userStatus == 'online';
                            return Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF43275A),
                                    border: Border.all(
                                        color: const Color(0xFF7DD6FC)),
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white),
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34C759),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.black, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Date Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.only(left: 30, right: 12),
                          ),
                        ),
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFEF0E6),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.only(left: 12, right: 30),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages Stream
                  Expanded(
                    child: StreamBuilder<List<ChatMessageEntity>>(
                      stream: socialRepo.getDirectChatStream(widget.friendUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF7DD6FC)),
                          );
                        }

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          itemCount: messages.length,
                          itemBuilder: (context, idx) {
                            final msg = messages[idx];
                            final isMe = msg.senderId == currentUser?.uid;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF689EEA)
                                      : const Color(0xFFED77ED),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isMe
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.message,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isMe) ...[
                                          const Icon(
                                            Icons.done_all,
                                            size: 16,
                                            color: Color(0xFFFEF0E6),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        const Text(
                                          'Just now',
                                          style: TextStyle(
                                            color: Color(0xFFFEF0E6),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
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

                  // Bottom Input Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF301C40),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF7DD6FC)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              onSubmitted: (_) => _sendMessage(),
                              style: const TextStyle(
                                color: Color(0xFFFEF0E6),
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                hintText: 'type here',
                                hintStyle: TextStyle(color: Color(0xFF689EEA)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF7DD6FC),
                              size: 24,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
