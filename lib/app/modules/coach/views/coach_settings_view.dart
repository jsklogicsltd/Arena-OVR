import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/components/animated_glowing_border.dart';
import '../../../routes/app_routes.dart';
import 'manage_roster_screen.dart';

class CoachSettingsView extends StatefulWidget {
  const CoachSettingsView({super.key});

  @override
  State<CoachSettingsView> createState() => _CoachSettingsViewState();
}

class _CoachSettingsViewState extends State<CoachSettingsView> {
  final CoachController controller = Get.find<CoachController>();

  bool pushEnabled = true;
  bool hapticEnabled = true;
  bool ratingEnabled = false;

  void _showEditNameDialog() {
    final text = TextEditingController(text: controller.coachName.value == 'Loading...' ? '' : controller.coachName.value);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF101A24),
        title: Text(
          'Edit Name',
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 40,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => TextButton(
                onPressed: controller.isUpdatingName.value
                    ? null
                    : () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        await controller.updateCoachName(text.text);
                        Get.back(closeOverlays: true);
                      },
                child: controller.isUpdatingName.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final team = controller.currentTeam.value;
      
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: StadiumBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // const FireSparksBackground(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // balance the right icon
                      Text(
                        'SETTINGS',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 28),
                        onPressed: () {}, // Optional settings action
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glass Header Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  // Avatar with camera-icon overlay
                                  Obx(() {
                                    final url = controller.coachPhotoUrl.value;
                                    final uploading = controller.isUploadingPhoto.value;
                                    return GestureDetector(
                                      onTap: controller.updateCoachPhoto,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Circle avatar (wrapped with premium glow).
                                          AnimatedGlowingBorder(
                                            // Preserve strict sizing: original 88x88.
                                            // Add clean 3px glow gap around it.
                                            diameter: 94,
                                            borderWidth: 3,
                                            duration: const Duration(seconds: 4),
                                            child: SizedBox(
                                              width: 88,
                                              height: 88,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: AppColors.primary,
                                                      width: 2),
                                                  color: Colors.white10,
                                                  image: url.isNotEmpty
                                                      ? DecorationImage(
                                                          image:
                                                              CachedNetworkImageProvider(url),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: url.isEmpty
                                                    ? const Icon(Icons.person,
                                                        color: Colors.white54,
                                                        size: 40)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          // Upload-in-progress overlay
                                          if (uploading)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black54,
                                                ),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Camera icon badge
                                          if (!uploading)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF0F172A),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 5),
                                  Obx(() => Text(
                                    controller.coachName.value == 'Loading...'
                                        ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Coach')
                                        : controller.coachName.value,
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  )),
                                  const SizedBox(height: 4),
                                  Text(
                                    FirebaseAuth.instance.currentUser?.email ?? 'coach@school.edu',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Badges/Buttons
                                  Obx(() => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      controller.coachRoleBadge.value,
                                      style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                    ),
                                  )),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _showEditNameDialog,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        'EDIT PROFILE',
                                        style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // TEAM MANAGEMENT SECTION
                        _buildSectionTitle('TEAM MANAGEMENT').animate(delay: 50.ms).fade(),
                        const SizedBox(height: 12),
                        _buildSettingsGroup(
                          children: [
                            _buildSettingsItem(
                              title: 'Team Settings',
                              showArrow: true,
                              onTap: () => Get.toNamed(Routes.TEAM_SETTINGS),
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              title: 'Season Management',
                              showArrow: true,
                              onTap: () => Get.toNamed(Routes.SEASON_HQ),
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              title: 'Team\nCode',
                              trailingWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    team?.teamCode ?? 'TEAM4X',
                                    style: GoogleFonts.spaceGrotesk(color: AppColors.tierGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy, color: AppColors.tierGold, size: 16),
                                ],
                              ),
                              onTap: () {
                                final code = team?.teamCode ?? 'TEAM4X';
                                Clipboard.setData(ClipboardData(text: code));
                                Get.snackbar('Copied', 'Team code copied to clipboard', backgroundColor: AppColors.primary, colorText: Colors.white);
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              title: 'Manage Roster',
                              showArrow: true,
                              onTap: () {
                                final teamId = controller.currentTeam.value?.id;
                                if (teamId == null || teamId.isEmpty) return;
                                Get.to(() => ManageRosterScreen(teamId: teamId));
                              },
                            ),
                          ],
                        ).animate(delay: 100.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // PREFERENCES SECTION
                        _buildSectionTitle('PREFERENCES').animate(delay: 150.ms).fade(),
                        const SizedBox(height: 12),
                        _buildSettingsGroup(
                          children: [
                            _buildSettingsSwitch(
                              title: 'Push Notifications',
                              value: pushEnabled,
                              onChanged: (val) => setState(() => pushEnabled = val),
                            ),
                            // NOTE: Other preferences are hidden for now.
                            // _buildDivider(),
                            // _buildSettingsSwitch(
                            //   title: 'Haptic Feedback',
                            //   value: hapticEnabled,
                            //   onChanged: (val) => setState(() => hapticEnabled = val),
                            // ),
                            // _buildDivider(),
                            // _buildSettingsSwitch(
                            //   title: 'Rating Notifications',
                            //   value: ratingEnabled,
                            //   onChanged: (val) => setState(() => ratingEnabled = val),
                            // ),
                          ],
                        ).animate(delay: 200.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // SCHOOL SECTION
                        _buildSectionTitle('SCHOOL').animate(delay: 250.ms).fade(),
                        const SizedBox(height: 12),
                        _buildSettingsGroup(
                          children: [
                            _buildSettingsItem(
                              title: 'School:',
                              trailingWidget: Text(
                                team?.schoolName ?? 'Lincoln High School',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                              ),
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              title: 'School Code:',
                              trailingWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    team?.schoolInviteCode?.toUpperCase() ?? 'LHS492',
                                    style: GoogleFonts.spaceGrotesk(color: AppColors.tierGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.lock_outline, color: Colors.white24, size: 16),
                                ],
                              ),
                              onTap: () {},
                            ),
                          ],
                        ).animate(delay: 300.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // ACCOUNT SECTION
                        _buildSectionTitle('ACCOUNT').animate(delay: 350.ms).fade(),
                        const SizedBox(height: 12),
                        _buildSettingsGroup(
                          children: [
                            _buildSettingsItem(
                              title: 'Change Password',
                              showArrow: true,
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              title: 'Log Out',
                              trailingWidget: const Icon(Icons.logout, color: Colors.white54, size: 18),
                              onTap: () async {
                                controller.logout();
                              },
                            ),
                          ],
                        ).animate(delay: 400.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // DANGER ZONE
                        _buildSectionTitle('DANGER ZONE', color: const Color(0xFFEF4444)).animate(delay: 450.ms).fade(),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.deleteAccount(),
                            borderRadius: BorderRadius.circular(24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Delete My Account',
                                            style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Permanently deletes your account and profile data. Team/org records may be retained as required.',
                                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: 500.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 48),

                        // App Version
                        Center(
                          child: Text(
                            'ARENA V1.0.0',
                            style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
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
    });
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: color ?? Colors.white.withOpacity(0.8), 
          fontSize: 10, 
          letterSpacing: 2.0, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withOpacity(0.08), height: 1, thickness: 1);
  }

  Widget _buildSettingsItem({
    required String title,
    bool showArrow = false,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
              ),
            ),
            if (trailingWidget != null) trailingWidget,
            if (showArrow) const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
