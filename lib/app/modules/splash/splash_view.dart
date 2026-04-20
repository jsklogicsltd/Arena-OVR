import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import 'splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  // Controller only needed for the complex simulated loading sequence now
  late final AnimationController _mainController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    Get.find<SplashController>();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    _progressAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 0.60)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.60, end: 0.78)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.78, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
    ]).animate(_mainController);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
          // Premium subtle background layer (non-interactive).
          // const FireSparksBackground(),
          SizedBox(
            width: double.infinity,
            height: screenHeight,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Logo (Drops from top using flutter_animate) ──
                Hero(
                  tag: 'app_logo',
                  child: const AppLogo(width: 176),
                )
                    .animate()
                    .fade(duration: 1200.ms, curve: Curves.easeOutQuint)
                    .slideY(
                        begin: -0.5,
                        end: 0.0,
                        duration: 1600.ms,
                        curve: Curves.elasticOut),

                const SizedBox(height: 16),

                // ── Headline ───────────────────────────────────
                Image.asset(AppAssets.headline, width: 206)
                    .animate(delay: 400.ms)
                    .fade(duration: 1200.ms)
                    .slideY(
                        begin: 0.2,
                        end: 0.0,
                        duration: 1200.ms,
                        curve: Curves.easeOutQuint),

                const SizedBox(height: 52),

                // ── Progress bar (driven by _mainController) ───
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, _) {
                    final progress = _progressAnim.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 300,
                          height: 6,
                          child: Stack(
                            children: [
                              Container(
                                width: 300,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Container(
                                width: 300 * progress,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00A1FF),
                                      Color(0xFF00D4AA),
                                      Color(0xFFFFB800),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB800)
                                          .withOpacity(0.6 * progress),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          progress >= 1.0 ? 'READY' : 'SYNCHRONIZING',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: progress >= 1.0
                                ? const Color(0xFFFFB800)
                                : AppColors.primary,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate(delay: 800.ms).fade(duration: 1200.ms),

                const Spacer(flex: 3),

                // ── Footer ─────────────────────────────────────
                Text(
                  'BUILT FOR CHAMPIONS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 4.0,
                  ),
                )
                    .animate(delay: 1100.ms)
                    .fade(duration: 1200.ms)
                    .slideY(
                        begin: 0.2,
                        end: 0.0,
                        duration: 1200.ms,
                        curve: Curves.easeOutQuint),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
    );
  }
}

