import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/arena_button.dart';
import '../../routes/app_routes.dart';
import 'admin_controller.dart';
import '../../data/models/school_model.dart';
import '../../data/models/user_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          AppAssets.logo,
                          height: 50,
                          errorBuilder: (ctx, _, __) => const Icon(
                            Icons.sports_football,
                            color: Colors.blueAccent,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARENA',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                height: 1.0,
                              ),
                            ),
                            Container(
                              width: 68,
                              height: 2,
                              decoration: const BoxDecoration(
                                color: AppColors.tierGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fade(duration: 800.ms, curve: Curves.easeOutCubic).slideX(begin: -0.1, duration: 800.ms, curve: Curves.easeOutCubic),
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x0DFFFFFF),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x0DFFFFFF),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => Get.toNamed(Routes.ADMIN_SETTINGS),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 800.ms, curve: Curves.easeOutCubic).slideX(begin: 0.1, duration: 800.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'COMMAND CENTER',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, duration: 800.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 8),
                      Container(
                        width: 64,
                        height: 1,
                        color: AppColors.tierGold,
                      ).animate(delay: 100.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).scaleX(begin: 0.0, duration: 800.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 24),

                      // Stats Panel
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                'SCHOOLS',
                                controller.isLoading.value ? null : controller.totalSchools.toString(),
                                const Color(0xFFFFB800),
                                Icons.domain,
                              ),
                              _buildDivider(),
                              _buildStatItem(
                                'COACHES',
                                controller.isLoading.value ? null : controller.totalCoaches.toString(),
                                const Color(0xFF00E0FF),
                                Icons.sports,
                              ),
                              _buildDivider(),
                              _buildStatItem(
                                'ATHLETES',
                                controller.isLoading.value ? null : controller.totalAthletes.toString(),
                                const Color(0xFF39FF14),
                                Icons.directions_run,
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: 200.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, duration: 800.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 24),

                      // Create Button
                      ArenaButton(
                        label: '+ CREATE NEW SCHOOL',
                        onPressed: () => Get.toNamed(Routes.CREATE_SCHOOL),
                      ).animate(delay: 300.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, duration: 800.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 32),

                      // ── SCHOOLS SECTION ──
                      _buildSectionHeader('YOUR SCHOOLS', '', 400),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return _buildSchoolsShimmer();
                        }
                        if (controller.schools.isEmpty) {
                          return _buildEmptyState('No schools yet.', Icons.domain).animate().fade(duration: 800.ms);
                        }
                        return Column(
                          children: controller.schools
                              .asMap()
                              .entries
                              .map((e) => _buildSchoolCard(e.value, e.key))
                              .toList(),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionLabel, int delayMs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1.0,
          ),
        ),
        if (actionLabel != null)
          Text(
            actionLabel,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00A1FF),
            ),
          ),
      ],
    ).animate(delay: delayMs.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildSchoolsShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.05),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: GlassCard(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 60, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 8),
                            Container(width: 50, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String? value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        if (value == null)
          Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.05),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        else
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                val.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              );
            },
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildSchoolCard(SchoolModel school, int index) {
    final bool isExpiring =
        school.expiryDate != null &&
        school.expiryDate!.difference(DateTime.now()).inDays < 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(Routes.SCHOOL_DETAILS, arguments: school);
        },
        child: GlassCard(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          leftBorderColor: isExpiring
              ? const Color(0xFF334155)
              : const Color(0xFF00A1FF),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: (school.logoUrl != null && school.logoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(school.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (school.logoUrl == null || school.logoUrl!.isEmpty)
                    ? const Center(
                        child: Icon(
                          Icons.account_balance,
                          color: Colors.white70,
                          size: 28,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: school.inviteCode),
                            );
                            Get.snackbar(
                              'Copied',
                              'School Code ${school.inviteCode} copied.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFFFFC107),
                              colorText: Colors.black,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              school.inviteCode,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isExpiring
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isExpiring ? Colors.orange : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isExpiring ? 'EXPIRING' : 'ACTIVE',
                            style: GoogleFonts.spaceGrotesk(
                              color: isExpiring ? Colors.orange : Colors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      school.name,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Real-time counts from streams
                    Obx(() {
                      final coaches = controller.allCoaches
                          .where((u) => u.schoolId == school.id)
                          .length;
                      final athletes = controller.allAthletes
                          .where((u) => u.schoolId == school.id)
                          .length;
                      return Text(
                        '$athletes athletes • $coaches coaches',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ).animate(delay: (500 + (index * 100)).ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideX(begin: 0.05, duration: 800.ms, curve: Curves.easeOutCubic),
    );
  }
}
