import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/design/agent_network_row.dart';
import '../../../core/widgets/design/app_icon_button.dart';
import '../../../core/widgets/design/app_segmented_control.dart';
import '../../../core/widgets/design/mafia_page.dart';
import '../../auth/domain/entities/user_entity.dart';
import 'providers/social_providers.dart';
import 'providers/social_view_provider.dart';
import 'widgets/user_profile_dialog.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});
  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _action(Future<void> Function() action,
      {VoidCallback? success}) async {
    await action();
    if (mounted && !ref.read(socialControllerProvider).hasError)
      success?.call();
  }

  void _profile(
      {required String uid,
      required String name,
      required String avatar,
      required ProfileDialogType type,
      VoidCallback? primary,
      VoidCallback? secondary}) {
    showDialog<void>(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                    child: StreamBuilder<UserEntity?>(
                        stream: ref
                            .read(socialRepositoryProvider)
                            .getUserStream(uid),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          return UserProfileDialog(
                              displayName: user?.displayName ?? name,
                              avatarUrl: user?.avatarUrl ?? avatar,
                              gamesPlayed: user?.gamesPlayed,
                              winRatio: user != null && user.gamesPlayed > 0
                                  ? '${(100 * user.wins / user.gamesPlayed).round()}%'
                                  : null,
                              type: type,
                              onPrimaryAction: primary,
                              onSecondaryAction: secondary);
                        })))));
  }

  void _send(UserEntity user) => _action(
      () => ref.read(socialControllerProvider.notifier).sendFriendRequest(user),
      success: () => ref.read(socialViewProvider.notifier).markSent(user.uid));

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(socialViewProvider);
    final controller = ref.read(socialViewProvider.notifier);
    final busy = ref.watch(socialControllerProvider).isLoading;
    final friends = ref.watch(friendsStreamProvider);
    final requests = ref.watch(pendingRequestsStreamProvider);
    ref.listen(socialControllerProvider, (_, next) {
      if (next.hasError)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Couldn’t complete that action. Please try again.')));
    });
    return MafiaPage(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        AppIconButton(
            icon: Icons.arrow_back,
            label: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/lobby')),
        const SizedBox(width: 12),
        Expanded(
            child: AppSegmentedControl(
                labels: const ['Requests', 'Friends'],
                icons: const [Icons.person_add_alt_1, Icons.group],
                selectedIndex: view.tab,
                onSelected: controller.selectTab))
      ]),
      const SizedBox(height: 12),
      AppTextField(
          controller: _search,
          hintText: 'Search codename',
          onChanged: controller.search,
          prefixIcon: const Icon(Icons.search, color: AppColors.figmaBlue)),
      const SizedBox(height: 50),
      if (view.query.trim().isNotEmpty)
        if (view.searching)
          const Center(child: CircularProgressIndicator())
        else if (view.error != null)
          _message(view.error!)
        else if (view.results.isEmpty)
          _message('No agents found.')
        else
          ...view.results.map((user) => Padding(
              key: ValueKey(user.uid),
              padding: const EdgeInsets.only(bottom: 12),
              child: AgentNetworkRow(
                  name: user.displayName,
                  avatar: user.avatarUrl,
                  online: user.userStatus != 'offline',
                  action: view.sent.contains(user.uid)
                      ? 'Request Sent'
                      : 'Add Friend',
                  icon: Icons.person_add_alt_1,
                  onAction: busy || view.sent.contains(user.uid)
                      ? null
                      : () => _send(user),
                  onProfile: () => _profile(
                      uid: user.uid,
                      name: user.displayName,
                      avatar: user.avatarUrl,
                      type: ProfileDialogType.newUser,
                      primary: view.sent.contains(user.uid)
                          ? null
                          : () => _send(user)))))
      else if (view.tab == 1)
        friends.when(
            data: (items) => items.isEmpty
                ? _message(
                    'Your network starts here. Search for an agent to add a friend.')
                : Column(
                    children: items
                        .map((friend) => Padding(
                            key: ValueKey(friend.uid),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AgentNetworkRow(
                                name: friend.displayName,
                                avatar: friend.avatarUrl,
                                online: friend.status != 'offline',
                                subtitle: friend.status == 'in_game'
                                    ? 'In game'
                                    : friend.status == 'online'
                                        ? 'Online'
                                        : 'Offline',
                                action: 'Message',
                                icon: Icons.chat_bubble_rounded,
                                onAction: () => context.push(
                                    '/social/chat/${friend.uid}?name=${Uri.encodeComponent(friend.displayName)}'),
                                onProfile: () => _profile(
                                    uid: friend.uid,
                                    name: friend.displayName,
                                    avatar: friend.avatarUrl,
                                    type: ProfileDialogType.friend,
                                    primary: () => _action(() => ref
                                        .read(socialControllerProvider.notifier)
                                        .removeFriend(friend.uid))))))
                        .toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _retry('Couldn’t load your friends.',
                () => ref.invalidate(friendsStreamProvider)))
      else
        requests.when(
            data: (items) => items.isEmpty
                ? _message('No pending friend requests.')
                : Column(
                    children: items
                        .map((request) => Padding(
                            key: ValueKey(request.id),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AgentNetworkRow(
                                name: request.senderDisplayName,
                                avatar: request.senderAvatarUrl,
                                action: 'Accept',
                                onAction: busy
                                    ? null
                                    : () => _action(() => ref
                                        .read(socialControllerProvider.notifier)
                                        .acceptFriendRequest(request)),
                                onProfile: () => _profile(
                                    uid: request.senderId,
                                    name: request.senderDisplayName,
                                    avatar: request.senderAvatarUrl,
                                    type: ProfileDialogType.friendRequest,
                                    primary: () => _action(() => ref
                                        .read(socialControllerProvider.notifier)
                                        .acceptFriendRequest(request)),
                                    secondary: () => _action(
                                        () => ref.read(socialControllerProvider.notifier).rejectFriendRequest(request.id))))))
                        .toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _retry('Couldn’t load friend requests.', () => ref.invalidate(pendingRequestsStreamProvider))),
    ]));
  }

  Widget _message(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child:
          Text(text, style: AppTypography.uiBody, textAlign: TextAlign.center));
  Widget _retry(String text, VoidCallback onRetry) => Column(children: [
        _message(text),
        TextButton(onPressed: onRetry, child: const Text('Try again'))
      ]);
}
