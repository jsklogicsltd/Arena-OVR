import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'player_controller.dart';
import 'views/athlete_dashboard_view.dart';
import 'views/athlete_profile_view.dart';
import '../leaderboard/leaderboard_view.dart';
import '../feed/feed_view.dart';
import '../settings/settings_view.dart';
import '../../core/constants/app_colors.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.selectedTab.value;
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: IndexedStack(
          index: tab,
          children: const [
            AthleteDashboardView(),
            LeaderboardView(),
            FeedView(),
            AthleteProfileView(),
            SettingsView(),
          ],
        ),
        bottomNavigationBar: _PlayerNavBar(
          currentIndex: tab,
          onTap: controller.changeTab,
        ),
      );
    });
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _PlayerNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PlayerNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final scale = (w / 390).clamp(0.85, 1.0);
    final navHeight = 68.0 * scale;

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0, currentIndex: currentIndex,
            icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
            label: 'HOME', onTap: onTap,
          ),
          _NavItem(
            index: 1, currentIndex: currentIndex,
            icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard_rounded,
            label: 'LEADERBOARD', onTap: onTap,
          ),
          _NavItem(
            index: 2, currentIndex: currentIndex,
            icon: Icons.dynamic_feed_outlined, activeIcon: Icons.dynamic_feed_rounded,
            label: 'FEED', onTap: onTap,
          ),
          _NavItem(
            index: 3, currentIndex: currentIndex,
            icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
            label: 'PROFILE', onTap: onTap,
          ),
          _NavItem(
            index: 4, currentIndex: currentIndex,
            icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded,
            label: 'SETTINGS', onTap: onTap,
          ),
        ],
      ),
    );
  }
}

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
    final Color color = isActive ? AppColors.tierGold : const Color(0xFF5E7080);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: color,
                size: (isActive ? 24 : 22) * scale,
              ),
            ),
            SizedBox(height: 3.0 * scale),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 9 * scale,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
