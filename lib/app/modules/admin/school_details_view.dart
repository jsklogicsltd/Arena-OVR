import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/fire_sparks_background.dart';
import '../../core/components/animated_glowing_border.dart';
import '../../data/models/school_model.dart';
import '../../data/models/user_model.dart';
import 'admin_controller.dart';

class SchoolDetailsView extends StatefulWidget {
  const SchoolDetailsView({super.key});

  @override
  State<SchoolDetailsView> createState() => _SchoolDetailsViewState();
}

class _SchoolDetailsViewState extends State<SchoolDetailsView> {
  late final SchoolModel school;
  late final AdminController adminCtrl;
  late final TextEditingController _maxTeamsCtrl;
  late final TextEditingController _maxAthletesCtrl;
  bool _schoolArgValid = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is SchoolModel) {
      school = arg;
      adminCtrl = Get.find<AdminController>();
      _maxTeamsCtrl =
          TextEditingController(text: school.maxTeamsLimit.toString());
      _maxAthletesCtrl =
          TextEditingController(text: school.maxAthletesLimit.toString());
      _schoolArgValid = true;
    }
  }

  @override
  void dispose() {
    if (_schoolArgValid) {
      _maxTeamsCtrl.dispose();
      _maxAthletesCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_schoolArgValid) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: StadiumBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'School Data Unavailable.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isExpiring =
        school.expiryDate != null &&
        school.expiryDate!.difference(DateTime.now()).inDays < 30;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // const FireSparksBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Get.back(),
                ).animate().fade().slideX(begin: -0.2),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedGlowingBorder(
                        // Preserve strict sizing: original 120x120.
                        // Add clean 3px glow gap around it.
                        diameter: 126,
                        borderWidth: 3,
                        duration: const Duration(seconds: 5),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              image: (school.logoUrl != null && school.logoUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(school.logoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.tierGold.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: (school.logoUrl == null || school.logoUrl!.isEmpty)
                                ? const Center(
                                    child: Icon(
                                      Icons.account_balance,
                                      color: Colors.white70,
                                      size: 60,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      )
                          .animate()
                          .fade(duration: 800.ms, curve: Curves.easeOutCubic)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic),

                      const SizedBox(height: 24),

                      // School Name
                      Text(
                        school.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 100.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1),

                      const SizedBox(height: 8),

                      // Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            school.email,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ).animate(delay: 200.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1),

                      const SizedBox(height: 32),

                      // Stats Row — live counts from streams
                      Obx(() {
                        final coachCount = adminCtrl.allCoaches
                            .where((u) => u.schoolId == school.id)
                            .length;
                        final athleteCount = adminCtrl.allAthletes
                            .where((u) => u.schoolId == school.id)
                            .length;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                title: 'COACHES',
                                value: coachCount.toString(),
                                icon: Icons.sports,
                                color: const Color(0xFF00E0FF),
                                delay: 300,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailCard(
                                title: 'ATHLETES',
                                value: athleteCount.toString(),
                                icon: Icons.directions_run,
                                color: const Color(0xFF39FF14),
                                delay: 400,
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 16),

                      // Invite Code
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.key, color: Color(0xFFFFC107), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'INVITE CODE',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  school.inviteCode,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFC107),
                                    letterSpacing: 8.0,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white70),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: school.inviteCode));
                                    Get.snackbar(
                                      'Copied',
                                      'School Code ${school.inviteCode} copied.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: const Color(0xFFFFC107),
                                      colorText: Colors.black,
                                      duration: const Duration(seconds: 2),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Status & Expiry
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: school.isActive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      school.isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EXPIRY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  school.expiryDate != null
                                      ? DateFormat('MMM dd, yyyy').format(school.expiryDate!)
                                      : 'N/A',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isExpiring ? Colors.orange : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: 600.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Subscription Limits — editable
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Row(
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFF00A1FF),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SUBSCRIPTION LIMITS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white54,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Two input fields side-by-side
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLimitField(
                                    label: 'MAX TEAMS',
                                    icon: Icons.groups_outlined,
                                    color: const Color(0xFF00A1FF),
                                    controller: _maxTeamsCtrl,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildLimitField(
                                    label: 'MAX ATHLETES',
                                    icon: Icons.directions_run_rounded,
                                    color: const Color(0xFF39FF14),
                                    controller: _maxAthletesCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Save button
                            Obx(() {
                              final saving = adminCtrl.isUpdatingLimits.value;
                              return SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          final newTeams = int.tryParse(
                                            _maxTeamsCtrl.text.trim(),
                                          );
                                          final newAthletes = int.tryParse(
                                            _maxAthletesCtrl.text.trim(),
                                          );
                                          if (newTeams == null ||
                                              newAthletes == null ||
                                              newTeams < 1 ||
                                              newAthletes < 1) {
                                            Get.snackbar(
                                              'Invalid Input',
                                              'Please enter positive whole numbers for both limits.',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              backgroundColor: Colors.red
                                                  .withValues(alpha: 0.8),
                                              colorText: Colors.white,
                                            );
                                            return;
                                          }
                                          adminCtrl.updateSchoolLimits(
                                            schoolId: school.id,
                                            newMaxTeams: newTeams,
                                            newMaxAthletes: newAthletes,
                                          );
                                        },
                                  icon: saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    saving ? 'SAVING...' : 'SAVE CHANGES',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A1FF),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF00A1FF)
                                            .withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ).animate(delay: 650.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1),

                      const SizedBox(height: 32),

                      // ── COACHES LIST ──
                      _buildSectionHeader('COACHES', const Color(0xFF00E0FF), Icons.sports, 700),
                      const SizedBox(height: 12),
                      Obx(() {
                        final coaches = adminCtrl.allCoaches
                            .where((u) => u.schoolId == school.id)
                            .toList();
                        if (coaches.isEmpty) {
                          return _buildEmptyState('No coaches have joined yet.', Icons.sports);
                        }
                        return Column(
                          children: coaches
                              .asMap()
                              .entries
                              .map((e) => _buildUserCard(e.value, e.key, isCoach: true))
                              .toList(),
                        );
                      }),

                      const SizedBox(height: 32),

                      // ── ATHLETES LIST ──
                      _buildSectionHeader('ATHLETES', const Color(0xFF39FF14), Icons.directions_run, 800),
                      const SizedBox(height: 12),
                      Obx(() {
                        final athletes = adminCtrl.allAthletes
                            .where((u) => u.schoolId == school.id)
                            .toList();
                        if (athletes.isEmpty) {
                          return _buildEmptyState('No athletes have joined yet.', Icons.directions_run);
                        }
                        return Column(
                          children: athletes
                              .asMap()
                              .entries
                              .map((e) => _buildUserCard(e.value, e.key, isCoach: false))
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon, int delayMs) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: color.withValues(alpha: 0.2)),
        ),
      ],
    ).animate(delay: delayMs.ms).fade(duration: 700.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 28),
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

  Widget _buildUserCard(UserModel user, int index, {required bool isCoach}) {
    final color = isCoach ? const Color(0xFF00E0FF) : const Color(0xFF39FF14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        leftBorderColor: color,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Avatar
            AnimatedGlowingBorder(
              // Preserve strict sizing: original 46x46.
              // Add clean 3px glow gap around it.
              diameter: 52,
              borderWidth: 3,
              duration: const Duration(seconds: 4),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: ClipOval(
                    child: (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: user.profilePicUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _initialsWidget(user.name, color),
                            errorWidget: (_, __, ___) => _initialsWidget(user.name, color),
                          )
                        : _initialsWidget(user.name, color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCoach && user.positionGroup != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${user.positionGroup ?? ''} · #${user.displayJerseyNumber}',
                      style: GoogleFonts.spaceGrotesk(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // OVR badge for athletes, role icon for coaches
            if (!isCoach && user.ovr > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    Text(
                      user.ovr.toString(),
                      style: GoogleFonts.spaceGrotesk(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'OVR',
                      style: GoogleFonts.spaceGrotesk(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  isCoach ? Icons.sports : Icons.directions_run,
                  color: color.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: (900 + (index * 70)).ms).fade(duration: 600.ms, curve: Curves.easeOutCubic).slideX(begin: 0.05, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _initialsWidget(String name, Color color) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildLimitField({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white54,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: '0',
              hintStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white24,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return GlassCard(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                val.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fade(duration: 800.ms, curve: Curves.easeOutCubic).scale(begin: const Offset(0.9, 0.9));
  }
}
