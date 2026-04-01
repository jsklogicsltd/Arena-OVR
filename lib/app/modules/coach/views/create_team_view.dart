import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/team_model.dart';
import '../../../routes/app_routes.dart';

class CreateTeamView extends StatefulWidget {
  const CreateTeamView({super.key});

  @override
  State<CreateTeamView> createState() => _CreateTeamViewState();
}

class _CreateTeamViewState extends State<CreateTeamView> {
  final CoachController controller = Get.find<CoachController>();
  final TextEditingController _nameController = TextEditingController();
  
  String selectedSport = 'FOOTBALL';
  final List<String> sports = ['FOOTBALL', 'BASKETBALL', 'BASEBALL', 'SOCCER', 'TRACK', 'VOLLEYBALL'];
  
  List<String> positionGroups = ['OFFENSE', 'DEFENSE', 'SPECIAL TEAMS'];
  List<String> selectedPositionGroups = ['OFFENSE', 'DEFENSE'];
  
  Color primaryColor = const Color(0xFF00A1FF); // Blue
  Color secondaryColor = const Color(0xFF1E293B); // Dark Slate

  final List<Color> swatchColors = [
    const Color(0xFF00A1FF), const Color(0xFFFFC107), const Color(0xFFE53935), const Color(0xFF43A047),
    const Color(0xFF8E24AA), const Color(0xFFFF9800), const Color(0xFF1E293B), const Color(0xFFFFFFFF),
  ];

