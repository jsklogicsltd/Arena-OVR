import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Periodic shimmer wrapper for any existing bar UI.
///
/// Shimmer runs **1.5s ON** → **4s OFF** → repeat, without ever replacing the
/// underlying bar. This prevents progress from disappearing.
///
/// Uses [Timer.periodic] for the cycle and a short one-shot timer to end each pulse.
class PeriodicShimmerBar extends StatefulWidget {
  const PeriodicShimmerBar({
    super.key,
    required this.child,
    required this.baseColor,
    /// If provided (0..1), shimmer overlay is clipped to this widthFactor
    /// (useful for progress bars: shimmer only over filled portion).
    this.shimmerFraction,
    this.highlightColor,
    /// Time the shimmer overlay is visible each cycle.
    this.shimmerDuration = const Duration(milliseconds: 1500),
    /// Idle time before the next shimmer pulse.
    this.pauseDuration = const Duration(seconds: 4),
    /// One sweep duration while shimmer is active (passed to [Shimmer]).
    this.shimmerSweepPeriod = const Duration(milliseconds: 1100),
  });

  /// The original bar widget to display (always visible).
  final Widget child;

  /// Base color for shimmer. For best results pass the bar's dominant fill color.
  final Color baseColor;

  /// Optional clip fraction for shimmer overlay (0.0–1.0).
  final double? shimmerFraction;

  /// Optional shimmer highlight color (defaults to subtle silver/white).
  final Color? highlightColor;
  final Duration shimmerDuration;
  final Duration pauseDuration;
  final Duration shimmerSweepPeriod;

  @override
  State<PeriodicShimmerBar> createState() => _PeriodicShimmerBarState();
}

class _PeriodicShimmerBarState extends State<PeriodicShimmerBar> {
  Timer? _cycleTimer;
  Timer? _endShimmerTimer;
  bool _shimmerActive = false;

  Duration get _cycle =>
      widget.shimmerDuration + widget.pauseDuration;

  @override
  void initState() {
    super.initState();
    _startCycleTimer();
    _beginShimmerPulse();
  }

  @override
  void didUpdateWidget(covariant PeriodicShimmerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shimmerDuration != widget.shimmerDuration ||
        oldWidget.pauseDuration != widget.pauseDuration) {
      _cycleTimer?.cancel();
      _endShimmerTimer?.cancel();
      _startCycleTimer();
    }
  }

  void _startCycleTimer() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(_cycle, (_) => _beginShimmerPulse());
  }

  void _beginShimmerPulse() {
    if (!mounted) return;
    _endShimmerTimer?.cancel();
    setState(() => _shimmerActive = true);
    _endShimmerTimer = Timer(widget.shimmerDuration, () {
      if (!mounted) return;
      setState(() => _shimmerActive = false);
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _endShimmerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shimmerActive) {
      return widget.child;
    }

    final shimmer = Shimmer.fromColors(
      period: widget.shimmerSweepPeriod,
      baseColor: widget.baseColor.withValues(alpha: 0.88),
      // Subtle silver/white highlight over existing bar colors.
      highlightColor:
          (widget.highlightColor ?? const Color(0xFFE8EAED)).withValues(alpha: 0.65),
      child: widget.child,
    );

    final frac = widget.shimmerFraction;
    if (frac == null) return shimmer;

    // Always show the original bar; shimmer is an overlay clipped to the filled width.
    final clamped = frac.clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: clamped,
            child: shimmer,
          ),
        ),
      ],
    );
  }
}
