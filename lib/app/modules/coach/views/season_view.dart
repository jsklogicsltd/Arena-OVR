import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/fire_sparks_background.dart';

class SeasonView extends StatefulWidget {
  const SeasonView({super.key});

  @override
  State<SeasonView> createState() => _SeasonViewState();
}

class _SeasonViewState extends State<SeasonView> with TickerProviderStateMixin {
  late final CoachController controller;

  // Animation controllers
  late AnimationController _progressCtrl;
  late AnimationController _statsCtrl;

  late Animation<double> _progressAnim;
  late Animation<double> _ratingsAnim;
  late Animation<double> _ovrAnim;
  late Animation<double> _athletesAnim;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CoachController>();

    _progressCtrl = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this);
    _statsCtrl    = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this);

    // Compute real values for animation targets
    final progress = _computeProgress();
    final avgOvr   = _computeAvgOvr();
    final athletes = controller.roster.length.toDouble();
    // Ratings given – use real count from current team doc if available
    final ratingsGiven =
        (controller.currentTeam.value?.totalRatingsThisSeason ?? 0).toDouble();

    _progressAnim = Tween<double>(begin: 0, end: progress)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));

    _ratingsAnim  = Tween<double>(begin: 0, end: ratingsGiven)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut));

    _ovrAnim      = Tween<double>(begin: 0, end: avgOvr)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut));

    _athletesAnim = Tween<double>(begin: 0, end: athletes)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut));

    // Start animations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _statsCtrl.forward();
      });
    });

    // If season data arrives a moment later from Firebase,
    // recompute percentages so we don't stay on a fallback value.
    ever(controller.season, (_) {
      if (!mounted) return;
      _progressCtrl.reset();
      _statsCtrl.reset();

      final newProgress = _computeProgress();
      final newAvgOvr = _computeAvgOvr();
      final newAthletes = controller.roster.length.toDouble();
      final newRatingsGiven =
          (controller.currentTeam.value?.totalRatingsThisSeason ?? 0).toDouble();

      _progressAnim = Tween<double>(begin: 0, end: newProgress).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
      );
      _ratingsAnim = Tween<double>(begin: 0, end: newRatingsGiven).animate(
        CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut),
      );
      _ovrAnim = Tween<double>(begin: 0, end: newAvgOvr).animate(
        CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut),
      );
      _athletesAnim = Tween<double>(begin: 0, end: newAthletes).animate(
        CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut),
      );

      _progressCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _statsCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  double _computeProgress() {
    // Match the Coach Dashboard logic:
    // Day 1 should start at 0%; Day 15 reaches 100%.
    final s = controller.season.value;
    if (s == null || s.startDate == null) return 0.0;

    final totalDays = _totalDays().toDouble();
    if (totalDays <= 0) return 0.0;

    final dayOfSeason = _dayOfSeason().toDouble();
    final denom = (totalDays - 1).clamp(1.0, double.infinity);
    return ((dayOfSeason - 1) / denom).clamp(0.0, 1.0);
  }

  double _computeAvgOvr() {
    if (controller.roster.isEmpty) return 0;
    final total = controller.roster.fold<int>(0, (sum, a) => sum + a.coachVisibleOvr);
    return total / controller.roster.length;
  }

  int _dayOfSeason() {
    final s = controller.season.value;
    // Same default as Coach Dashboard when startDate is missing.
    if (s?.startDate == null) return 1;
    return max(1, DateTime.now().difference(s!.startDate!).inDays + 1);
  }

  int _totalDays() {
    final s = controller.season.value;
    if (s?.startDate == null || s?.endDate == null) return 15;
    // Inclusive day count: end-start(14) means 15 season days.
    return max(1, s!.endDate!.difference(s.startDate!).inDays + 1);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '–';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // const FireSparksBackground(),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // APP BAR
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      Text(
                        'SEASON HQ',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerRight,
                      ),
                    ],
                  ),
                ).animate().fade().slideY(begin: -0.1),

                // ── 1. Current Season Card ─────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Season title + badges
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() => Text(
                                    controller.season.value?.seasonNumber != null
                                        ? 'SEASON ${controller.season.value!.seasonNumber}'
                                        : 'SEASON –',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.tierGold,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0,
                                    ),
                                  )),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildBadge('ACTIVE', const Color(0xFF10B981), showDot: true),
                                      const SizedBox(width: 8),
                                      _buildBadge('REVEALED', const Color(0xFF0284C7)),
                                    ],
                                  ),
                                ],
                              ),

                              // Animated Progress Circle
                              AnimatedBuilder(
                                animation: _progressAnim,
                                builder: (context, _) {
                                  final pct = _progressAnim.value;
                                  return SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 76,
                                          height: 76,
                                          child: CircularProgressIndicator(
                                            value: pct,
                                            strokeWidth: 6,
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        // Subtle glow ring
                                        Container(
                                          width: 76,
                                          height: 76,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0EA5E9).withOpacity(0.3),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${(pct * 100).toInt()}%',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Timeline rows with real dates
                          Obx(() {
                            final s = controller.season.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimelineRow(
                                  Icons.calendar_today,
                                  'Started: ${_formatDate(s?.startDate)}',
                                ),
                                const SizedBox(height: 8),
                                _buildTimelineRow(
                                  Icons.access_time,
                                  'Day ${_dayOfSeason()} of ${_totalDays()}',
                                ),
                              ],
                            );
                          }),

                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withOpacity(0.1), height: 1),
                          const SizedBox(height: 24),

                          // Stats Row – animated count-up
                          AnimatedBuilder(
                            animation: _statsCtrl,
                            builder: (context, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    _ratingsAnim.value.toInt().toString(),
                                    'RATINGS GIVEN',
                                  ),
                                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                                  _buildStatItem(
                                    _ovrAnim.value.toStringAsFixed(1),
                                    'AVG OVR',
                                  ),
                                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                                  _buildStatItem(
                                    _athletesAnim.value.toInt().toString(),
                                    'ATHLETES',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade().slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── 2. Reset Season Danger Button ─────────────────────────
                _buildResetButton(context).animate(delay: 100.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'All player ratings will reset to 0. A new 3-day reveal period begins.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ).animate(delay: 150.ms).fade(),

                const SizedBox(height: 48),

                // ── 3. History Section ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HISTORY',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0),
                    ),
                    Text(
                      'ARCHIVE',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                  ],
                ).animate(delay: 200.ms).fade(),
                const SizedBox(height: 16),

                _buildHistoryCard(
                  title: 'Season 1',
                  dateRange: 'Oct 1 – Nov 12, 2025',
                  topPlayer: 'Top Player: Marcus Johnson (94)',
                  iconText: 'S1',
                  iconData: Icons.history,
                  isLocked: false,
                ).animate(delay: 250.ms).fade().slideY(begin: 0.1),

                const SizedBox(height: 12),

                _buildHistoryCard(
                  title: 'Pre-Season Beta',
                  dateRange: 'Aug 15 – Sept 30, 2025',
                  topPlayer: null,
                  iconText: 'S0',
                  iconData: Icons.lock_outline,
                  isLocked: true,
                ).animate(delay: 300.ms).fade().slideY(begin: 0.1),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── helper widgets ─────────────────────────────────────────────────────────

  Widget _buildBadge(String text, Color color, {bool showDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(text, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showResetConfirmation(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'RESET SEASON',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFEF4444), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String dateRange,
    String? topPlayer,
    required String iconText,
    required IconData iconData,
    required bool isLocked,
  }) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 10, left: 10,
                        child: Text(iconText,
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        bottom: 10, right: 10,
                        child: Icon(iconData, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(dateRange,
                          style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      if (topPlayer != null) ...[
                        const SizedBox(height: 4),
                        Text(topPlayer,
                            style: GoogleFonts.inter(
                                color: const Color(0xFF0EA5E9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    bool isConfirming = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0000),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 48)
                      .animate()
                      .shake(hz: 8),
                  const SizedBox(height: 16),
                  Text('RESET SEASON?',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                  const SizedBox(height: 12),
                  Text(
                    'This action is irreversible. All current athlete OVRs will be archived and reset to their baseline. A new season will begin immediately.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (isConfirming)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text('CANCEL',
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setModalState(() => isConfirming = true);
                              try {
                                await controller.resetSeason();
                                Navigator.pop(context);
                                Get.back();
                                Get.snackbar('Season Reset', 'A new season has begun.',
                                    backgroundColor: AppColors.tierGold,
                                    colorText: Colors.black);
                              } catch (e) {
                                setModalState(() => isConfirming = false);
                                Get.snackbar('Error', 'Failed to reset season: $e');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFFE53935).withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text('CONFIRM RESET',
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
