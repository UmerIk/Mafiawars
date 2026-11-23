import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../audio/providers/audio_providers.dart';

class ModeratorNarrationBanner extends ConsumerStatefulWidget {
  const ModeratorNarrationBanner({super.key});

  @override
  ConsumerState<ModeratorNarrationBanner> createState() =>
      _ModeratorNarrationBannerState();
}

class _ModeratorNarrationBannerState
    extends ConsumerState<ModeratorNarrationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrationTextAsync = ref.watch(currentNarrationTextProvider);
    final narrationText = narrationTextAsync.value;

    if (narrationText == null || narrationText.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0C10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF1E56), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1E56).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFFF1E56),
              child: Icon(Icons.psychology, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODERATOR NARRATION',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF1E56),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    narrationText,
                    style: GoogleFonts.cinzel(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
