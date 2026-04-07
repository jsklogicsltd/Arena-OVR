import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/arena_button.dart';
import '../../core/widgets/fire_sparks_background.dart';
import 'invite_code_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart' as import_repo;

class InviteCodeView extends GetView<InviteCodeController> {
  const InviteCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle premium background layer (non-interactive).
            // const FireSparksBackground(),
            SafeArea(
              child: Column(
                children: [
              // Head Navigation & Logout block (for testing and flow escape)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          final repo = Get.put(import_repo.AuthRepository());
                          await repo.signOut();
                          Get.offAllNamed('/auth');
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: 800.ms),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 1600.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 24),

                        // Coach-only: Create Team vs Join Team
                        Obx(() {
                          if (!UserModel.isCoachRole(controller.userRole.value)) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoSlidingSegmentedControl<int>(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  thumbColor: const Color(0xFF00A1FF)
                                      .withValues(alpha: 0.35),
                                  groupValue: controller
                                      .coachOnboardingSegment.value,
                                  onValueChanged: (int? v) {
                                    if (v == null) return;
                                    controller.coachOnboardingSegment.value = v;
                                  },
                                  children: <int, Widget>{
                                    0: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        'Create Team',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    1: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        'Join Team',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),

                        // Title
                        Obx(
                          () => Text(
                            UserModel.isCoachRole(controller.userRole.value)
                                ? (controller.coachOnboardingSegment.value == 0
                                    ? 'ENTER SCHOOL CODE'
                                    : 'ENTER TEAM CODE')
                                : 'ENTER YOUR CODE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        )
                            .animate(delay: 200.ms)
                            .fade(duration: 1200.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: 1200.ms,
                              curve: Curves.easeOutQuint,
                            ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Obx(
                          () =>
                              Text(
                                    UserModel.isCoachRole(controller.userRole.value)
                                        ? (controller.coachOnboardingSegment
                                                    .value ==
                                                0
                                            ? 'Your Super admin will provide your school access code'
                                            : 'Your Head Coach will provide your team access code')
                                        : 'Your coach will provide\nyour\nteam access code',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  )
                                  .animate(delay: 300.ms)
                                  .fade(duration: 1200.ms)
                                  .slideY(
                                    begin: 0.2,
                                    end: 0.0,
                                    duration: 1200.ms,
                                    curve: Curves.easeOutQuint,
                                  ),
                        ),

                        const SizedBox(height: 48),

                        // Pin Code Fields (Key forces rebuild when CLEAR CODE is tapped)
                        Obx(() => PinInput(
                              key: ValueKey<int>(controller.clearTrigger),
                              length: 6,
                              pinController: controller.pinInputController,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              builder: (context, cells) {
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: cells.map((cell) {
                                      final isActive =
                                          cell.isFocused || cell.isFilled;
                                      return Container(
                                        width: 48,
                                        height: 64,
                                        margin: EdgeInsets.only(
                                          right: cell.index == 5 ? 0 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.20,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border(
                                            top: BorderSide(
                                              color: isActive
                                                  ? const Color(0xFF00A1FF)
                                                  : Colors.white.withValues(
                                                      alpha: 0.20,
                                                    ),
                                              width: 1.0,
                                            ),
                                            right: BorderSide(
                                              color: isActive
                                                  ? const Color(0xFF00A1FF)
                                                  : Colors.white.withValues(
                                                      alpha: 0.20,
                                                    ),
                                              width: 1.0,
                                            ),
                                            bottom: BorderSide(
                                              color: isActive
                                                  ? const Color(0xFF00A1FF)
                                                  : Colors.white.withValues(
                                                      alpha: 0.20,
                                                    ),
                                              width: 2.0,
                                            ),
                                            left: BorderSide(
                                              color: isActive
                                                  ? const Color(0xFF00A1FF)
                                                  : Colors.white.withValues(
                                                      alpha: 0.20,
                                                    ),
                                              width: 1.0,
                                            ),
                                          ),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF00A1FF,
                                                    ).withValues(alpha: 0.40),
                                                    blurRadius: 15,
                                                    offset: Offset.zero,
                                                    spreadRadius: 0,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                          child: Text(
                                            cell.character ?? '',
                                            key: ValueKey<String>(
                                              cell.character ?? '',
                                            ),
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ))
                            .animate(delay: 400.ms)
                            .fade(duration: 1200.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: 1200.ms,
                              curve: Curves.easeOutQuint,
                            ),

                        const SizedBox(height: 12),

                        Text(
                          '6-character code (letters and numbers)',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ).animate(delay: 500.ms).fade(duration: 1200.ms),

                        const SizedBox(height: 32),

                        // Clear / Cancel button — clear wrong code so user can re-enter
                        TextButton(
                          onPressed: () {
                            controller.clearCode();
                          },
                          child: Text(
                            'CLEAR CODE',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate(delay: 550.ms).fade(duration: 1200.ms),

                        const SizedBox(height: 16),

                        // Join Button
                        Obx(
                              () => ArenaButton(
                                label: UserModel.isCoachRole(controller.userRole.value)
                                    ? (controller.coachOnboardingSegment.value ==
                                            0
                                        ? 'VERIFY SCHOOL'
                                        : 'JOIN DASHBOARD')
                                    : 'JOIN TEAM',
                                onPressed: controller.joinTeam,
                                isLoading: controller.isLoading.value,
                              ),
                            )
                            .animate(delay: 600.ms)
                            .fade(duration: 1200.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: 1200.ms,
                              curve: Curves.easeOutQuint,
                            ),

                        const SizedBox(height: 32),

                        // Footer string
                        Obx(
                          () => RichText(
                            text: TextSpan(
                              text: 'Don\'t have a code? ',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: UserModel.isCoachRole(controller.userRole.value)
                                      ? (controller.coachOnboardingSegment
                                                  .value ==
                                              0
                                          ? 'Contact your admin'
                                          : 'Contact your coach')
                                      : 'Contact your coach',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(
                                      0xFFFFB800,
                                    ), // AppColors.accent / yellow
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 700.ms).fade(duration: 1200.ms),
                        ),

                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
