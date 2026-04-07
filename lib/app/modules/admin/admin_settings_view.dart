import 'package:arena_ovr/app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/components/animated_glowing_border.dart';
import 'admin_controller.dart';

class AdminSettingsView extends GetView<AdminController> {
  const AdminSettingsView({super.key});

  void _showEditNameDialog() {
    final text = TextEditingController(text: controller.adminName.value);
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                        await controller.updateAdminName(text.text);
                        // Force-close dialog even if overlays stack.
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x0DFFFFFF),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ).animate().fade().slideX(begin: -0.2),
                    Expanded(
                      child: Center(
                        child: Text(
                          'ADMIN SETTINGS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ).animate().fade().slideX(begin: -0.2),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  GestureDetector(
                                    onTap: controller.updateAdminPhoto,
                                    child: Obx(() {
                                      final url = controller.adminPhotoUrl.value;
                                      final uploading =
                                          controller.isUpdatingPhoto.value;
                                      return AnimatedGlowingBorder(
                                        diameter: 86,
                                        borderWidth: 3,
                                        duration: const Duration(seconds: 4),
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFFFFB800),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFFFFB800)
                                                          .withValues(
                                                              alpha: 0.05),
                                                      blurRadius: 15,
                                                      spreadRadius: 0,
                                                      offset: const Offset(0, 0),
                                                    ),
                                                  ],
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  image: url.isNotEmpty
                                                      ? DecorationImage(
                                                          image:
                                                              CachedNetworkImageProvider(
                                                                  url),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: url.isEmpty
                                                    ? const Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 40,
                                                          color: Colors.white70,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              if (uploading)
                                                Container(
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.black54,
                                                  ),
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFF00A1FF),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => Text(
                                  controller.adminName.value.isEmpty
                                      ? 'Loading...'
                                      : controller.adminName.value,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  controller.adminEmail.value.isEmpty
                                      ? 'Loading...'
                                      : controller.adminEmail.value,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB800,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFB800,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'SUPER ADMIN',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFFFB800),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                onPressed: _showEditNameDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00A1FF),
                                  side: const BorderSide(
                                    color: Color(0xFF00A1FF),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'EDIT PROFILE',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: 100.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 32),

                      // Platform Section
                      _buildSectionHeader(
                        'PLATFORM',
                      ).animate(delay: 200.ms).fade(),
                      const SizedBox(height: 8),
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildListTile(
                              Icons.school_outlined,
                              'Manage Schools',
                              onTap: () => Get.back(),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildListTile(
                              Icons.bar_chart,
                              'Generate Reports',
                              badge: 'COMING SOON',
                            ),
                          ],
                        ),
                      ).animate(delay: 300.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 24),

                      // Notifications Section
                      _buildSectionHeader(
                        'NOTIFICATIONS',
                      ).animate(delay: 400.ms).fade(),
                      const SizedBox(height: 8),
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              Icons.notifications_outlined,
                              'Push Notifications',
                              true,
                            ),
                            // NOTE: Other notification preferences are hidden for now.
                            // Divider(
                            //   color: Colors.white.withValues(alpha: 0.1),
                            //   height: 1,
                            // ),
                            // _buildSwitchTile(
                            //   Icons.person_add_outlined,
                            //   'New Coach Alerts',
                            //   true,
                            // ),
                          ],
                        ),
                      ).animate(delay: 500.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 24),

                      // Account Section
                      _buildSectionHeader(
                        'ACCOUNT',
                      ).animate(delay: 600.ms).fade(),
                      const SizedBox(height: 8),
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildListTile(
                              Icons.lock_outline,
                              'Change Password',
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildListTile(
                              Icons.logout,
                              'Log Out',
                              isDestructive: true,
                              onTap: () => controller.logout(),
                            ),
                          ],
                        ),
                      ).animate(delay: 700.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 24),

                      _buildSectionHeader(
                        'DANGER ZONE',
                      ).animate(delay: 750.ms).fade(),
                      const SizedBox(height: 8),
                      GlassCard(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(
                            Icons.delete_forever_outlined,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                          title: Text(
                            'Delete My Account',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFEF4444),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Permanent — removes your login and profile data.',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 20,
                          ),
                          onTap: () => controller.deleteAccount(),
                        ),
                      ).animate(delay: 800.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 48),

                      Center(
                        child: Text(
                          'ARENA v1.0.0',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white24,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ).animate(delay: 800.ms).fade(),
                      const SizedBox(height: 48),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    String? badge,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : const Color(0xFF00A1FF),
        size: 24,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: isDestructive ? Colors.redAccent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white24,
        size: 20,
      ),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A1FF), size: 24),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          value: value,
          activeColor: const Color(0xFF00A1FF),
          onChanged: (v) {},
        ),
      ),
    );
  }
}
