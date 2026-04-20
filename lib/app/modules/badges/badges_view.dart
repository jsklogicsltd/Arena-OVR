import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'badges_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/badge_trophy_case.dart';
import '../../data/repositories/badge_repository.dart';

class BadgesView extends GetView<BadgesController> {
  const BadgesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 44, minHeight: 44),
                      )
                    else
                      const SizedBox(width: 44, height: 44),
                    Expanded(
                      child: Text(
                        'TROPHY CASE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR BADGES',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0x08FFFFFF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0x1AFFFFFF),
                                width: 1,
                              ),
                            ),
                            child: BadgeTrophyCase(
                              earnedBadges: controller.earnedBadgeIds,
                              badgeSize: 60,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'BADGE DETAILS',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...BadgeIds.all.map((id) {
                        final unlocked =
                            controller.earnedBadgeIds.contains(id);
                        return _buildBadgeDetailRow(id, unlocked);
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeDetailRow(String badgeId, bool unlocked) {
    final label = BadgeIds.labelFor(badgeId);
    final desc = BadgeIds.descriptionFor(badgeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0x15FFD700) : const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? const Color(0x55FFD700)
              : const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF3D454D),
              border: Border.all(
                color: unlocked
                    ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: unlocked
                  ? Image.asset(
                      'assets/badges/$badgeId.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.emoji_events_rounded,
                            color: Color(0xFFFFD700), size: 22),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.lock_outline_rounded,
                          color: Colors.white38, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: unlocked ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    color: unlocked ? Colors.white54 : Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFFFFD700), size: 22),
        ],
      ),
    );
  }
}
