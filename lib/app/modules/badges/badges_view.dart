import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:google_fonts/google_fonts.dart";

import "badges_controller.dart";
import "../../core/constants/app_colors.dart";
import "../../core/widgets/stadium_background.dart";
import "../../core/widgets/fire_sparks_background.dart";
import "../../core/components/animated_glowing_border.dart";

/// Badges hub (placeholder UI until badge catalog is wired).
class BadgesView extends GetView<BadgesController> {
  const BadgesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // const FireSparksBackground(),
            SafeArea(
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
                            'BADGES',
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
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedGlowingBorder(
                              diameter: 102,
                              borderWidth: 3,
                              duration: const Duration(seconds: 4),
                              child: const SizedBox(
                                width: 96,
                                height: 96,
                                child: CircleAvatar(
                                  backgroundColor: Color(0xFF1E293B),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.tierGold,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'COMING SOON',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Earned badges and milestones will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
