import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ProfileDialogType {
  friend,
  friendRequest,
  newUser,
}

class UserProfileDialog extends StatelessWidget {
  final String displayName;
  final String? streakDays;
  final int gamesPlayed;
  final int winAsMafia;
  final int winAsCitizen;
  final String winRatio;
  final String? avatarAsset;
  final ProfileDialogType type;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const UserProfileDialog({
    super.key,
    required this.displayName,
    this.streakDays = '25',
    this.gamesPlayed = 50,
    this.winAsMafia = 5,
    this.winAsCitizen = 30,
    this.winRatio = '75%',
    this.avatarAsset = 'assets/images/avatar_rayven.png',
    this.type = ProfileDialogType.friend,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  static Future<void> show(
    BuildContext context, {
    required String displayName,
    String? streakDays = '25',
    int gamesPlayed = 50,
    int winAsMafia = 5,
    int winAsCitizen = 30,
    String winRatio = '75%',
    String? avatarAsset = 'assets/images/avatar_rayven.png',
    ProfileDialogType type = ProfileDialogType.friend,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: UserProfileDialog(
          displayName: displayName,
          streakDays: streakDays,
          gamesPlayed: gamesPlayed,
          winAsMafia: winAsMafia,
          winAsCitizen: winAsCitizen,
          winRatio: winRatio,
          avatarAsset: avatarAsset,
          type: type,
          onPrimaryAction: onPrimaryAction,
          onSecondaryAction: onSecondaryAction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCC43275A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7DD6FC)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF43275A),
              border: Border.all(color: const Color(0xFF7DD6FC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCrimson.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                avatarAsset ?? 'assets/images/avatar_rayven.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.face_5,
                  color: Color(0xFFFEF0E6),
                  size: 50,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name & Streak
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFEF0E6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 18)),
              Text(
                '${streakDays ?? '25'} Days',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFEF0E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Rows
          _StatRow(label: 'Games Played', value: '$gamesPlayed'),
          const Divider(color: Colors.white24, height: 16),
          _StatRow(label: 'Win as Mafia', value: '$winAsMafia'),
          const Divider(color: Colors.white24, height: 16),
          _StatRow(label: 'Win as Citizen', value: '$winAsCitizen'),
          const Divider(color: Colors.white24, height: 16),
          _StatRow(label: 'Win ratio', value: winRatio),
          const SizedBox(height: 24),

          // Action Buttons depending on type
          if (type == ProfileDialogType.friend) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onPrimaryAction?.call();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0x8043275A),
                  side: const BorderSide(color: Color(0xFF7DD6FC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFEF0E6)),
                label: const Text(
                  'Remove Friend',
                  style: TextStyle(color: Color(0xFFFEF0E6), fontSize: 16),
                ),
              ),
            ),
          ] else if (type == ProfileDialogType.friendRequest) ...[
            Text(
              '$displayName has sent you a friend request!!',
              style: const TextStyle(color: Color(0xFFFEF0E6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSecondaryAction?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF383C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Decline', style: TextStyle(color: Color(0xFFFF383C))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPrimaryAction?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF34C759)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Accept', style: TextStyle(color: Color(0xFF34C759))),
                  ),
                ),
              ],
            ),
          ] else if (type == ProfileDialogType.newUser) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onPrimaryAction?.call();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0x8043275A),
                  side: const BorderSide(color: Color(0xFF7DD6FC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFFEF0E6)),
                label: const Text(
                  'Add Friend',
                  style: TextStyle(color: Color(0xFFFEF0E6), fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFEF0E6),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFEF0E6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
