import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Premium sports / gaming-style rotating neon border around a circular avatar.
///
/// The gradient ring rotates continuously; the [child] stays static (no spin).
class AnimatedGlowingBorder extends StatefulWidget {
  const AnimatedGlowingBorder({
    super.key,
    required this.child,
    /// Outer diameter of the glowing ring (including border).
    this.diameter = 100,
    /// Width of the animated gradient stroke.
    this.borderWidth = 3,
    /// One full rotation duration.
    this.duration = const Duration(seconds: 4),
    /// Optional outer glow (soft halo).
    this.glowBlur = 12,
    this.glowSpread = 0,
  });

  final Widget child;
  final double diameter;
  final double borderWidth;
  final Duration duration;
  final double glowBlur;
  final double glowSpread;

  @override
  State<AnimatedGlowingBorder> createState() => _AnimatedGlowingBorderState();
}

class _AnimatedGlowingBorderState extends State<AnimatedGlowingBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<Color> _sweepColors = [
    // Brand sweep: Silver -> Gold -> Silver (loop)
    Color(0xFFC0C0C0), // Silver/Grey
    Color(0xFFFFD700), // Gold
    Color(0xFFC0C0C0), // back to Silver for seamless loop
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedGlowingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    final inner = (d - 2 * widget.borderWidth).clamp(0.0, d);

    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft outer glow (does not rotate — keeps perf reasonable)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0C0C0).withValues(alpha: 0.22),
                    blurRadius: widget.glowBlur,
                    spreadRadius: widget.glowSpread,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.20),
                    blurRadius: widget.glowBlur * 0.75,
                    spreadRadius: widget.glowSpread,
                  ),
                ],
              ),
            ),
          ),
          // Rotating sweep gradient ring
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: _sweepColors,
                        stops: const [0.0, 0.5, 1.0],
                        tileMode: TileMode.clamp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Inner mask + avatar (static — does not rotate with border)
          ClipOval(
            child: SizedBox(
              width: inner,
              height: inner,
              child: ColoredBox(
                color: const Color(0xFF0A0E1A),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
