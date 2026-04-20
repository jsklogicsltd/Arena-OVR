import 'package:flutter/material.dart';

class EliteOvrStyle {
  EliteOvrStyle._();

  static bool isEliteOvr(int ovr) => ovr >= 95;

  static const Color goldTint = Color(0xFFFFD700);

  static const LinearGradient eliteCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4E3900),
      Color(0xFF9A6A00),
      Color(0xFFFFC53A),
      Color(0xFFFFE08A),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  static List<BoxShadow> eliteGlow({double alpha = 0.45}) => [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: alpha),
          blurRadius: 28,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
      ];

  static Widget tintedAvatar({
    required bool isElite,
    required Widget child,
  }) {
    if (!isElite) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(goldTint, BlendMode.modulate),
      child: child,
    );
  }
}
