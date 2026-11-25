// Created by Hamza Ali on 2026-11-25.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../game/domain/entities/chat_message_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/social_repository.dart';
import 'social_providers.dart';

final directMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessageEntity>, String>((ref, uid) =>
        ref.watch(socialRepositoryProvider).getDirectChatStream(uid));
final chatUserProvider = StreamProvider.autoDispose.family<UserEntity?, String>(
    (ref, uid) => ref.watch(socialRepositoryProvider).getUserStream(uid));
final chatSearchProvider =
    StateProvider.autoDispose.family<String, String>((ref, screen) => '');

class ConversationPreview {
  const ConversationPreview(this.friend, this.message);
  final FriendEntity friend;
  final ChatMessageEntity message;
}

class InboxState {
  const InboxState(
      {required this.conversations,
      required this.loading,
      required this.failedIds});
  final List<ConversationPreview> conversations;
  final bool loading;
  final List<String> failedIds;
}

/// The current API exposes messages per friend, but no conversation index.
/// Riverpod cancels each message subscription when the inbox/friend disappears.
final inboxProvider = Provider.autoDispose<AsyncValue<InboxState>>((ref) {
  final friends = ref.watch(friendsStreamProvider);
  return friends.when(
      data: (friends) {
        final rows = <ConversationPreview>[];
        final failed = <String>[];
        var loading = false;
        for (final friend in friends) {
          final messages = ref.watch(directMessagesProvider(friend.uid));
          loading |= messages.isLoading;
          if (messages.hasError) failed.add(friend.uid);
          final data = messages.valueOrNull;
          if (data != null && data.isNotEmpty) {
            final latest =
                data.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
            rows.add(ConversationPreview(friend, latest));
          }
        }
        rows.sort((a, b) {
          final order = b.message.timestamp.compareTo(a.message.timestamp);
          return order == 0 ? a.friend.uid.compareTo(b.friend.uid) : order;
        });
        return AsyncData(InboxState(
            conversations: rows, loading: loading, failedIds: failed));
      },
      loading: () => const AsyncLoading(),
      error: (error, stack) => AsyncError(error, stack));
});

class DirectMessageSender extends StateNotifier<AsyncValue<void>> {
  DirectMessageSender(this.repository, this.uid) : super(const AsyncData(null));
  final SocialRepository repository;
  final String uid;
  Future<bool> send(String draft) async {
    if (state.isLoading || draft.trim().isEmpty) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
        repository.sendDirectMessage(friendUid: uid, message: draft.trim()));
    if (mounted) state = result;
    return !result.hasError;
  }
}

final directMessageSenderProvider = StateNotifierProvider.autoDispose
    .family<DirectMessageSender, AsyncValue<void>, String>((ref, uid) =>
        DirectMessageSender(ref.watch(socialRepositoryProvider), uid));
