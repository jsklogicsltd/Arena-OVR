import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/arena_button.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return StadiumBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── Logo ─────────────────────────────────────────────────────────
              _buildLogo(),

              const SizedBox(height: 44),

              // ── Card ─────────────────────────────────────────────────────────
              GlassCard(
                borderRadius: 28.0,
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Title row with accent line
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SIGN IN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    )
                    .animate(delay: 350.ms)
                    .fade(duration: 450.ms)
                    .slideX(begin: -0.2, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 28),

                    // Email
                    GlassTextField(
                      controller: controller.emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                    )
                    .animate(delay: 440.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: 0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 14),

                    // Password
                    GlassTextField(
                      controller: controller.passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    )
                    .animate(delay: 510.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: -0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .animate(delay: 570.ms)
                    .fade(duration: 380.ms),

                    const SizedBox(height: 28),

                    // Login button
                    Obx(() => ArenaButton(
                      label: 'LOGIN ➔',
                      onPressed: controller.signIn,
                      isLoading: controller.isLoading.value,
                    ))
                    .animate(delay: 640.ms)
                    .fade(duration: 420.ms)
                    .scale(
                      begin: const Offset(0.86, 0.86),
                      end: const Offset(1.0, 1.0),
                      duration: 480.ms,
                      curve: Curves.easeOutBack,
                    ),
                  ],
                ),
              )
              .animate(delay: 180.ms)
              .fade(duration: 550.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 550.ms, curve: Curves.easeOutCubic)
              .blur(begin: const Offset(6, 6), end: Offset.zero, duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: 28),

              // ── OR divider — expands from center ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 70, child: Divider(color: AppColors.cardBorder, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 70, child: Divider(color: AppColors.cardBorder, thickness: 1)),
                ],
              )
              .animate(delay: 730.ms)
              .fade(duration: 400.ms)
              .scaleX(begin: 0.25, end: 1.0, duration: 500.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

              // ── Sign Up link ──────────────────────────────────────────────────
              GestureDetector(
                onTap: controller.navigateToSignUp,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Don't have an account?  ",
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'SIGN UP',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: 820.ms)
              .fade(duration: 450.ms)
              .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 48),

              // ── Footer ───────────────────────────────────────────────────────
              Text(
                'PRIVACY POLICY   ·   TERMS OF SERVICE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              )
              .animate(delay: 920.ms)
              .fade(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo image with dramatic reveal
        Image.asset(
          AppAssets.logo,
          width: 115,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.sports_football,
            color: AppColors.tierGold,
            size: 72,
          ),
        )
        .animate()
        .blur(begin: const Offset(16, 16), end: Offset.zero, duration: 600.ms, curve: Curves.easeOut)
        .fade(duration: 350.ms, curve: Curves.easeIn)
        .scale(
          begin: const Offset(0.42, 0.42),
          end: const Offset(1.0, 1.0),
          duration: 720.ms,
          curve: Curves.easeOutBack,
        )
        .then(delay: 250.ms)
        .shimmer(
          duration: 1000.ms,
          color: const Color(0xFFFFD700).withOpacity(0.42),
          angle: -0.2,
        ),

        const SizedBox(height: 12),

        // "ARENA OVR" wordmark beneath
        Text(
          'ARENA OVR',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 5,
          ),
        )
        .animate(delay: 500.ms)
        .fade(duration: 500.ms)
        .slideY(begin: 0.4, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
      ],
    );
  }
}
