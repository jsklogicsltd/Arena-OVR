import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.radius = 16,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        AppAssets.logo,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.sports_football,
          color: AppColors.tierGold,
          size: 72,
        ),
      ),
    );
  }
}
