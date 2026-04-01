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
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StadiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: controller.goBack,
                  ),
                ),
              ).animate().fade(duration: 800.ms),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Logo
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(AppAssets.logo, width: 140),
                        )
                        .animate()
                        .fade(duration: 1200.ms, curve: Curves.easeOutQuint)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 1600.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 48),

                        // Form Card
                        GlassCard(
                          borderRadius: 24.0,
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Text(
                                'RESET PASSWORD',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              Text(
                                'Enter your email address to receive a password reset link.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              GlassTextField(
                                controller: controller.emailController,
                                hintText: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 32),
                              
                              Obx(() => ArenaButton(
                                    label: 'SEND RESET LINK',
                                    onPressed: controller.resetPassword,
                                    isLoading: controller.isLoading.value,
                                  )),
                            ],
                          ),
                        )
                        .animate(delay: 300.ms)
                        .fade(duration: 1200.ms)
                        .slideY(begin: 0.1, end: 0.0, duration: 1200.ms, curve: Curves.easeOutQuint),
                        
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