  bool isLoading = false;
  File? _selectedLogo;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked != null) {
        setState(() => _selectedLogo = File(picked.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  void _showColorPicker(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select ${isPrimary ? "Primary" : "Secondary"} Color',
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: swatchColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isPrimary) primaryColor = color;
                        else secondaryColor = color;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a team name');
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final schoolId = userDoc.data()?['schoolId'] ?? 'UNKNOWN_SCHOOL';

      final newTeam = TeamModel(
        id: '',
        schoolId: schoolId,
        name: _nameController.text.trim(),
        teamCode: '',
        positionGroups: selectedPositionGroups.toList(),
        customTags: const [],
        primaryColor: '#${primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        secondaryColor: '#${secondaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        createdBy: uid,
      );

      final teamId = await controller.createTeam(newTeam);

      // Upload team logo if selected
      if (_selectedLogo != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('team_logos')
              .child('$teamId.jpg');
          await ref.putFile(_selectedLogo!);
          final logoUrl = await ref.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .update({'logoUrl': logoUrl});
        } catch (_) {
          // Logo upload failed silently — team still created
        }
      }

      // Fetch generated code
      final createdTeamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
      final teamCode = createdTeamDoc.data()?['teamCode'] ?? 'ERROR';

      setState(() => isLoading = false);
      _showSuccessOverlay(_nameController.text.trim(), teamCode);

    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to create team: $e');
    }
  }

  void _showSuccessOverlay(String teamName, String code) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: StadiumBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header ──────────────────────────────────────────
                      Icon(Icons.emoji_events, color: AppColors.tierGold, size: 72)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'TEAM CREATED!',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28, fontWeight: FontWeight.w900,
                          color: AppColors.tierGold, letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        teamName,
                        style: GoogleFonts.inter(
                          fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Invite Code Card ─────────────────────────────────
                      GlassCard(
                        backgroundColor: const Color(0x99172A36),
                        leftBorderColor: AppColors.tierGold,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                        child: Column(
                          children: [
                            Text(
                              'PLAYER INVITE CODE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11, color: Colors.white54,
                                letterSpacing: 2.0, fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              code,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 52, fontWeight: FontWeight.w900,
                                color: AppColors.tierGold, letterSpacing: 10,
                                shadows: [
                                  Shadow(
                                    color: AppColors.tierGold.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ).animate().scale(
                              begin: const Offset(0.5, 0.5),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share this code with your athletes to join the team.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white38, height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.15, curve: Curves.easeOutCubic),

                      const SizedBox(height: 24),

                      // ── Actions ───────────────────────────────────────────
                      _buildActionButton('COPY CODE', Icons.copy, () {
                        Clipboard.setData(ClipboardData(text: code));
                        Get.snackbar(
                          'Copied!', 'Invite code copied to clipboard',
                          backgroundColor: AppColors.tierGold,
                          colorText: Colors.black,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }),
                      const SizedBox(height: 14),
                      _buildActionButton('GO TO DASHBOARD', Icons.arrow_forward, () {
                        // When coach had no teams we used offAllNamed(CREATE_TEAM), so
                        // COACH is not on the stack. Navigate to coach dashboard explicitly.
                        Navigator.of(context).pop(); // close success overlay
                        Get.offAllNamed(Routes.COACH);
                      }, isPrimary: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.tierGold : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: isPrimary ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    if (controller.coachTeams.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 44),
                    ],
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CREATE YOUR TEAM',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ).animate().fade(duration: 800.ms, curve: Curves.easeOutQuint).slideY(begin: -0.5, curve: Curves.easeOutQuint).blurXY(begin: 10, end: 0, duration: 800.ms),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -20,
                              child: Icon(Icons.stadium, size: 100, color: Colors.white.withOpacity(0.05)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUILD YOUR ROSTER',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5
                                  ),
                                ).animate(delay: 150.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideX(begin: -0.2, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),
                                const SizedBox(height: 8),
                                Text(
                                  'Set up your team and start developing\nyour athletes to dominate the arena.',
                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
                                ).animate(delay: 250.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideX(begin: -0.2, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 1000.ms, curve: Curves.easeOutQuint).scale(begin: const Offset(0.90, 0.90), duration: 1000.ms, curve: Curves.easeOutQuint).blurXY(begin: 15, end: 0, duration: 1000.ms),
                      
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TEAM LOGO
                            Text('TEAM LOGO', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                                .animate(delay: 280.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint),
                            const SizedBox(height: 12),
                            Center(
                              child: GestureDetector(
                                onTap: _pickLogo,
                                child: StatefulBuilder(
                                  builder: (context, setInner) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(0.07),
                                            border: Border.all(
                                              color: primaryColor.withOpacity(0.6),
                                              width: 2.5,
                                            ),
                                            image: _selectedLogo != null
                                                ? DecorationImage(
                                                    image: FileImage(_selectedLogo!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: _selectedLogo == null
                                              ? Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.shield_outlined,
                                                        color: primaryColor.withOpacity(0.6),
                                                        size: 32),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Add Logo',
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: Colors.white38,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF0A0E1A),
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(Icons.camera_alt,
                                                color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            )
                            .animate(delay: 290.ms)
                            .fade(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),

                            const SizedBox(height: 28),

                            // TEAM NAME
                            Text('TEAM NAME', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                                .animate(delay: 300.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0x800A0E1A),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Eagles Football',
                                  hintStyle: GoogleFonts.inter(color: Colors.white24),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ).animate(delay: 350.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideY(begin: 0.1, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),

                            const SizedBox(height: 32),

                            // SPORT
                            Text('SPORT', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                                .animate(delay: 450.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: sports.map((sport) {
                                  final isSelected = selectedSport == sport;
                                  return GestureDetector(
                                    onTap: () => setState(() => selectedSport = sport),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        sport,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: isSelected ? Colors.white : Colors.white54,
                                          fontSize: 12, fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ).animate(delay: 500.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideY(begin: 0.1, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),

                            const SizedBox(height: 32),

                            // POSITION GROUPS
                            Text('POSITION GROUPS', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                                .animate(delay: 600.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: positionGroups.map((group) {
                                final isSelected = selectedPositionGroups.contains(group);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedPositionGroups.remove(group);
                                      } else {
                                        selectedPositionGroups.add(group);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                                    ),
                                    child: Text(
                                      group,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: isSelected ? AppColors.primary : Colors.white54,
                                        fontSize: 12, fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ).animate(delay: 650.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideY(begin: 0.1, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),
                          ],
                        ),
                      ).animate(delay: 150.ms).fade(duration: 1000.ms, curve: Curves.easeOutQuint).slideY(begin: 0.2, curve: Curves.easeOutQuint).blurXY(begin: 8, end: 0, duration: 800.ms),
                      
                      const SizedBox(height: 32),

                      // TEAM IDENTITY
                      Text('TEAM IDENTITY', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                          .animate(delay: 750.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorPicker(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Primary', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorPicker(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: secondaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white24, width: 1),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Secondary', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate(delay: 800.ms).fade(duration: 800.ms, curve: Curves.easeOutQuint).slideY(begin: 0.1, curve: Curves.easeOutQuint).blurXY(begin: 4, end: 0, duration: 800.ms),

                      const SizedBox(height: 48),

                      // SUBMIT BUTTON
                      GestureDetector(
                        onTap: isLoading ? null : _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B6B0D),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: isLoading 
                            ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREATE TEAM & GENERATE CODE',
                                    style: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.bolt, color: Colors.black, size: 20),
                                ],
                              ),
                        ),
                      ).animate(delay: 950.ms).fade(duration: 1000.ms, curve: Curves.easeOutQuint).slideY(begin: 0.2, curve: Curves.easeOutQuint).blurXY(begin: 10, end: 0, duration: 1000.ms),

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
}
