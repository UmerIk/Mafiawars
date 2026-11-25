// Created by Hamza Ali on 2026-11-25.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../providers/social_providers.dart';

final _queryProvider =
    StateProvider.autoDispose.family<String, String>((ref, roomId) => '');
final _sentProvider =
    StateProvider.autoDispose.family<Set<String>, String>((ref, roomId) => {});
final _pendingProvider =
    StateProvider.autoDispose.family<Set<String>, String>((ref, roomId) => {});
final _errorProvider =
    StateProvider.autoDispose.family<String?, String>((ref, roomId) => null);

/// Searches the existing friend stream and sends through the unchanged repository.
class InviteFriendsDialog extends ConsumerWidget {
  const InviteFriendsDialog(
      {super.key, required this.roomId, required this.roomCode});
  final String roomId, roomCode;

  static Future<void> show(BuildContext context,
          {required String roomId, required String roomCode}) =>
      showDialog<void>(
          context: context,
          builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: InviteFriendsDialog(roomId: roomId, roomCode: roomCode)));

  Future<void> _invite(WidgetRef ref, String uid) async {
    final pending = ref.read(_pendingProvider(roomId));
    if (pending.contains(uid) || ref.read(_sentProvider(roomId)).contains(uid)) {
      return;
    }
    ref.read(_pendingProvider(roomId).notifier).state = {...pending, uid};
    ref.read(_errorProvider(roomId).notifier).state = null;
    try {
      await ref
          .read(socialRepositoryProvider)
          .sendGameInvite(friendUid: uid, roomCode: roomCode, roomId: roomId);
      if (!ref.context.mounted) return;
      ref.read(_sentProvider(roomId).notifier).state = {
        ...ref.read(_sentProvider(roomId)),
        uid
      };
    } catch (_) {
      if (!ref.context.mounted) return;
      ref.read(_errorProvider(roomId).notifier).state =
          'Couldn’t send the invitation. Please try again.';
    } finally {
      if (ref.context.mounted) {
        ref.read(_pendingProvider(roomId).notifier).state = {
          ...ref.read(_pendingProvider(roomId))
        }..remove(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsStreamProvider);
    final query = ref.watch(_queryProvider(roomId));
    final sent = ref.watch(_sentProvider(roomId));
    final pending = ref.watch(_pendingProvider(roomId));
    final error = ref.watch(_errorProvider(roomId));
    return SizedBox(
        width: 400,
        height: math.min(750, MediaQuery.sizeOf(context).height * .8),
        child: AppSurface(
            radius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Text('Invite Friends', style: AppTypography.uiTitle),
              const SizedBox(height: 4),
              const Text('Invite your friends to this game',
                  style: AppTypography.uiCaption),
              const SizedBox(height: 28),
              AppTextField(
                  hintText: 'Search Codename',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.figmaCyan),
                  onChanged: (value) =>
                      ref.read(_queryProvider(roomId).notifier).state = value),
              const SizedBox(height: 28),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error,
                        style: AppTypography.uiCaption
                            .copyWith(color: AppColors.error))),
              Expanded(
                  child: friends.when(
                      data: (items) {
                        final matches = items
                            .where((item) => item.displayName
                                .toLowerCase()
                                .contains(query.trim().toLowerCase()))
                            .toList();
                        if (matches.isEmpty) {
                          return Center(
                              child: Text(
                                  items.isEmpty
                                      ? 'No friends added yet.'
                                      : 'No matching friends.',
                                  style: AppTypography.uiBody));
                        }
                        return ListView.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final friend = matches[index];
                              return AgentNetworkRow(
                                  key: ValueKey(friend.uid),
                                  name: friend.displayName,
                                  avatar: friend.avatarUrl,
                                  online: friend.status != 'offline',
                                  action: sent.contains(friend.uid)
                                      ? 'Invited'
                                      : 'Invite',
                                  icon: Icons.mark_email_unread_outlined,
                                  busy: pending.contains(friend.uid),
                                  onAction: sent.contains(friend.uid) ||
                                          pending.contains(friend.uid)
                                      ? null
                                      : () => _invite(ref, friend.uid));
                            });
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                const Text('Couldn’t load friends.',
                                    style: AppTypography.uiBody),
                                TextButton(
                                    onPressed: () =>
                                        ref.invalidate(friendsStreamProvider),
                                    child: const Text('Try again'))
                              ])))),
            ])));
  }
}
