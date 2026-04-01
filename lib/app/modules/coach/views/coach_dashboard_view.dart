import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../coach_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../routes/app_routes.dart';
import 'announcement_view.dart';

class CoachDashboardView extends GetView<CoachController> {
  const CoachDashboardView({super.key});

  void _showTeamSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Obx(() {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Switch Team', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...controller.coachTeams.map((team) {
                  final isActive = controller.currentTeam.value?.id == team.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      controller.switchTeam(team.id);
                      Navigator.pop(context);
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      backgroundImage: team.logoUrl != null ? CachedNetworkImageProvider(team.logoUrl!) : null,
                      child: team.logoUrl == null ? const Icon(Icons.shield, color: Colors.white54, size: 20) : null,
                    ),
                    title: Text(team.name, style: GoogleFonts.spaceGrotesk(color: isActive ? AppColors.tierGold : Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                    trailing: isActive ? const Icon(Icons.check_circle, color: AppColors.tierGold) : null,
                  );
                }),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.CREATE_TEAM);
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.add, color: AppColors.tierGold),
                  ),
                  title: Text('+ Add New Team', style: GoogleFonts.spaceGrotesk(color: AppColors.tierGold, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: Obx(() {
            final team = controller.currentTeam.value;
            if (team == null) return const Center(child: CircularProgressIndicator(color: AppColors.tierGold));

            return _DashboardBody(
              controller: controller,
              team: team,
              onShowTeamSwitcher: () => _showTeamSwitcher(context),
            );
          }),
        ),
      ),
    );
  }
}

// ── Animated inner body ───────────────────────────────────────────────────────

