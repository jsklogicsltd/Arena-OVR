import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Scaffold + bottom readability gradient only.
/// Full-screen stadium visuals come from [VideoBackdrop] in `main.dart` — no static PNG here
/// (avoids double background with the video layer).
class StadiumBackground extends StatelessWidget {
  final Widget child;
  const StadiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.backgroundEnd.withOpacity(0.0),
                    AppColors.backgroundEnd.withOpacity(0.6),
                    AppColors.backgroundEnd.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
