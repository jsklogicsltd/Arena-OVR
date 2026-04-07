import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:google_fonts/google_fonts.dart";
import "coach_controller.dart";

import "views/coach_dashboard_view.dart";
import "views/roster_view.dart";
import "views/award_points_view.dart";
import "views/coach_settings_view.dart";
import "../feed/feed_view.dart";

class CoachView extends GetView<CoachController> {
  const CoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.selectedTab.value;
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(
              index: tab,
              children: const [
                CoachDashboardView(),
                RosterView(),
                AwardPointsView(),
                FeedView(),
                CoachSettingsView(),
              ],
            ),
            // Keep nav always on top so body gestures (like Feed list) can't block taps.
            Align(
              alignment: Alignment.bottomCenter,
              child: _CoachNavBar(
                currentIndex: tab,
                onTap: controller.changeTab,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Custom Nav Bar ────────────────────────────────────────────────────────────

class _CoachNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CoachNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Base width = 390 (small phones). Clamp keeps UI readable.
    final scale = (w / 390).clamp(0.85, 1.0);

    // Height of the flat bar area (below the floating button)
    final barHeight = 72.0 * scale;
    // Radius of the floating AWARD circle
    final circleRadius = 32.0 * scale;
    // How far the circle lifts above the bar top edge
    final liftAmount = -34.0 * scale;

    return SizedBox(
      // Use full bar height for correct hit-testing of icons.
      // Previously, `barHeight + liftAmount` (with liftAmount negative) made the
      // layout area smaller than the painted content, so taps sometimes worked
      // only on the text portion (lower part) but not on the icon portion.
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background bar ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: barHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF141B2D),
                    const Color(0xFF0F1923),
                    const Color(0xFF0A0E1A),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF00A8FF).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00A8FF).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(index: 0, currentIndex: currentIndex, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'HOME', onTap: onTap),
                  _NavItem(index: 1, currentIndex: currentIndex, icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'ROSTER', onTap: onTap),
                  // Center spacer — the floating button goes here
                  const Expanded(child: SizedBox()),
                  _NavItem(index: 3, currentIndex: currentIndex, icon: Icons.wifi_tethering_outlined, activeIcon: Icons.wifi_tethering, label: 'FEED', onTap: onTap),
                  _NavItem(index: 4, currentIndex: currentIndex, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'PROFILE', onTap: onTap),
                ],
              ),
            ),
          ),

          // ── Floating AWARD button ────────────────────────────────────────
          Positioned(
            bottom: barHeight - circleRadius + liftAmount,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // This invisible padding block expands the click area significantly
                  GestureDetector(
                    onTap: () => onTap(2),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0 * scale,
                        vertical: 8.0 * scale,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circle with glow
                          Container(
                            width: circleRadius * 1.6,
                            height: circleRadius * 1.6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD700), // Gold fill
                              border: Border.all(
                                color: const Color(0xFF0F1923), // Dark ring separating from bar
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFF0A0E1A), // Dark icon on gold bg
                              size: 24 * scale,
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            'AWARD',
                            style: GoogleFonts.spaceGrotesk(
                              color: currentIndex == 2 ? const Color(0xFFFFD700) : Colors.white54,
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual nav item (non-center) ─────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final scale = (w / 390).clamp(0.85, 1.0);

    final bool isActive = currentIndex == index;
    final Color color = isActive ? const Color(0xFF00A8FF) : const Color(0xFF5E7080);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 26 * scale,
            ),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

