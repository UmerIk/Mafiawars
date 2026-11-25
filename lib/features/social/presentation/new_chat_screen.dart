// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/design/design_components.dart';
import 'providers/chat_providers.dart';
import 'providers/social_providers.dart';
import 'widgets/chat_contact_row.dart';

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(chatSearchProvider('new')).trim().toLowerCase();
    final friends = ref.watch(friendsStreamProvider);
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(30, 76, 30, 30),
        child: Column(children: [
          PageHeader(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/chats')),
          const SizedBox(height: 10),
          AppTextField(
              hintText: 'Search Codename',
              prefixIcon: const Icon(Icons.search, color: AppColors.figmaCyan),
              onChanged: (value) =>
                  ref.read(chatSearchProvider('new').notifier).state = value),
          const SizedBox(height: 50),
          Expanded(
              child: friends.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => AsyncFeedback(
                      message: 'Could not load your agents.',
                      onRetry: () => ref.invalidate(friendsStreamProvider)),
                  data: (friends) {
                    final matches = friends
                        .where((friend) =>
                            friend.displayName.toLowerCase().contains(query))
                        .toList();
                    if (matches.isEmpty) {
                      return AsyncFeedback(
                          message: query.isEmpty
                              ? 'Add agents to your network to start a chat.'
                              : 'No agents match that codename.');
                    }
                    return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final friend = matches[index];
                          return ChatContactRow(
                              key: ValueKey(friend.uid),
                              name: friend.displayName,
                              avatar: friend.avatarUrl,
                              online: friend.status != 'offline',
                              onTap: () => context.push(Uri(
                                      path: '/social/chat/${friend.uid}',
                                      queryParameters: {
                                        'name': friend.displayName
                                      }).toString()));
                        });
                  }))
        ]));
  }
}