class _DashboardBody extends StatefulWidget {
  final CoachController controller;
  final dynamic team;
  final VoidCallback onShowTeamSwitcher;
  const _DashboardBody({required this.controller, required this.team, required this.onShowTeamSwitcher});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> with TickerProviderStateMixin {
  late AnimationController _numCtrl;
  late Animation<double> _ovrAnim;
  late Animation<double> _ratingsAnim;
  late Animation<double> _playersAnim;
  late Animation<double> _avgOvrAnim;
  late Animation<double> _perAnim;
  late Animation<double> _tmAnim;
  late Animation<double> _impAnim;
  late Animation<double> _stdAnim;

  CoachController get c => widget.controller;

  Timer? _animDebounce;
  bool _initialForwardScheduled = true;

  void _scheduleNumberAnimation() {
    _animDebounce?.cancel();
    _animDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _numCtrl.reset();
      _numCtrl.forward();
    });
  }

  @override
  void initState() {
    super.initState();
    _numCtrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialForwardScheduled = false;
      _numCtrl.forward();
    });
    // Re-refresh when roster or feed loads/updates from Firebase so numbers are real
    ever(c.roster, (_) {
      if (mounted) {
        _refresh();
        if (!_initialForwardScheduled) _scheduleNumberAnimation();
      }
    });
    ever(c.feed, (_) {
      if (mounted) {
        _refresh();
        if (!_initialForwardScheduled) _scheduleNumberAnimation();
      }
    });
    ever(c.currentTeam, (_) {
      if (mounted) {
        _refresh();
        if (!_initialForwardScheduled) _scheduleNumberAnimation();
      }
    });
  }

  static double _avgCategoryPoints(List<UserModel> roster, String key, [String? altKey]) {
    if (roster.isEmpty) return 0;
    double sum = 0;
    for (final a in roster) {
      final m = a.currentRating;
      final raw = m[key] ?? (altKey != null ? m[altKey] : null);
      if (raw is num) {
        sum += raw.toDouble();
      } else if (raw != null) {
        sum += double.tryParse(raw.toString()) ?? 0;
      }
    }
    return sum / roster.length;
  }

  static bool _hasAnyPoints(UserModel u) {
    if (u.currentRating.isEmpty) return false;
    for (final v in u.currentRating.values) {
      if (v is num) {
        if (v != 0) return true;
      } else {
        final parsed = num.tryParse(v.toString());
        if (parsed != null && parsed != 0) return true;
      }
    }
    return false;
  }

  static List<UserModel> _rosterWithPoints(List<UserModel> roster) {
    return roster.where(_hasAnyPoints).toList();
  }

  void _refresh() {
    final rosterAll = c.roster;
    // For coach dashboard we want TEAM metrics to always reflect the full roster,
    // even if some athletes have 0 points (especially later in the season).
    final roster = rosterAll;
    final isReal = roster.isNotEmpty;

    final double ovrVal;
    final double perVal;
    final double classVal;
    final double progVal;
    final double stdVal;
    if (isReal) {
      ovrVal = roster.map((a) => a.coachVisibleOvr).reduce((a, b) => a + b) / roster.length;
      perVal = _avgCategoryPoints(roster, 'Performance');
      classVal = _avgCategoryPoints(roster, 'Class', 'Classroom');
      progVal = _avgCategoryPoints(roster, 'Program');
      stdVal = _avgCategoryPoints(roster, 'Standard');
    } else {
      // When season just reset and nobody has points yet, keep values at 0
      // instead of using potentially-stale stored team averages.
      ovrVal = 0;
      perVal = 0;
      classVal = 0;
      progVal = 0;
      stdVal = 0;
    }
    final activePl = (isReal ? roster.length : 0).toDouble();
    final double avgOvr = isReal ? ovrVal : 0;
    // Real ratings this week: count RATING feed items from last 7 days
    final now = DateTime.now();
    final ratings = c.feed
        .where((f) =>
            f.type == 'RATING' &&
            f.createdAt != null &&
            now.difference(f.createdAt!).inDays < 7)
        .length
        .toDouble();

    final curve = CurvedAnimation(parent: _numCtrl, curve: Curves.easeOut);
    _ovrAnim      = Tween<double>(begin: 0, end: ovrVal).animate(curve);
    _perAnim      = Tween<double>(begin: 0, end: perVal).animate(curve);
    _tmAnim       = Tween<double>(begin: 0, end: classVal).animate(curve);
    _impAnim      = Tween<double>(begin: 0, end: progVal).animate(curve);
    _stdAnim      = Tween<double>(begin: 0, end: stdVal).animate(curve);
    _ratingsAnim  = Tween<double>(begin: 0, end: ratings).animate(curve);
    _playersAnim  = Tween<double>(begin: 0, end: activePl).animate(curve);
    _avgOvrAnim   = Tween<double>(begin: 0, end: avgOvr).animate(curve);
  }

  @override
  void dispose() {
    _animDebounce?.cancel();
    _numCtrl.dispose();
    super.dispose();
  }

  // Delegate helper methods from original GetView
  Widget _buildStatBar(String label, double animValue, Color color, double max) {
    final pct = max > 0 ? (animValue / max).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(animValue.toInt().toString(), style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // App Bar / Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onShowTeamSwitcher,
                              child: Row(
                                children: [
                                  // Coach profile photo (real-time reactive)
                                  Obx(() {
                                    final url = c.coachPhotoUrl.value;
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primary, AppColors.tierGold],
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF1E293B),
                                          backgroundImage: url.isNotEmpty
                                              ? CachedNetworkImageProvider(url)
                                              : null,
                                          child: url.isEmpty
                                              ? const Icon(Icons.person, color: Colors.white54, size: 22)
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Obx(() => Text(
                                          c.coachName.value,
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                        )),
                                        Text(
                                          team.name.toUpperCase(),
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => c.changeTab(4),
                                child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fade().slideY(begin: -0.2),

                      const SizedBox(height: 32),

                      // Season Overview Card
                      Obx(() {
                        final currentSeason = c.season.value;
                        final seasonNumber = currentSeason?.seasonNumber ?? 1;
                        
                        // Calculate progress
                        int dayOfSeason = 1;
                        int totalDays = 15;
                        int progressPercent = 0;
                        
                        if (currentSeason != null && currentSeason.startDate != null) {
                          final now = DateTime.now();
                          final diff = now.difference(currentSeason.startDate!).inDays;
                          dayOfSeason = diff >= 0 ? diff + 1 : 1;
                          
                          if (currentSeason.endDate != null) {
                             // Inclusive day count: end-start(14) means 15 season days.
                             totalDays = currentSeason.endDate!.difference(currentSeason.startDate!).inDays + 1;
                             if (totalDays <= 0) totalDays = 15; // Fallback
                          }
                          
                          // Day 1 should start at 0%, Day N advances each completed day.
                          final denom = (totalDays - 1).clamp(1, 9999);
                          progressPercent =
                              (((dayOfSeason - 1) / denom) * 100).clamp(0, 100).toInt();
                        }
                        
                        return GestureDetector(
                          onTap: () => Get.toNamed(Routes.SEASON_HQ),
                          child: GlassCard(
                            backgroundColor: const Color(0x99172A36),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            leftBorderColor: AppColors.seasonGold,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SEASON $seasonNumber',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppColors.seasonGold,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Day $dayOfSeason of $totalDays',
                                      style: GoogleFonts.inter(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 3.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$progressPercent%',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                       Get.defaultDialog(
                                         title: 'Reset Season?',
                                         titleStyle: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                                         middleText: 'Are you sure you want to completely reset this season?',
                                         middleTextStyle: GoogleFonts.inter(color: Colors.white70),
                                         backgroundColor: const Color(0xFF0F172A),
                                         buttonColor: const Color(0xFFEF4444),
                                         cancelTextColor: Colors.white,
                                         confirmTextColor: Colors.white,
                                         textConfirm: 'Reset',
                                         textCancel: 'Cancel',
                                         onConfirm: () {
                                           c.resetSeason();
                                           Get.back();
                                         }
                                       );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                                      ),
                                      child: Text(
                                        'RESET',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: const Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: 200.ms).fade().slideY(begin: 0.1));
                      }),

                      const SizedBox(height: 32),

                      // Team card (same layout as former top athlete card)
                      AnimatedBuilder(
                        animation: _numCtrl,
                        builder: (context, _) {
                        final tm = c.currentTeam.value;
                        final String? logoUrl = tm?.logoUrl;
                        final String name = (tm?.name ?? 'MY TEAM').toUpperCase();
                        final int n = c.roster.length;
                        final String subtitle = n > 0
                            ? '$n ATHLETE${n == 1 ? '' : 'S'} • TEAM AVG PTS'
                            : 'NO ATHLETES YET';
                        
                        return Column(
                          children: [
                            GlassCard(
                              backgroundColor: const Color(0x99172A36),
                              borderColor: AppColors.seasonGold.withOpacity(0.3),
                              padding: const EdgeInsets.all(20),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(24),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.seasonGold,
                                                  AppColors.seasonGold.withOpacity(0.2),
                                                  AppColors.seasonGold.withOpacity(0.5),
                                                  AppColors.seasonGold.withOpacity(0.5),
                                                ],
                                                stops: const [0.0, 0.2, 0.5, 1.0],
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  image: logoUrl != null && logoUrl.isNotEmpty
                                                      ? DecorationImage(
                                                          image: CachedNetworkImageProvider(logoUrl),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                  color: const Color(0xFF0F1923),
                                                ),
                                                child: logoUrl == null || logoUrl.isEmpty
                                                    ? const Icon(Icons.sports_football, color: Colors.white54, size: 40)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  subtitle,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white54,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                                  textBaseline: TextBaseline.alphabetic,
                                                  children: [
                                                    Text(
                                                      '${_ovrAnim.value.toInt()}',
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: AppColors.seasonGold,
                                                        fontSize: 48,
                                                        fontWeight: FontWeight.w900,
                                                        height: 1.0,
                                                        shadows: [
                                                          Shadow(
                                                            color: AppColors.seasonGold.withOpacity(0.5),
                                                            blurRadius: 10,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'OVR',
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: AppColors.seasonGold,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Animated Progress Bars
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildStatBar('PER', _perAnim.value, AppColors.primary, 100),
                                          const SizedBox(width: 12),
                                          _buildStatBar('CLA', _tmAnim.value, AppColors.positive, 100),
                                          const SizedBox(width: 12),
                                          _buildStatBar('PRO', _impAnim.value, AppColors.seasonGold, 100),
                                          const SizedBox(width: 12),
                                          _buildStatBar('STD', _stdAnim.value, Colors.grey, 100),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    // Move badge away from avatar/image so it sits below it.
                                    top: -15,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.seasonGold,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.stars, color: Colors.black87, size: 14),
                                          const SizedBox(width: 4),
                                          Text('TEAM', style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade().slideY(begin: 0.1),
                          ],
                        );
                      }),

                      const SizedBox(height: 16),

                      // ── Stats Row: Ratings / Active Players / Avg Overall ──
                      AnimatedBuilder(
                        animation: _numCtrl,
                        builder: (context, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatTile(
                                value: '${_ratingsAnim.value.toInt()}',
                                label: 'RATINGS\nTHIS WEEK',
                                valueColor: AppColors.primary,
                                hasBorder: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatTile(
                                value: '${_playersAnim.value.toInt()}',
                                label: 'ACTIVE\nPLAYERS',
                                valueColor: Colors.white,
                                hasBorder: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatTile(
                                value: '${_avgOvrAnim.value.toInt()}',
                                label: 'AVG\nOVERALL',
                                valueColor: AppColors.seasonGold,
                                hasBorder: true,
                              ),
                            ),
                          ],
                        ).animate(delay: 150.ms).fade().slideY(begin: 0.1);
                      }),

                      const SizedBox(height: 32),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.0,
                        children: [
                          _buildActionCard(
                            title: 'AWARD RATING',
                            svgPath: 'assets/svg/award.svg',
                            color: AppColors.primary,
                            hasBorder: true,
                            onTap: () => c.changeTab(2),
                          ).animate(delay: 300.ms).fade().scale(begin: const Offset(0.9, 0.9)),
                          _buildActionCard(
                            title: 'LEADERBOARD',
                            svgPath:'assets/svg/leader.svg',
                            color: AppColors.tierGold,
                            hasBorder: true,
                            onTap: () => Get.toNamed(Routes.LEADERBOARD),
                          ).animate(delay: 400.ms).fade().scale(begin: const Offset(0.9, 0.9)),
                          _buildActionCard(
                            title: 'ANNOUNCE',
                            svgPath:'assets/svg/annouce.svg',
                            color: Colors.white,
                            hasBorder: false,
                            onTap: () => Get.to(() => const AnnouncementView()),
                          ).animate(delay: 500.ms).fade().scale(begin: const Offset(0.9, 0.9)),
                          _buildActionCard(
                            title: 'CREATE TEAM',
                            svgPath: 'assets/svg/createteam.svg',
                            color: Colors.white,
                            hasBorder: false,
                            onTap: () => Get.toNamed(Routes.CREATE_TEAM),
                          ).animate(delay: 600.ms).fade().scale(begin: const Offset(0.9, 0.9)),
                        ],
                      ),

                      const SizedBox(height: 48),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('RECENT ACTIVITY', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () => c.changeTab(3),
                            child: Text('VIEW ALL', style: GoogleFonts.spaceGrotesk(color: AppColors.tierGold, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ).animate(delay: 700.ms).fade(),
                      
                      const SizedBox(height: 16),

                      // Recent Feed (Real or Mock Data if empty)
                      Builder(builder: (context) {
                        final items = c.feed.isNotEmpty 
                            ? c.feed.take(3).map((f) => _MockActivity(
                                  type: f.type,
                                  title: f.type.toUpperCase() == 'RATING'
                                      ? '${f.actorName} gave ${f.targetDisplayLabel} ${f.ratingPointsDescription}'
                                      : f.content,
                                  timeAgo: _timeAgo(f.createdAt),
                                  actorName: f.actorName,
                                )).toList() 
                            : _getMockFeedItems();

                        return Column(
                          children: items.map((item) {
                            final isPerformance = item.type == 'PERFORMANCE' || item.type == 'POINTS'; // Adjust type as needed
                            final icon = isPerformance ? Icons.star_border : Icons.military_tech;
                            final iconColor = isPerformance ? const Color(0xFF00A1FF) : const Color(0xFFFFD700);


                            final titleWidget = c.feed.isNotEmpty
                                ? Text(
                                    '${item.actorName} - ${item.title}',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w400),
                                  )
                                : _buildMockRichTextTitle(item.title);

                            final timeText = item.timeAgo;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x99172A36), // #172A36 60%
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1), // #FFFFFF 10%
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon Container
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: iconColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon, color: iconColor, size: 24),
                                        ),
                                        const SizedBox(width: 12), // Gap 12px
                                        // Text Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              titleWidget,
                                              const SizedBox(height: 4),
                                              Text(
                                                timeText,
                                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fade().slideX(begin: 0.1);
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 80), // Padding for Bottom Navbar
                    ]),
                  ),
                ),
              ],
            );
  }

  Widget _buildActionCard({
    required String title,
    required String svgPath,
    required Color color,
    required bool hasBorder,
    required VoidCallback onTap,
  }) {
    final isColored = color != Colors.white;
    
    // Figma custom opacities for different colored borders
    double borderOpacity = 0.0;
    if (hasBorder) {
      borderOpacity = (color == AppColors.primary) ? 0.30 : 0.20;
    }

    final card = Container(
      decoration: BoxDecoration(
        color: const Color(0x99172A36), // #172A36 at 60%
        borderRadius: BorderRadius.circular(16),
        border: hasBorder
            ? Border.all(color: color.withOpacity(borderOpacity), width: 1)
            : Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isColored
                    ? color.withOpacity(0.12)
                    : Colors.white.withOpacity(0.08),
                boxShadow: isColored
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isColored ? color : Colors.white70,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: isColored ? color : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: card,
        ),
      ),
    );
  }

  static String _timeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${(diff.inDays / 7).floor()} wk ago';
  }

  List<_MockActivity> _getMockFeedItems() {
    return [
      _MockActivity(
        type: 'PERFORMANCE',
        title: 'You awarded Sarah Chen +3 in Performance',
        timeAgo: '2 min ago',
        actorName: 'You',
      ),
      _MockActivity(
        type: 'BADGE',
        title: "Jake Miller earned 'Rising Star' badge",
        timeAgo: '1 hour ago',
        actorName: 'Jake Miller',
      ),
    ];
  }

  Widget _buildMockRichTextTitle(String title) {
    if (title.contains('Sarah Chen +3')) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.white, fontWeight: FontWeight.w400),
          children: [
            const TextSpan(text: 'You awarded '),
            TextSpan(text: 'Sarah Chen ', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            TextSpan(text: '+3 ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF00A1FF))),
            const TextSpan(text: 'in Performance'),
          ],
        ),
      );
    } else if (title.contains('Rising Star')) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.white, fontWeight: FontWeight.w400),
          children: [
            TextSpan(text: 'Jake Miller ', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const TextSpan(text: 'earned '),
            TextSpan(text: "'Rising Star' ", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFFFD700))),
            const TextSpan(text: 'badge'),
          ],
        ),
      );
    }
    return Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4));
  }

  Widget _buildStatTile({
    required String value,
    required String label,
    required Color valueColor,
    required bool hasBorder,
  }) {
    final borderColor = hasBorder
        ? AppColors.seasonGold.withOpacity(0.2)   
        : Colors.white.withOpacity(0.08);
    final bgColor = hasBorder
        ? const Color(0x99172A36)
        : const Color(0x99172A36);

    final decoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1),
    );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white54,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
      ],
    );

    if (hasBorder) {
      // AVG OVERALL tile: apply background blur (sigma 12) per Figma
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 78,
            constraints: const BoxConstraints(minWidth: 108),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            alignment: Alignment.center,
            decoration: decoration,
            child: content,
          ),
        ),
      );
    }

    return Container(
      height: 78,
      constraints: const BoxConstraints(minWidth: 108),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      decoration: decoration,
      child: content,
    );
  }
}

class _MockActivity {
  final String type;
  final String title;
  final String timeAgo;
  final String actorName;

  _MockActivity({
    required this.type,
    required this.title,
    required this.timeAgo,
    required this.actorName,
  });
}
