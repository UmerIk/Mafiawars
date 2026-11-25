// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/design/design_components.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/chat_providers.dart';
import 'widgets/direct_message_bubble.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  const FriendChatScreen(
      {super.key, required this.friendUid, required this.friendName});
  final String friendUid, friendName;
  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Future<void> _send() async {
    final draft = _text.text;
    final sent = await ref
        .read(directMessageSenderProvider(widget.friendUid).notifier)
        .send(draft);
    if (!mounted || !sent) return;
    // Keep anything typed while the previous message was being sent.
    if (_text.text == draft) _text.clear();
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(directMessagesProvider(widget.friendUid));
    final friend = ref.watch(chatUserProvider(widget.friendUid));
    final send = ref.watch(directMessageSenderProvider(widget.friendUid));
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    return MafiaPage(
        scrollable: false,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.viewInsetsOf(context).bottom > 0 ? 12 : 76, 20, 20),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: PageHeader(
                  title: friend.valueOrNull?.displayName ?? widget.friendName,
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/chats'),
                  trailing: AgentAvatar(
                      value: friend.valueOrNull?.avatarUrl ?? '',
                      size: 60,
                      online: friend.hasValue
                          ? friend.valueOrNull?.userStatus != 'offline' &&
                              friend.valueOrNull != null
                          : null))),
          if (friend.hasError)
            TextButton(
                onPressed: () =>
                    ref.invalidate(chatUserProvider(widget.friendUid)),
                child: const Text('Profile unavailable · Retry')),
          const SizedBox(height: 28),
          Expanded(
              child: messages.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => AsyncFeedback(
                      message: 'Could not load this conversation.',
                      onRetry: () => ref.invalidate(
                          directMessagesProvider(widget.friendUid))),
                  data: (data) {
                    if (data.isEmpty) {
                      return const AsyncFeedback(
                          message: 'No messages yet. Say hello!');
                    }
                    final sorted = [...data]..sort((a, b) {
                        final order = a.timestamp.compareTo(b.timestamp);
                        return order == 0 ? a.id.compareTo(b.id) : order;
                      });
                    return Align(
                        alignment: Alignment.topCenter,
                        child: ListView.builder(
                            shrinkWrap: sorted.length < 20,
                            controller: _scroll,
                            reverse: true,
                            padding: EdgeInsets.zero,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: sorted.length,
                            itemBuilder: (context, reverseIndex) {
                              final index = sorted.length - reverseIndex - 1;
                              final message = sorted[index];
                              final date = message.timestamp.toLocal();
                              final previous = index > 0
                                  ? sorted[index - 1].timestamp.toLocal()
                                  : null;
                              final newDay = previous == null ||
                                  DateUtils.dateOnly(previous) !=
                                      DateUtils.dateOnly(date);
                              return Column(
                                  key: ValueKey(message.id),
                                  children: [
                                    if (newDay) ChatDateDivider(date: date),
                                    DirectMessageBubble(
                                        message: message,
                                        isMine: message.senderId == uid)
                                  ]);
                            }));
                  })),
          if (send.hasError)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'Message could not be sent. Your draft is saved; try again.',
                    style: AppTypography.uiCaption
                        .copyWith(color: AppColors.figmaWhite))),
          const SizedBox(height: 10),
          AppTextField(
              controller: _text,
              hintText: 'type here',
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              suffixIcon: send.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      tooltip: 'Send message',
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded,
                          color: AppColors.figmaPink)))
        ]));
  }
}
