import 'package:flutter/material.dart';

/// Animated pulsing unread badge indicator for game chat button and tabs.
class AnimatedUnreadBadge extends StatefulWidget {
  final int count;
  final double fontSize;
  final EdgeInsets padding;
  final Color badgeColor;

  const AnimatedUnreadBadge({
    super.key,
    required this.count,
    this.fontSize = 9,
    this.padding = const EdgeInsets.all(5),
    this.badgeColor = const Color(0xFFFF1E56),
  });

  @override
  State<AnimatedUnreadBadge> createState() => _AnimatedUnreadBadgeState();
}

class _AnimatedUnreadBadgeState extends State<AnimatedUnreadBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.badgeColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.badgeColor.withOpacity(0.6),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
