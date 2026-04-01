import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/arena_button.dart';
import 'signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

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

              const SizedBox(height: 36),

              // ── Card ─────────────────────────────────────────────────────────
              GlassCard(
                borderRadius: 28.0,
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Avatar picker ─────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: controller.pickImage,
                        child: Obx(() {
                          final file = controller.selectedImage.value;
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Circle avatar
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withOpacity(0.12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2.5,
                                    ),
                                    image: file != null
                                        ? DecorationImage(
                                            image: FileImage(file),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: file == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person_rounded,
                                                color: AppColors.primary.withOpacity(0.8),
                                                size: 36),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Photo',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: AppColors.primary.withOpacity(0.7),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                                // Camera badge
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0A0E1A),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // "Optional" label
                    Center(
                      child: Text(
                        'PROFILE PHOTO  (OPTIONAL)',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                          'CREATE ACCOUNT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    )
                    .animate(delay: 320.ms)
                    .fade(duration: 420.ms)
                    .slideX(begin: -0.2, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),

                    // Full name
                    GlassTextField(
                      controller: controller.nameController,
                      hintText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                    )
                    .animate(delay: 400.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: 0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 14),

                    // Email
                    GlassTextField(
                      controller: controller.emailController,
                      hintText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                    )
                    .animate(delay: 460.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: -0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 14),

                    // Password
                    GlassTextField(
                      controller: controller.passwordController,
                      focusNode: controller.passwordFocusNode,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    )
                    .animate(delay: 520.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: 0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 14),

                    // Confirm password
                    GlassTextField(
                      controller: controller.confirmPasswordController,
                      focusNode: controller.confirmPasswordFocusNode,
                      hintText: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    )
                    .animate(delay: 580.ms)
                    .fade(duration: 400.ms)
                    .slideX(begin: -0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 28),

                    // Role header
                    Text(
                      'I AM A...',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 3.0,
                      ),
                    )
                    .animate(delay: 650.ms)
                    .fade(duration: 380.ms),

                    const SizedBox(height: 14),

                    // Role selector
                    Obx(() {
                      final hasAdmin = controller.showAdminOption.value;
                      return Column(
                        children: [
                          Row(
                            children: [
                              if (hasAdmin) ...[
                                Expanded(
                                  child: _buildRoleCard(
                                    role: 'ADMIN',
                                    icon: Icons.shield_outlined,
                                    isSelected: controller.selectedRole.value == 'ADMIN',
                                    animDelay: 700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: _buildRoleCard(
                                  role: 'COACH',
                                  icon: Icons.sports_score_outlined,
                                  isSelected: controller.selectedRole.value == 'COACH',
                                  animDelay: hasAdmin ? 770 : 700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleCard(
                                  role: 'PLAYER',
                                  svgIcon: AppAssets.playerIcon,
                                  isSelected: controller.selectedRole.value == 'PLAYER',
                                  animDelay: hasAdmin ? 840 : 770,
                                ),
                              ),
                            ],
                          ),
                          if (controller.selectedRole.value == 'ADMIN') ...[
                            const SizedBox(height: 10),
                            Text(
                              'First-time platform setup',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      );
                    }),

                    const SizedBox(height: 28),

                    // Create button
                    Obx(() => ArenaButton(
                      label: 'CREATE ACCOUNT',
                      onPressed: controller.signUp,
                      isLoading: controller.isLoading.value,
                    ))
                    .animate(delay: 880.ms)
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
              .animate(delay: 160.ms)
              .fade(duration: 550.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 550.ms, curve: Curves.easeOutCubic)
              .blur(begin: const Offset(6, 6), end: Offset.zero, duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: 28),

              // ── Sign In link ──────────────────────────────────────────────────
              GestureDetector(
                onTap: controller.navigateToSignIn,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Already have an account?  ',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'SIGN IN',
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
              .animate(delay: 960.ms)
              .fade(duration: 450.ms)
              .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo with blur-clear + elastic scale + gold shimmer sweep
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

  Widget _buildRoleCard({
    required String role,
    IconData? icon,
    String? svgIcon,
    required bool isSelected,
    int animDelay = 700,
  }) {
    final color = isSelected ? const Color(0xFF00A1FF) : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => controller.selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.09 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A1FF) : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A1FF).withOpacity(0.22),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgIcon != null)
              SvgPicture.asset(
                svgIcon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              role,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: animDelay))
    .fade(duration: 400.ms)
    .scale(
      begin: const Offset(0.75, 0.75),
      end: const Offset(1.0, 1.0),
      duration: 450.ms,
      curve: Curves.easeOutBack,
    );
  }
}
