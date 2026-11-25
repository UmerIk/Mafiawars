// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/design/design_components.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/chat_providers.dart';
import 'providers/social_providers.dart';
import 'widgets/chat_contact_row.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final query = ref.watch(chatSearchProvider('inbox')).trim().toLowerCase();
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    return MafiaPage(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(30, 76, 30, 30),
        child: Column(children: [
          PageHeader(
              title: 'Messages',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/lobby'),
              trailing: AppIconButton(
                  icon: Icons.edit_square,
                  label: 'New chat',
                  onPressed: () => context.push('/new_chat'))),
          const SizedBox(height: 10),
          AppTextField(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, color: AppColors.figmaCyan),
              onChanged: (value) =>
                  ref.read(chatSearchProvider('inbox').notifier).state = value),
          const SizedBox(height: 50),
          Expanded(
              child: AppSurface(
                  radius: 20,
                  borderWidth: 0,
                  child: inbox.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => AsyncFeedback(
                          message: 'Could not load messages.',
                          onRetry: () => ref.invalidate(friendsStreamProvider)),
                      data: (state) {
                        final rows = state.conversations
                            .where((row) =>
                                row.friend.displayName
                                    .toLowerCase()
                                    .contains(query) ||
                                row.message.message
                                    .toLowerCase()
                                    .contains(query))
                            .toList();
                        return Column(children: [
                          if (state.loading) const LinearProgressIndicator(),
                          if (state.failedIds.isNotEmpty)
                            AsyncFeedback(
                                message: 'Some chats could not load.',
                                onRetry: () {
                                  for (final id in state.failedIds) {
                                    ref.invalidate(directMessagesProvider(id));
                                  }
                                }),
                          Expanded(
                              child: rows.isEmpty
                                  ? AsyncFeedback(
                                      message: state.loading
                                          ? 'Loading conversations…'
                                          : query.isNotEmpty
                                              ? 'No matching conversations.'
                                              : 'No conversations yet. Start a new chat.')
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      itemCount: rows.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                              height: 1,
                                              indent: 14,
                                              endIndent: 14,
                                              color: Colors.white24),
                                      itemBuilder: (_, index) {
                                        final row = rows[index];
                                        return ChatContactRow(
                                            key: ValueKey(row.friend.uid),
                                            name: row.friend.displayName,
                                            avatar: row.friend.avatarUrl,
                                            online:
                                                row.friend.status != 'offline',
                                            outlined: false,
                                            sender: row.message.senderId == uid
                                                ? 'You'
                                                : row.message.senderDisplayName,
                                            preview: row.message.message,
                                            onTap: () => context.push(Uri(
                                                    path:
                                                        '/social/chat/${row.friend.uid}',
                                                    queryParameters: {
                                                      'name':
                                                          row.friend.displayName
                                                    }).toString()));
                                      }))
                        ]);
                      })))
        ]));
  }
}
