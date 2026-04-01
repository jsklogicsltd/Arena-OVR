import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundEnd = Color(0xFF141B2D);
  static const Color primary = Color(0xFF00A3FF);
  static const Color accent = Color(0xFFFFB800);
  static const Color positive = Color(0xFF00FF88);
  static const Color negative = Color(0xFFFF3B5C);
  static const Color cardSurface = Color(0xB2141B2D); // #141B2D at 70% opacity
  static const Color cardBorder = Color(0x19FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8899AA);

  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFB800);
  static const Color tierPurple = Color(0xFF9B30FF);
  static const Color tierDiamond = Color(0xFF00FFFF);

  static const Color seasonGold = Color(0xFFFFD700);

  static Color getTierColor(int? ovr) {
    if (ovr == null) return textSecondary;
    if (ovr < 30) return tierBronze;
    if (ovr < 60) return tierSilver;
    if (ovr < 80) return tierGold;
    if (ovr < 95) return tierPurple;
    return tierDiamond;
  }
}
