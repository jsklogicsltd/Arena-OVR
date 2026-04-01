import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';

class TeamSettingsView extends StatefulWidget {
  const TeamSettingsView({super.key});

  @override
  State<TeamSettingsView> createState() => _TeamSettingsViewState();
}

class _TeamSettingsViewState extends State<TeamSettingsView> {
  final CoachController controller = Get.find<CoachController>();

  late TextEditingController _nameController;
  late String primaryColorHex;
  late String secondaryColorHex;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final team = controller.currentTeam.value;
    _nameController = TextEditingController(text: team?.name ?? '');
    primaryColorHex = team?.primaryColor ?? '8B0000';
    secondaryColorHex = team?.secondaryColor ?? 'FFFFFF';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  void _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      Get.snackbar('Error', 'Please enter a team name', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withValues(alpha: 0.85), colorText: Colors.white);
      return;
    }
    setState(() => isLoading = true);
    try {
      await controller.updateBranding(
        primaryColorHex,
        secondaryColorHex,
        null,
        teamName: newName,
      );
      setState(() => isLoading = false);
      Get.back();
      Get.snackbar('Saved', 'Team name and settings updated!', backgroundColor: AppColors.tierGold, colorText: Colors.black);
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to save: $e');
    }
  }

  void _pickColor(bool isPrimary) async {
    Color currentColor = _parseColor(isPrimary ? primaryColorHex : secondaryColorHex);
    Color pickedColor = currentColor;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isPrimary ? 'Primary Color' : 'Secondary Color',
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (c) => pickedColor = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final hex = pickedColor.value.toRadixString(16).substring(2).toUpperCase();
              setState(() {
                if (isPrimary) primaryColorHex = hex;
                else secondaryColorHex = hex;
              });
              Navigator.pop(ctx);
            },
            child: Text('Apply', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final team = controller.currentTeam.value;
      final teamCode = team?.teamCode ?? 'aEAM4X';
      final topPlayer = controller.roster.isNotEmpty ? controller.roster.first : null;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: StadiumBackground(
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
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
                        'TEAM SETTINGS',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _save,
                        child: Text(
                          'SAVE',
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
                        // Logo Circle
                        Center(
                          child: Obx(() {
                            final logoUrl = controller.currentTeam.value?.logoUrl;
                            final uploading = controller.isUploadingTeamLogo.value;
                            return GestureDetector(
                              onTap: controller.updateTeamLogo,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 144,
                                    height: 144,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141B2D),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _parseColor(primaryColorHex).withOpacity(0.4),
                                          blurRadius: 30,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                      image: logoUrl != null && logoUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(logoUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: logoUrl == null || logoUrl.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.shield_outlined, color: Colors.white54, size: 36),
                                                const SizedBox(height: 4),
                                                Text(
                                                  team?.name.toUpperCase() ?? 'TEAM',
                                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                  // Upload loading overlay
                                  if (uploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black54,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Camera badge
                                  if (!uploading)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF0F172A),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ).animate().fade().scale(begin: const Offset(0.9, 0.9)),

                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            'TAP TO CHANGE LOGO',
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Team Identity
                        Text('TEAM IDENTITY', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold))
                          .animate().fade(),

                        const SizedBox(height: 12),

                        // Team Name Input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                          ),
                        ).animate(delay: 100.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        // Team Code Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.tierGold.withOpacity(0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TEAM CODE',
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    teamCode,
                                    style: GoogleFonts.spaceGrotesk(color: AppColors.tierGold, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: teamCode));
                                  Get.snackbar('Copied!', 'Team code copied to clipboard', backgroundColor: AppColors.primary, colorText: Colors.white);
                                },
                                child: Text(
                                  'REGENERATE CODE',
                                  style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 150.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        Text('TEAM COLORS', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold))
                          .animate(delay: 200.ms).fade(),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            // Primary Color Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickColor(true),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: _parseColor(primaryColorHex).withOpacity(0.5), width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _parseColor(primaryColorHex).withOpacity(0.4),
                                            blurRadius: 30,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: _parseColor(primaryColorHex),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text('PRIMARY', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Secondary Color Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickColor(false),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: _parseColor(secondaryColorHex).withOpacity(0.5), width: 1),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: _parseColor(secondaryColorHex),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text('SECONDARY', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 250.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        // Gradient Bar (color preview)
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [_parseColor(primaryColorHex), _parseColor(secondaryColorHex)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ).animate(delay: 300.ms).fade(),

                        const SizedBox(height: 32),

                        // Preview Section
                        Text('PREVIEW', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold))
                          .animate(delay: 350.ms).fade(),

                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _parseColor(primaryColorHex).withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                children: [
                                  // Athlete image with OVR badge
                                  Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _parseColor(primaryColorHex), width: 2),
                                          image: topPlayer?.profilePicUrl != null
                                            ? DecorationImage(image: CachedNetworkImageProvider(topPlayer!.profilePicUrl!), fit: BoxFit.cover)
                                            : null,
                                          color: Colors.white10,
                                        ),
                                        child: topPlayer?.profilePicUrl == null
                                          ? const Icon(Icons.person, color: Colors.white38, size: 36)
                                          : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _parseColor(primaryColorHex),
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'OVR ${topPlayer?.ovr ?? 92}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topPlayer?.name.toUpperCase() ?? 'MARCUS JOHNSON',
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${team?.name.toUpperCase() ?? 'APEX WARRIORS'} • ${topPlayer?.positionGroup ?? 'SF'}',
                                          style: GoogleFonts.inter(color: _parseColor(primaryColorHex), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 12),
                                        // Stat bars — primary, secondary, muted
                                        Row(
                                          children: [
                                            _miniBar(_parseColor(primaryColorHex), 0.7),
                                            const SizedBox(width: 6),
                                            _miniBar(_parseColor(secondaryColorHex), 0.4),
                                            const SizedBox(width: 6),
                                            _miniBar(Colors.white24, 0.3),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate(delay: 400.ms).fade().slideY(begin: 0.1),

                        const SizedBox(height: 40),

                        Center(
                          child: GestureDetector(
                            onTap: () => Get.defaultDialog(
                              title: 'Deactivate Team?',
                              titleStyle: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                              middleText: 'This will deactivate your team. Players will lose access.',
                              middleTextStyle: GoogleFonts.inter(color: Colors.white70),
                              backgroundColor: const Color(0xFF0F172A),
                              buttonColor: const Color(0xFFEF4444),
                              cancelTextColor: Colors.white,
                              confirmTextColor: Colors.white,
                              textConfirm: 'Deactivate',
                              textCancel: 'Cancel',
                              onConfirm: () => Get.back(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFEF4444), width: 1),
                              ),
                              child: Text(
                                'DEACTIVATE TEAM',
                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ),
                          ),
                        ).animate(delay: 500.ms).fade(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _miniBar(Color color, double fill) {
    return Expanded(
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Colors.white12,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fill,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
