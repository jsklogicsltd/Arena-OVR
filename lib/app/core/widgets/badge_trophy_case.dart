import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/repositories/badge_repository.dart';

/// Reusable badge grid for athlete dashboard and profile.
/// Renders `Image.asset('assets/badges/$id.png')` with graceful fallback.
class BadgeTrophyCase extends StatelessWidget {
  final List<String> earnedBadges;
  final double badgeSize;
  final bool compact;

  const BadgeTrophyCase({
    super.key,
    required this.earnedBadges,
    this.badgeSize = 60,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final defs = BadgeIds.all;
    // Bigger badges, tighter layout (matches the mock you want).
    final size = (compact ? badgeSize : badgeSize.clamp(132, 156)).toDouble();

    return SizedBox(
      // Keep this just tall enough for badge + label (avoid excess empty space).
      height: size + 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: defs.length,
        itemBuilder: (context, i) {
          final badgeId = defs[i];

          final unlocked = earnedBadges.contains(badgeId);

          return Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 2 : 0,
              right: 10,
              top: 2,
              bottom: 2,
            ),
            child: _BadgeItem(
              badgeId: badgeId,
              unlocked: unlocked,
              size: size,
              index: i,
            ),
          );
        },
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String badgeId;
  final bool unlocked;
  final double size;
  final int index;

  const _BadgeItem({
    required this.badgeId,
    required this.unlocked,
    required this.size,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final label = BadgeIds.labelFor(badgeId);
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Keep glow very subtle to avoid large blur outside the section.
                    if (unlocked)
                      Container(
                        width: size * 0.86,
                        height: size * 0.86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.10),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    // Badge art (already circular in the PNG) — render directly.
                    unlocked
                        ? Transform.scale(
                            // Badge PNGs have inconsistent transparent padding.
                            // A small zoom makes them read larger and more consistent.
                            scale: 1.22,
                            child: Image.asset(
                              'assets/badges/$badgeId.png',
                              width: size,
                              height: size,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) =>
                                  _fallbackIcon(unlocked),
                            ),
                          )
                        : _fallbackIcon(false),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 400 + index * 70))
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: unlocked
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.40),
              fontSize: size >= 130 ? 12 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(bool unlocked) {
    return Center(
      child: Icon(
        unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
        color: unlocked ? const Color(0xFFFFD700) : Colors.white38,
        size: size * 0.42,
      ),
    );
  }
}
