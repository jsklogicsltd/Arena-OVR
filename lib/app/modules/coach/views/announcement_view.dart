import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/fire_sparks_background.dart';
import '../../../core/components/animated_glowing_border.dart';

class AnnouncementView extends StatefulWidget {
  const AnnouncementView({super.key});

  @override
  State<AnnouncementView> createState() => _AnnouncementViewState();
}

class _AnnouncementViewState extends State<AnnouncementView> {
  final CoachController controller = Get.find<CoachController>();
  final TextEditingController _contentController = TextEditingController();
  
  bool isPinned = false;
  bool isLoading = false;

  void _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      Get.snackbar('Error', 'Announcement cannot be empty.', backgroundColor: AppColors.primary, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);
    try {
      await controller.postAnnouncement(content, isPinned);
      setState(() => isLoading = false);
      Get.back();
      Get.snackbar('Success', 'Announcement posted!', backgroundColor: AppColors.tierGold, colorText: Colors.black);
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to post announcement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String coachName = controller.coachName.value.isNotEmpty ? controller.coachName.value : 'Coach';
      final String teamName = controller.currentTeam.value?.name.toUpperCase() ?? 'EAGLES FOOTBALL';
      final String coachPhoto = controller.coachPhotoUrl.value;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: StadiumBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // const FireSparksBackground(),
              SafeArea(
                child: Column(
                  children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      'ANNOUNCEMENTS',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _submit,
                      child: Text(
                        'POST',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coach Profile Row
                      Row(
                        children: [
                          AnimatedGlowingBorder(
                            // Preserve strict sizing: original 50x50.
                            // Add clean 3px glow gap around it.
                            diameter: 56,
                            borderWidth: 3,
                            duration: const Duration(seconds: 4),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFFDE047), width: 2),
                                  image: (coachPhoto.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(coachPhoto),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: coachPhoto.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white54, size: 22)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coachName,
                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                teamName,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fade().slideX(begin: -0.1),

                      const SizedBox(height: 24),

                      // Text Input Area
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _contentController,
                              maxLength: 500,
                              maxLines: 8,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Share with your team...',
                                hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                                counterText: '', // Hide default counter
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 20,
                              child: Text(
                                '${_contentController.text.length}/500',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 100.ms).fade().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Pin to top Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text('Pin to top', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          subtitle: Text('Pinned posts stay at the top of the team feed', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                          value: isPinned,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF334155),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          onChanged: (val) => setState(() => isPinned = val),
                        ),
                      ).animate(delay: 200.ms).fade().slideY(begin: 0.1),

                      const SizedBox(height: 32),

                      Text('PREVIEW', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold))
                        .animate(delay: 300.ms).fade(),
                      
                      const SizedBox(height: 16),

                      // Preview Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Yellow indicator line
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          AnimatedGlowingBorder(
                                            diameter: 30,
                                            borderWidth: 3,
                                            duration: const Duration(seconds: 4),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.white10,
                                                backgroundImage: coachPhoto.isNotEmpty
                                                    ? NetworkImage(coachPhoto)
                                                    : null,
                                                child: coachPhoto.isEmpty
                                                    ? const Icon(Icons.person,
                                                        color: Colors.white54,
                                                        size: 14)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(coachName, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                      Text('JUST NOW', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, letterSpacing: 1.0)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Skeleton lines
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 8,
                                    width: 200,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),

                    // Bottom Submit Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: isLoading ? null : _submit,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8), // Cyan color from design
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B4D8).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'POST TO TEAM',
                                        style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5),
                                      ),
                              ),
                            ),
                          ).animate(delay: 400.ms).fade().slideY(begin: 0.2),
                          const SizedBox(height: 12),
                          Text(
                            'All team members will be notified instantly',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12),
                          ).animate(delay: 400.ms).fade(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }); // end Obx
  }
}
