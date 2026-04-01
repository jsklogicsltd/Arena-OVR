import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import '../constants/app_colors.dart';

class ArenaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ArenaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      return Container(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundEnd,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundEnd.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTab(Icons.home_outlined, 0, themeController),
            _buildTab(Icons.bar_chart_outlined, 1, themeController),
            _buildCenterTab(Icons.play_arrow_outlined, 2, themeController),
            _buildTab(Icons.military_tech_outlined, 3, themeController),
            _buildTab(Icons.person_outline, 4, themeController),
          ],
        ),
      );
    });
  }

  Widget _buildTab(IconData icon, int index, ThemeController themeController) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isActive
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeController.activeTabGlow,
                    blurRadius: 15,
                    spreadRadius: -5,
                  )
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isActive ? themeController.primaryColor : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterTab(IconData icon, int index, ThemeController themeController) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: themeController.primaryGradient,
          border: Border.all(
            color: themeController.secondaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeController.secondaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 32,
        ),
      ),
    );
  }
}
