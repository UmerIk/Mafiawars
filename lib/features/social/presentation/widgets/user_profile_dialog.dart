import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/design/agent_avatar.dart';
import '../../../../core/widgets/design/app_surface.dart';

enum ProfileDialogType { friend, friendRequest, newUser }

/// Shared Figma relationship dialog; unknown metrics are never sample numbers.
class UserProfileDialog extends StatelessWidget {
  const UserProfileDialog(
      {super.key,
      required this.displayName,
      this.streakDays,
      this.gamesPlayed,
      this.winAsMafia,
      this.winAsCitizen,
      this.winRatio,
      this.avatarAsset,
      this.avatarUrl,
      this.type = ProfileDialogType.friend,
      this.onPrimaryAction,
      this.onSecondaryAction});
  final String displayName;
  final String? streakDays, winRatio, avatarAsset, avatarUrl;
  final int? gamesPlayed, winAsMafia, winAsCitizen;
  final ProfileDialogType type;
  final VoidCallback? onPrimaryAction, onSecondaryAction;

  static Future<void> show(BuildContext context,
          {required String displayName,
          String? streakDays,
          int? gamesPlayed,
          int? winAsMafia,
          int? winAsCitizen,
          String? winRatio,
          String? avatarAsset,
          String? avatarUrl,
          ProfileDialogType type = ProfileDialogType.friend,
          VoidCallback? onPrimaryAction,
          VoidCallback? onSecondaryAction}) =>
      showDialog<void>(
          context: context,
          builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                      child: UserProfileDialog(
                          displayName: displayName,
                          streakDays: streakDays,
                          gamesPlayed: gamesPlayed,
                          winAsMafia: winAsMafia,
                          winAsCitizen: winAsCitizen,
                          winRatio: winRatio,
                          avatarAsset: avatarAsset,
                          avatarUrl: avatarUrl,
                          type: type,
                          onPrimaryAction: onPrimaryAction,
                          onSecondaryAction: onSecondaryAction)))));

  @override
  Widget build(BuildContext context) => AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AgentAvatar(value: avatarUrl ?? avatarAsset ?? '', size: 96),
        const SizedBox(height: 12),
        Text(displayName,
            textAlign: TextAlign.center, style: AppTypography.uiTitle),
        if (streakDays != null)
          Text('🔥 $streakDays Days', style: AppTypography.uiBody),
        const SizedBox(height: 28),
        _StatRow(label: 'Games Played', value: gamesPlayed?.toString() ?? '—'),
        _StatRow(label: 'Win as Mafia', value: winAsMafia?.toString() ?? '—'),
        _StatRow(
            label: 'Win as Citizen', value: winAsCitizen?.toString() ?? '—'),
        _StatRow(label: 'Win ratio', value: winRatio ?? '—'),
        const SizedBox(height: 24),
        if (type == ProfileDialogType.friendRequest) ...[
          Text('$displayName has sent you a friend request!',
              style: AppTypography.uiCaption, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: AppButton(
                    text: 'Reject',
                    variant: AppButtonVariant.danger,
                    onPressed: onSecondaryAction == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            onSecondaryAction!();
                          })),
            const SizedBox(width: 10),
            Expanded(
                child: AppButton(
                    text: 'Accept',
                    variant: AppButtonVariant.success,
                    onPressed: onPrimaryAction == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            onPrimaryAction!();
                          })),
          ])
        ] else
          AppButton(
              text: type == ProfileDialogType.friend
                  ? 'Remove Friend'
                  : 'Add Friend',
              isFullWidth: true,
              variant: type == ProfileDialogType.friend
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              icon: type == ProfileDialogType.friend
                  ? Icons.remove_circle_outline
                  : Icons.person_add_alt_1,
              onPressed: onPrimaryAction == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      onPrimaryAction!();
                    }),
      ]));
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label, style: AppTypography.uiBody)),
          Text(value,
              style: AppTypography.uiBody.copyWith(fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Colors.white24)
      ]));
}
