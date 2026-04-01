import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../theme/theme_controller.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool withGlow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? leftBorderColor;
  final Color? borderColor;   // full all-sides border override
  final Color? glowColor;     // custom shadow color

  const GlassCard({
    super.key,
    required this.child,
    this.withGlow = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.leftBorderColor,
    this.borderColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use GetBuilder so the widget  rebuilds on ThemeController.update()
    // without needing Obx + an observable in every branch.
    return GetBuilder<ThemeController>(
      builder: (theme) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            clipBehavior: leftBorderColor != null ? Clip.hardEdge : Clip.none,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.cardSurface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.cardBorder,
                width: 1,
              ),
              boxShadow: glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor!,
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : withGlow
                      ? [
                          BoxShadow(
                            color: theme.cardBorderGlow,
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
            ),
            child: leftBorderColor == null
                ? Padding(padding: padding, child: child)
                : Stack(
                    children: [
                      Padding(padding: padding, child: child),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 4,
                        child: Container(color: leftBorderColor),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
