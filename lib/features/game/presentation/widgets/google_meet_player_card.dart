import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/game_room_entity.dart';

class GoogleMeetPlayerCard extends StatefulWidget {
  final RoomPlayerEntity player;
  final bool isSpeaking;
  final bool isSelected;
  final VoidCallback? onTap;
  final PlayerRole? revealedRole;
  final List<String> voterNames;
  final List<String> mafiaTargeterNames;
  final String? statusLabel;

  const GoogleMeetPlayerCard({
    super.key,
    required this.player,
    this.isSpeaking = false,
    this.isSelected = false,
    this.onTap,
    this.revealedRole,
    this.voterNames = const [],
    this.mafiaTargeterNames = const [],
    this.statusLabel,
  });

  @override
  State<GoogleMeetPlayerCard> createState() => _GoogleMeetPlayerCardState();
}

class _GoogleMeetPlayerCardState extends State<GoogleMeetPlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color _getRoleColor(PlayerRole? role) {
    switch (role) {
      case PlayerRole.mafia:
        return const Color(0xFFFF1E56);
      case PlayerRole.doctor:
        return Colors.greenAccent;
      case PlayerRole.detective:
        return Colors.amberAccent;
      case PlayerRole.civilian:
      default:
        return Colors.lightBlueAccent;
    }
  }

  String _getRoleEmoji(PlayerRole? role) {
    switch (role) {
      case PlayerRole.mafia:
        return '💀';
      case PlayerRole.doctor:
        return '🩺';
      case PlayerRole.detective:
        return '🔍';
      case PlayerRole.civilian:
      default:
        return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final isSpeaking = widget.isSpeaking && player.isAlive;
    final role = widget.revealedRole;
    final hasValidAvatar = player.avatarUrl.isNotEmpty &&
        (player.avatarUrl.startsWith('http://') || player.avatarUrl.startsWith('https://'));

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2833),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFFFF1E56)
                    : isSpeaking
                        ? Colors.greenAccent
                        : widget.mafiaTargeterNames.isNotEmpty
                            ? const Color(0xFFFF1E56)
                            : role != null
                                ? _getRoleColor(role)
                                : Colors.white12,
                width: widget.isSelected || isSpeaking || widget.mafiaTargeterNames.isNotEmpty || role != null ? 3.0 : 1.0,
              ),
              boxShadow: isSpeaking
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 1.0,
                      )
                    ]
                  : widget.isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF1E56).withOpacity(0.5),
                            blurRadius: 8.0,
                            spreadRadius: 1.0,
                          )
                        ]
                      : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // CENTER AVATAR
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFC70039),
                        backgroundImage: hasValidAvatar
                            ? NetworkImage(player.avatarUrl)
                            : null,
                        child: !hasValidAvatar
                            ? const Icon(Icons.person, size: 26, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      if (!player.isAlive)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.eliminationType == 'eliminated'
                                ? 'ELIMINATED 👞'
                                : (widget.statusLabel ?? 'KILLED 💀'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // MAFIA COLLABORATION SKULL BADGE (TOP RIGHT DURING NIGHT MAFIA)
                if (widget.mafiaTargeterNames.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1E56),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💀', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            widget.mafiaTargeterNames.join(', '),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ROLE EMOJI BADGE (BOTTOM RIGHT ON GAME OVER)
                if (role != null)
                  Positioned(
                    bottom: 24,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _getRoleColor(role)),
                      ),
                      child: Text(_getRoleEmoji(role),
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),

                // VOTER ICONS (BOTTOM BAR)
                if (widget.voterNames.isNotEmpty)
                  Positioned(
                    bottom: 22,
                    left: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.voterNames.take(3).map((voter) {
                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1E56),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            voter.substring(0, voter.length > 3 ? 3 : voter.length),
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // HOST CROWN BADGE (TOP RIGHT)
                if (player.isHost && widget.mafiaTargeterNames.isEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 12, color: Colors.black),
                    ),
                  ),

                // ACTIVE SPEAKER / MIC BADGE (TOP LEFT)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSpeaking
                          ? Colors.green.withOpacity(0.8)
                          : Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSpeaking
                          ? Icons.volume_up
                          : Icons.mic_off,
                      size: 12,
                      color: isSpeaking ? Colors.white : Colors.white54,
                    ),
                  ),
                ),

                // NAME BANNER & ROLE SUBTITLE (BOTTOM OVERLAY)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    color: Colors.black.withOpacity(0.75),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.displayName,
                          style: GoogleFonts.cinzel(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (role != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            role.title,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(role),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
