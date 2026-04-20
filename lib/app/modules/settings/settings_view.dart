import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'settings_controller.dart';
import '../player/player_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/components/animated_glowing_border.dart';
import '../../data/models/user_model.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  static const String _appVersion = 'ARENA V1.0.0';

  void _showEditNameDialog() {
    final player = Get.find<PlayerController>();
    final text = TextEditingController(text: player.athlete.value?.name ?? '');
    final jersey = TextEditingController(
        text: player.athlete.value?.displayJerseyNumber ?? '0');
    final position = TextEditingController(text: player.athlete.value?.positionGroup ?? '');
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF101A24),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
            const SizedBox(height: 10),
            TextField(
              controller: jersey,
              maxLength: 6,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter jersey number',
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
            const SizedBox(height: 10),
            TextField(
              controller: position,
              maxLength: 24,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter position (optional)',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => TextButton(
                onPressed: player.isUpdatingName.value
                    ? null
                    : () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        await player.updateAthleteProfile(
                          rawName: text.text,
                          rawJerseyNumber: jersey.text,
                          rawPositionGroup: position.text,
                        );
                        Get.back(closeOverlays: true);
                      },
                child: player.isUpdatingName.value
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
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    return StadiumBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // const FireSparksBackground(),
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Obx(() {
                    final player = Get.find<PlayerController>();
                    final athlete = player.athlete.value;
                    final team = player.team.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(athlete),
                        const SizedBox(height: 20),
                        _buildSectionLabel('PHYSICAL PROFILE'),
                        const SizedBox(height: 8),
                        _buildPhysicalProfileCard(athlete),
                        const SizedBox(height: 20),
                        _buildSectionLabel('PREFERENCES'),
                        const SizedBox(height: 8),
                        _buildPreferencesCard(),
                        const SizedBox(height: 20),
                        _buildSectionLabel('TEAM INFO'),
                        const SizedBox(height: 8),
                        _buildTeamInfoCard(team, athlete),
                        const SizedBox(height: 20),
                        _buildSectionLabel('ACCOUNT'),
                        const SizedBox(height: 8),
                        _buildAccountCard(context),
                        const SizedBox(height: 20),
                        _buildSectionLabel('DANGER ZONE', isDanger: true),
                        const SizedBox(height: 8),
                        _buildDangerZoneCard(),
                        const SizedBox(height: 28),
                        Text(
                          _appVersion,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            )
          else
            const SizedBox(width: 44, height: 44),
          Expanded(
            child: Text(
              'SETTINGS',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  // Figma: Profile Section 358x332, radius 24, fill #FFFFFF 0.2%, shadow: y 25, blur 50, spread -12, black 25%
  Widget _buildProfileCard(UserModel? athlete) {
    final player = Get.find<PlayerController>();
    final name = athlete?.name ?? 'Marcus Johnson';
    final email = athlete?.email ?? 'marcus@school.edu';
    // Default to 0 until explicitly set by the athlete.
    final jersey = athlete == null ? '0' : athlete.displayJerseyNumber;
    final position = athlete?.positionGroup ?? 'QUARTERBACK';
    final photoUrl = athlete?.profilePicUrl;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 332),
      decoration: BoxDecoration(
        color: const Color(0x03FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 25),
            blurRadius: 50,
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: player.updatePhoto,
                  child: Obx(() {
                    final uploading = player.isUploadingPhoto.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedGlowingBorder(
                          diameter: 106,
                          borderWidth: 3,
                          duration: const Duration(seconds: 4),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.tierGold, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.tierGold
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: photoUrl != null &&
                                            photoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            placeholder: (_, __) =>
                                                _avatarPlaceholder(100),
                                            errorWidget: (_, __, ___) =>
                                                _avatarPlaceholder(100),
                                          )
                                        : _avatarPlaceholder(100),
                                  ),
                                ),
                                if (uploading)
                                  Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!uploading)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '#$jersey • ${position.toUpperCase()}',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _showEditNameDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(
                    'EDIT PROFILE',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalProfileCard(UserModel? athlete) {
    final player = Get.find<PlayerController>();

    final gradeCtrl = TextEditingController(
      text: athlete?.grade?.toString() ?? '',
    );
    final heightCtrl = TextEditingController(
      text: athlete?.heightInches?.toString() ?? '',
    );
    final weightCtrl = TextEditingController(
      text: athlete?.weightLbs?.toString() ?? '',
    );

    final currentPower = athlete?.powerProfile;
    final currentSpeed = athlete?.speedProfile;

    return _buildGlassCard(
      children: [
        Row(
          children: [
            Expanded(
              child: _numericField(gradeCtrl, 'GRADE', hint: '9–12'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numericField(heightCtrl, 'HEIGHT (IN)', hint: 'e.g. 70'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numericField(weightCtrl, 'WEIGHT (LBS)', hint: 'e.g. 175'),
            ),
          ],
        ),
        if (currentPower != null || currentSpeed != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (currentPower != null)
                _profileChip('POWER', currentPower.toUpperCase(), AppColors.primary),
              if (currentPower != null && currentSpeed != null)
                const SizedBox(width: 8),
              if (currentSpeed != null)
                _profileChip('SPEED', currentSpeed.toUpperCase(), AppColors.tierGold),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Obx(() => SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: player.isSavingPhysical.value
                    ? null
                    : () {
                        final g = int.tryParse(gradeCtrl.text.trim());
                        final h = int.tryParse(heightCtrl.text.trim());
                        final w = int.tryParse(weightCtrl.text.trim());
                        if (g == null || h == null || w == null) {
                          Get.snackbar('Error', 'Enter valid numbers for all fields',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withValues(alpha: 0.85),
                            colorText: Colors.white);
                          return;
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                        player.updatePhysicalProfile(
                          grade: g,
                          heightInches: h,
                          weightLbs: w,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: player.isSavingPhysical.value
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(
                        'SAVE PHYSICAL PROFILE',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            )),
      ],
    );
  }

  Widget _numericField(TextEditingController ctrl, String label, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      color: Colors.white12,
      child: Icon(Icons.person_rounded, size: size * 0.5, color: AppColors.tierGold),
    );
  }

  Widget _buildSectionLabel(String text, {bool isDanger = false}) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        color: isDanger ? const Color(0xFFFF3333) : Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return _buildGlassCard(
      children: [
        _buildSwitchRow('Push Notifications', controller.pushNotifications, controller.togglePushNotifications, isOn: true),
        // NOTE: Other preferences are hidden for now.
        // Divider(height: 24, color: Colors.white.withValues(alpha: 0.1)),
        // _buildSwitchRow('Haptic Feedback', controller.hapticFeedback, controller.toggleHapticFeedback, isOn: false),
      ],
    );
  }

  Widget _buildSwitchRow(String label, RxBool obs, ValueChanged<bool> onToggle, {bool isOn = false}) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch.adaptive(
                value: obs.value,
                onChanged: onToggle,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ));
  }

  Widget _buildTeamInfoCard(dynamic team, UserModel? athlete) {
    final player = Get.find<PlayerController>();
    final teamName = team?.name ?? '—';
    final schoolName = team?.schoolName ?? '—';
    final coachName = player.coachName.value ?? '—';

    return _buildGlassCard(
      children: [
        _buildInfoRow('TEAM', Icons.groups_rounded, teamName, showDot: true),
        const SizedBox(height: 12),
        _buildInfoRow('SCHOOL', Icons.school_rounded, schoolName),
        const SizedBox(height: 12),
        _buildInfoRow('COACH', Icons.person_rounded, coachName),
      ],
    );
  }

  Widget _buildInfoRow(String label, IconData icon, String value, {bool showDot = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        if (showDot) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tierGold,
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return _buildGlassCard(
      children: [
        _buildActionRow('Change Password', Icons.chevron_right_rounded, () => controller.changePassword(context)),
        Divider(height: 24, color: Colors.white.withValues(alpha: 0.1)),
        _buildActionRow('Log Out', Icons.logout_rounded, () {
          try {
            Get.find<PlayerController>().logout();
          } catch (_) {}
        }),
      ],
    );
  }

  Widget _buildActionRow(String label, IconData trailingIcon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(trailingIcon, color: Colors.white54, size: 22),
          ],
        ),
      ),
    );
  }

  // Danger zone Figma: red heading, red-bordered button (dark fill), left-aligned gray warning
  static const Color _dangerRed = Color(0xFFFF3333);
  static const Color _warningGray = Color(0xFFB0B0B0);

  Widget _buildDangerZoneCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.deleteAccount,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _dangerRed, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_forever_rounded, color: _dangerRed, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'DELETE MY ACCOUNT',
                    style: GoogleFonts.spaceGrotesk(
                      color: _dangerRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'THIS WILL PERMANENTLY DELETE ALL YOUR DATA AND REMOVE YOU FROM THE TEAM. THIS ACTION CANNOT BE UNDONE.',
          style: GoogleFonts.spaceGrotesk(
            color: _warningGray,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}
