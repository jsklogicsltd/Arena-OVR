import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TierBorder extends StatelessWidget {
  final int? ovr;
  final Widget child;
  final bool withGlow;
  final double borderRadius;
  final double borderWidth;

  const TierBorder({
    super.key,
    required this.ovr,
    required this.child,
    this.withGlow = false,
    this.borderRadius = 50.0,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTierColor(ovr);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color, width: borderWidth),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: -2,
                )
              ]
            : null,
      ),
      child: child,
    );
  }
}
