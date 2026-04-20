import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/arena_button.dart';
import '../../core/widgets/fire_sparks_background.dart';
import '../../core/components/animated_glowing_border.dart';
import 'admin_controller.dart';

class CreateSchoolView extends StatefulWidget {
  const CreateSchoolView({super.key});

  @override
  State<CreateSchoolView> createState() => _CreateSchoolViewState();
}

class _CreateSchoolViewState extends State<CreateSchoolView> {
  final AdminController controller = Get.find<AdminController>();
  bool _didReset = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReset) return;
    _didReset = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetCreateSchoolFlow();
    });
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x0DFFFFFF),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            controller.resetCreateSchoolFlow();
                            Get.back();
                          },
                        ),
                      ),
                    ),
                    Text(
                      'NEW SCHOOL',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ).animate().fade().slideX(begin: -0.2),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unified Form Card
                      GlassCard(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Upload UI
                            Center(
                              child: GestureDetector(
                                onTap: controller.pickSchoolLogo,
                                child: Obx(
                                  () {
                                    final file = controller.selectedSchoolLogo.value;
                                    // Preserve strict sizing: original 100x100.
                                    // Add clean 3px glow gap around it.
                                    return AnimatedGlowingBorder(
                                      diameter: 106,
                                      borderWidth: 3,
                                      duration: const Duration(seconds: 4),
                                      child: SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF00A1FF).withValues(alpha: 0.5),
                                            ),
                                            image: file != null
                                                ? DecorationImage(
                                                    image: FileImage(file),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: file == null
                                              ? const Icon(
                                                  Icons.add_a_photo,
                                                  color: Colors.white54,
                                                  size: 32,
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'SCHOOL DETAILS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00A1FF),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassTextField(
                              hintText: 'Enter school name',
                              prefixIcon: Icons.domain,
                              controller: controller.nameController,
                            ),
                            const SizedBox(height: 16),
                            GlassTextField(
                              hintText: 'email@school.edu',
                              prefixIcon: Icons.email_outlined,
                              controller: controller.emailController,
                            ),
                            const SizedBox(height: 32),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'SUBSCRIPTION LIMITS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildLimitField(
                                    label: 'Max Teams',
                                    icon: Icons.groups_outlined,
                                    controller: controller.maxTeamsController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildLimitField(
                                    label: 'Max Athletes',
                                    icon: Icons.directions_run_rounded,
                                    controller: controller.maxAthletesController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'SUBSCRIPTION',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      controller.expiryDate.value ??
                                      DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365 * 10),
                                  ),
                                );
                                if (picked != null) {
                                  controller.expiryDate.value = picked;
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'YEARLY',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Obx(
                                          () => Text(
                                            'EXPIRES ${DateFormat('MMM yyyy').format(controller.expiryDate.value ?? DateTime.now()).toUpperCase()}',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF39FF14,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF39FF14,
                                          ).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF39FF14),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ACTIVE',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: const Color(0xFF39FF14),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fade().slideY(begin: 0.2),
                      const SizedBox(height: 32),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x0D00A1FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x3300A1FF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF00A1FF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'The Coach will set up the team logo and colors after joining the dashboard.',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms).fade(),
                      const SizedBox(height: 48),

                      // Submit button or Generated Code
                      Obx(() {
                        if (controller.generatedSchoolCode.value.isNotEmpty) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          controller.generatedSchoolCode.value,
                                    ),
                                  );
                                  Get.snackbar(
                                    'Copied',
                                    'Code copied to clipboard',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.8,
                                    ),
                                    colorText: Colors.white,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00A1FF,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        controller.generatedSchoolCode.value,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Color(0xFF00A1FF),
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: controller
                                                  .generatedSchoolCode
                                                  .value,
                                            ),
                                          );
                                          Get.snackbar(
                                            'Copied',
                                            'Code copied to clipboard',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.green
                                                .withValues(alpha: 0.8),
                                            colorText: Colors.white,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade().scale(),
                              const SizedBox(height: 24),
                              ArenaButton(
                                label: 'DONE',
                                onPressed: () {
                                  controller.resetCreateSchoolFlow();
                                  Get.back();
                                },
                              ).animate().fade().slideY(begin: 0.2),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            ArenaButton(
                              label: 'GENERATE SCHOOL CODE & CREATE',
                              isLoading: controller.isCreating.value,
                              icon: Icons.auto_awesome,
                              iconRight: true,
                              fontSize: 14,
                              onPressed: () => controller.createSchool(),
                            ).animate(delay: 600.ms).fade().slideY(begin: 0.2),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                'A unique 6-character access code will be generated automatically',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ).animate(delay: 700.ms).fade(),
                          ],
                        );
                      }),
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

  Widget _buildLimitField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00A1FF), size: 14),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              hintText: '0',
              hintStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white24,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
