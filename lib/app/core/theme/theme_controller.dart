import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class ThemeController extends GetxController {
  final Rx<Color> _teamPrimaryColor = AppColors.primary.obs;
  final Rx<Color> _teamSecondaryColor = AppColors.accent.obs;

  Color get primaryColor => _teamPrimaryColor.value;
  Color get secondaryColor => _teamSecondaryColor.value;

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, primaryColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Color get accentGlow => secondaryColor.withOpacity(0.5);
  
  Color get activeTabGlow => primaryColor.withOpacity(0.6);
  Color get cardBorderGlow => primaryColor.withOpacity(0.3);

  void setTeamColors(Color primary, Color secondary) {
    _teamPrimaryColor.value = primary;
    _teamSecondaryColor.value = secondary;
    update(); // notify GetBuilder widgets
  }

  void resetToDefault() {
    _teamPrimaryColor.value = AppColors.primary;
    _teamSecondaryColor.value = AppColors.accent;
    update(); // notify GetBuilder widgets
  }
}
