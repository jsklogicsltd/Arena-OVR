// import 'dart:math' as math;
//
// import 'package:flutter/material.dart';
//
// /// Lightweight ember/spark field: tiny glowing particles rise from the bottom,
// /// sway horizontally, and fade toward the top. Uses a single [AnimationController]
// /// and one [CustomPainter] pass — no third-party engines.
// ///
// /// Place behind content in a [Stack] and keep interactions unblocked:
// /// ```dart
// /// Stack(
// ///   children: [
// ///     FireSparksBackground(),
// ///     YourScreen(),
// ///   ],
// /// )
// /// ```
// class FireSparksBackground extends StatefulWidget {
//   const FireSparksBackground({
//     super.key,
//     this.particleCount = 26,
//     this.controllerDuration = const Duration(seconds: 45),
//   }) : assert(particleCount >= 20 && particleCount <= 30,
//             'particleCount should be between 20 and 30');
//
//   /// Number of embers (20–30).
//   final int particleCount;
//
//   /// One full sweep of [AnimationController.value] from 0→1 (repeats forever).
//   /// Slower = gentler drift.
//   final Duration controllerDuration;
//
//   @override
//   State<FireSparksBackground> createState() => _FireSparksBackgroundState();
// }
//
// class _FireSparksBackgroundState extends State<FireSparksBackground>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final List<_SparkConfig> _configs;
//
//   @override
//   void initState() {
//     super.initState();
//     final rnd = math.Random(42);
//     _configs = List.generate(widget.particleCount, (_) {
//       return _SparkConfig(
//         baseX: rnd.nextDouble(),
//         phase: rnd.nextDouble(),
//         verticalSpeed: 0.45 + rnd.nextDouble() * 1.1,
//         swayPhase: rnd.nextDouble() * math.pi * 2,
//         swayFrequency: 1.2 + rnd.nextDouble() * 2.8,
//         swayAmplitude: 4.0 + rnd.nextDouble() * 14.0,
//         radius: 1.2 + rnd.nextDouble() * 2.2,
//         hueIndex: rnd.nextInt(3),
//         maxOpacity: 0.18 + rnd.nextDouble() * 0.22,
//       );
//     });
//
//     _controller = AnimationController(vsync: this, duration: widget.controllerDuration)
//       ..repeat();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return RepaintBoundary(
//             child: AnimatedBuilder(
//               animation: _controller,
//               builder: (context, _) {
//                 return CustomPaint(
//                   size: Size(constraints.maxWidth, constraints.maxHeight),
//                   painter: _FireSparksPainter(
//                     configs: _configs,
//                     animationValue: _controller.value,
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _SparkConfig {
//   _SparkConfig({
//     required this.baseX,
//     required this.phase,
//     required this.verticalSpeed,
//     required this.swayPhase,
//     required this.swayFrequency,
//     required this.swayAmplitude,
//     required this.radius,
//     required this.hueIndex,
//     required this.maxOpacity,
//   });
//
//   final double baseX;
//   final double phase;
//   final double verticalSpeed;
//   final double swayPhase;
//   final double swayFrequency;
//   final double swayAmplitude;
//   final double radius;
//   final int hueIndex;
//   final double maxOpacity;
// }
//
// class _FireSparksPainter extends CustomPainter {
//   _FireSparksPainter({
//     required this.configs,
//     required this.animationValue,
//   });
//
//   final List<_SparkConfig> configs;
//   final double animationValue;
//
//   static const List<Color> _emberColors = [
//     Color(0xFFFF6B35), // orange
//     Color(0xFFFFD93D), // yellow
//     Color(0xFFFF4444), // red
//     Color(0xFFFF9500), // deep orange
//     Color(0xFFFFE066), // pale gold
//   ];
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (size.isEmpty) return;
//
//     final w = size.width;
//     final h = size.height;
//     // Spawn band: lower 18% of screen; travel upward; fade before very top.
//     final spawnMinY = h * 0.82;
//     final travelRange = h * 0.78;
//
//     for (final c in configs) {
//       // Normalized height progress: 0 = bottom spawn, 1 = top (faded out)
//       double p = (animationValue * c.verticalSpeed + c.phase) % 1.0;
//
//       final y = spawnMinY - p * travelRange;
//
//       final sway = math.sin(
//             animationValue * math.pi * 2 * c.swayFrequency + c.swayPhase,
//           ) *
//           c.swayAmplitude;
//       final x = c.baseX * w + sway;
//
//       // Fade out as sparks rise (stronger fade in upper half).
//       final fade = (1.0 - p);
//       final opacity = (fade * fade * c.maxOpacity).clamp(0.0, 0.45);
//
//       if (opacity <= 0.008) continue;
//
//       final color = _emberColors[c.hueIndex % _emberColors.length]
//           .withValues(alpha: opacity);
//
//       final cx = x.clamp(c.radius, w - c.radius);
//       final cy = y.clamp(c.radius, h - c.radius);
//
//       // Soft outer glow (single extra ring — keeps cost low)
//       final glowPaint = Paint()
//         ..color = color.withValues(alpha: opacity * 0.35)
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
//       canvas.drawCircle(Offset(cx, cy), c.radius * 2.1, glowPaint);
//
//       final corePaint = Paint()..color = color;
//       canvas.drawCircle(Offset(cx, cy), c.radius, corePaint);
//
//       // Tiny hot core
//       final hotPaint = Paint()
//         ..color = const Color(0xFFFFF3E0).withValues(alpha: opacity * 0.85);
//       canvas.drawCircle(Offset(cx, cy), c.radius * 0.35, hotPaint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _FireSparksPainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue ||
//         oldDelegate.configs != configs;
//   }
// }
