import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // Transparent so [VideoBackdrop] in main.dart shows behind all routes.
      // Screens that need a solid fill should set Scaffold.backgroundColor explicitly.
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        displayMedium: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        displaySmall: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardSurface,
      ),
    );
  }
}
