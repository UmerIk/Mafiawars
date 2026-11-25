import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/design/app_sheet.dart';
import '../../../../core/widgets/design/app_surface.dart';
import '../../../game/presentation/providers/game_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';

final _invitesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>(
    (ref) => ref.watch(socialRepositoryProvider).getGameInvitesStream());
// The current repository has no decline/consume endpoint. Dismissal stays local.
final _dismissedInvitesProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

class GameInviteSheet extends ConsumerWidget {
  const GameInviteSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GameInviteSheet());
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(_invitesProvider);
    final dismissed = ref.watch(_dismissedInvitesProvider);
    final game = ref.watch(gameControllerProvider);
    return AppSheet(
        title: 'Active invites',
        child: invites.when(
            data: (items) {
              final visible = items
                  .where((item) => !dismissed.contains(item['id']))
                  .toList();
              if (visible.isEmpty)
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No active invitations.',
                        style: AppTypography.uiBody));
              return ListView.separated(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final invite = visible[index];
                    return AppSurface(
                        key: ValueKey(invite['id']),
                        radius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          Text(
                              '${invite['senderName'] ?? 'An agent'} has invited you to join the game',
                              textAlign: TextAlign.center,
                              style: AppTypography.uiBody),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(
                                child: AppButton(
                                    text: 'Decline',
                                    compact: true,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () => ref
                                            .read(_dismissedInvitesProvider
                                                .notifier)
                                            .state = {
                                          ...dismissed,
                                          invite['id'] as String
                                        })),
                            const SizedBox(width: 10),
                            Expanded(
                                child: AppButton(
                                    text: 'Join',
                                    compact: true,
                                    isLoading: game.isLoading,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: game.isLoading
                                        ? null
                                        : () async {
                                            final room = await ref
                                                .read(gameControllerProvider
                                                    .notifier)
                                                .joinRoomByCode(
                                                    invite['roomCode']
                                                            as String? ??
                                                        '');
                                            if (!context.mounted) return;
                                            if (room != null) {
                                              final router =
                                                  GoRouter.of(context);
                                              Navigator.pop(context);
                                              router
                                                  .push('/game/${room.roomId}');
                                            }
                                          })),
                          ]),
                          if (game.hasError)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                    'Couldn’t join this room. Please try again.',
                                    style: AppTypography.uiCaption)),
                        ]));
                  });
            },
            loading: () => const Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator()),
            error: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Couldn’t load invitations.',
                      style: AppTypography.uiBody),
                  TextButton(
                      onPressed: () => ref.invalidate(_invitesProvider),
                      child: const Text('Try again')),
                ])));
  }
}
