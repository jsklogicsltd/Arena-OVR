import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'leaderboard_controller.dart';
import '../player/player_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/fire_sparks_background.dart';
import '../../core/components/animated_glowing_border.dart';
import '../../data/models/user_model.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({Key? key}) : super(key: key);

  PlayerController? _tryPlayerController() {
    if (!Get.isRegistered<PlayerController>()) return null;
    try {
      return Get.find<PlayerController>();
    } catch (_) {
      return null;
    }
  }

  double _uiScale(BuildContext context) {
    // Base width = 390 (typical small phone). Clamp keeps UI readable.
    final w = MediaQuery.sizeOf(context).width;
    return (w / 390).clamp(0.85, 1.0);
  }

  double _s(BuildContext context, double value) => value * _uiScale(context);

  @override
  Widget build(BuildContext context) {
    return StadiumBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // const FireSparksBackground(),
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Obx(() {
              final pc = _tryPlayerController();
              if (pc != null && pc.athlete.value?.role == 'athlete') {
                // Rebuild when season / profile loads (same as athlete dashboard OVR gate).
                pc.athlete.value;
                pc.season.value;
                if (!pc.isOvrTimingReady) {
                  return _buildAthleteLeaderboardGate(loading: true, pc: pc);
                }
                if (!pc.isOvrRevealed) {
                  return _buildAthleteLeaderboardGate(loading: false, pc: pc);
                }
              }
              if (controller.isLoading.value && controller.ranked.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.tierGold),
                );
              }
                  return _buildBody(context);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Before OVR is revealed (Day 1 / syncing): no tabs, no ranks, no faces, no OVR — matches athlete policy.
  Widget _buildAthleteLeaderboardGate({required bool loading, required PlayerController pc}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.tierGold,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'SYNCING LEADERBOARD…',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ] else ...[
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textSecondary,
                size: 52,
              ),
              const SizedBox(height: 20),
              Text(
                'LEADERBOARD LOCKED',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pc.capStatusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pc.phaseName,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.seasonGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rankings and OVR unlock when your season OVR is revealed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded, color: AppColors.tierGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'LEADERBOARD',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPodium(),
                const SizedBox(height: 24),
                _buildEliteSection(),
                const SizedBox(height: 24),
                _buildCategoryLeaders(),
                const SizedBox(height: 24),
                _buildRosterSection(),
                const SizedBox(height: 20),
                _buildTeamStatsBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma: container height 53px, fill #181834 70%, bottom border 1px #222249, blur 4
  static const Color _tabBarBg = Color(0xB2181834);
  static const Color _tabBarBorder = Color(0xFF222249);
  static const Color _tabSelected = Color(0xFFFFFFFF);
  static const Color _tabUnselected = Color(0xFF8B8BA8);
  static const Color _tabIndicatorBlue = Color(0xFF00A3FF);

  Widget _buildTabs() {
    const labels = ['TODAY', 'THIS WEEK', 'SEASON OVR'];
    return Obx(() {
      final sel = controller.selectedTimeframe.value;
      return Container(
        height: 53,
        decoration: BoxDecoration(
          color: _tabBarBg,
          border: Border(
            bottom: BorderSide(color: _tabBarBorder, width: 1),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Row(
              children: List.generate(3, (i) {
                final isSel = sel == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setTimeframe(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          labels[i],
                          style: GoogleFonts.spaceGrotesk(
                            color: isSel ? _tabSelected : _tabUnselected,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSel ? 80 : 0,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSel ? _tabIndicatorBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPodium() {
    return Obx(() {
      final p = controller.podium;
      if (p.isEmpty) return const SizedBox.shrink();
      final first = p[0];
      final second = p.length > 1 ? p[1] : null;
      final third = p.length > 2 ? p[2] : null;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null) _buildPodiumSpot(second, 2, isFirst: false),
          if (second != null) const SizedBox(width: 8),
          _buildPodiumSpot(first, 1, isFirst: true),
          if (third != null) const SizedBox(width: 8),
          if (third != null) _buildPodiumSpot(third, 3, isFirst: false),
        ],
      );
    });
  }

  // Top 3 rank colors per design: 1st yellow, 2nd grey, 3rd orange
  static const Color _rank1Border = Color(0xFFFFD700);
  static const Color _rank1Badge = Color(0xFFFFD700);
  static const Color _rank2Border = Color(0xFF9E9E9E);
  static const Color _rank2Badge = Color(0xFFBDBDBD);
  static const Color _rank2Text = Color(0xFF424242);
  static const Color _rank3Border = Color(0xFFFF9800);
  static const Color _rank3Badge = Color(0xFFFF9800);
  static const Color _rank3Text = Color(0xFF424242);
  static const Color _badgeTextDark = Color(0xFF1A1A1A);

  Widget _buildPodiumSpot(UserModel u, int rank, {required bool isFirst}) {
    final size = isFirst ? 100.0 : 80.0;
    final is1 = rank == 1;
    final is2 = rank == 2;
    final is3 = rank == 3;
    final borderColor = is1 ? _rank1Border : (is2 ? _rank2Border : _rank3Border);
    final badgeColor = is1 ? _rank1Badge : (is2 ? _rank2Badge : _rank3Badge);
    final badgeTextColor = is1 ? _badgeTextDark : (is2 ? _rank2Text : _rank3Text);
    final ovrColor = is1 ? _rank1Border : (is2 ? Colors.white : _rank3Border);

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: is1 ? 10 : 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: is1
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        rank == 2 ? '2ND' : (rank == 3 ? '3RD' : '1ST'),
        style: GoogleFonts.spaceGrotesk(
          color: badgeTextColor,
          fontSize: is1 ? 11 : 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (is1) ...[
          Transform.translate(
            offset: const Offset(0, 6),
            child: Icon(Icons.workspace_premium_rounded, color: _rank1Border, size: 28),
          ),
        ],
        SizedBox(
          width: size,
          height: size + 14,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedGlowingBorder(
                diameter: size + 6,
                borderWidth: 3,
                duration: const Duration(seconds: 4),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: is1 ? 3 : 2.5),
                      boxShadow: is1
                          ? [
                              BoxShadow(
                                color: _rank1Border.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: u.profilePicUrl != null && u.profilePicUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: u.profilePicUrl!,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                              placeholder: (_, __) => _avatarPlaceholder(size, borderColor),
                              errorWidget: (_, __, ___) => _avatarPlaceholder(size, borderColor),
                            )
                          : _avatarPlaceholder(size, borderColor),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 2,
                child: Center(child: badge),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: isFirst ? 100 : 72,
          child: Text(
            _shortName(u.name),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: isFirst ? 14 : 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${u.coachVisibleOvr} OVR',
          style: GoogleFonts.spaceGrotesk(
            color: ovrColor,
            fontSize: isFirst ? 16 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(double size, Color color) {
    return Container(
      color: Colors.white12,
      child: Icon(Icons.person_rounded, size: size * 0.5, color: color),
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}. ${parts.last}';
    return name;
  }

  Widget _buildEliteSection() {
    return Obx(() {
      final elite = controller.elite;
      if (elite.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ELITE 4-20',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              const padding = 10.0;
              final totalWidth = constraints.maxWidth;
              final cardWidth = (totalWidth - padding * 1 - gap * 2) / 4;
              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: elite.length,
                  itemBuilder: (context, i) {
                    final u = elite[i];
                    final rank = 4 + i;
                    return Padding(
                      padding: EdgeInsets.only(right: i < elite.length - 1 ? gap : 0),
                      child: SizedBox(
                        width: cardWidth,
                        child: _buildEliteCard(u, rank, cardWidth: cardWidth),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      );
    });
  }

  // Elite 4-20: alternating grey (4,6,8...) and orange (5,7,9...) per design
  static const Color _eliteGreyBorder = Color(0xFFBDBDBD);
  static const Color _eliteGreyBadge = Color(0xFFBDBDBD);
  static const Color _eliteOrangeBorder = Color(0xFFFF9800);
  static const Color _eliteOrangeBadge = Color(0xFFFF9800);

  Widget _buildEliteCard(UserModel u, int rank, {required double cardWidth}) {
    final isOrange = (rank - 4) % 2 == 1;
    final borderColor = isOrange ? _eliteOrangeBorder : _eliteGreyBorder;
    final badgeColor = isOrange ? _eliteOrangeBadge : _eliteGreyBadge;
    final badgeTextColor = _badgeTextDark;
    final ovrColor = isOrange ? const Color(0xFFFFB74D) : Colors.white;

    // Derive circle size from card width so it never overflows and stays circular
    final circleSize = (cardWidth - 10).clamp(48.0, 76.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: circleSize + 4,
          height: circleSize + 14,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedGlowingBorder(
                diameter: circleSize + 6,
                borderWidth: 3,
                duration: const Duration(seconds: 4),
                child: SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2.5),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: u.profilePicUrl != null && u.profilePicUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: u.profilePicUrl!,
                                fit: BoxFit.cover,
                                width: circleSize,
                                height: circleSize,
                                placeholder: (_, __) => _avatarPlaceholder(circleSize, borderColor),
                                errorWidget: (_, __, ___) => _avatarPlaceholder(circleSize, borderColor),
                              )
                            : _avatarPlaceholder(circleSize, borderColor),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${rank}TH',
                      style: GoogleFonts.spaceGrotesk(
                        color: badgeTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _shortName(u.name),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${u.coachVisibleOvr} OVR',
          style: GoogleFonts.spaceGrotesk(
            color: ovrColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // Category Leaders: Athlete, Student, Teammate, Citizen
  static const Color _athBg = Color(0x4D1E3A8A);
  static const Color _athBorder = Color(0x4D3B82F6);
  static const Color _athAccent = Color(0xFF93C5FD);
  static const Color _stuBg = Color(0x4D14532D);
  static const Color _stuBorder = Color(0x4D22C55E);
  static const Color _stuAccent = Color(0xFF4ADE80);
  static const Color _tmBg = Color(0x4D4C1D95);
  static const Color _tmBorder = Color(0x4D7C3AED);
  static const Color _tmAccent = Color(0xFFA78BFA);
  static const Color _citBg = Color(0x4D78350F);
  static const Color _citBorder = Color(0x4DD97706);
  static const Color _citAccent = Color(0xFFFB923C);

  Widget _buildCategoryLeaders() {
    if (controller.ranked.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY LEADERS',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                title: 'ATHLETE',
                icon: Icons.fitness_center_rounded,
                backgroundColor: _athBg,
                borderColor: _athBorder,
                accentColor: _athAccent,
                leaderName: controller.categoryLeader('Athlete') != null
                    ? _shortName(controller.categoryLeader('Athlete')!.name)
                    : '--',
                points: controller.categoryLeaderPoints('Athlete').round(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryCard(
                title: 'STUDENT',
                icon: Icons.school_rounded,
                backgroundColor: _stuBg,
                borderColor: _stuBorder,
                accentColor: _stuAccent,
                leaderName: controller.categoryLeader('Student') != null
                    ? _shortName(controller.categoryLeader('Student')!.name)
                    : '--',
                points: controller.categoryLeaderPoints('Student').round(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                title: 'TEAMMATE',
                icon: Icons.handshake_rounded,
                backgroundColor: _tmBg,
                borderColor: _tmBorder,
                accentColor: _tmAccent,
                leaderName: controller.categoryLeader('Teammate') != null
                    ? _shortName(controller.categoryLeader('Teammate')!.name)
                    : '--',
                points: controller.categoryLeaderPoints('Teammate').round(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryCard(
                title: 'CITIZEN',
                icon: Icons.shield_rounded,
                backgroundColor: _citBg,
                borderColor: _citBorder,
                accentColor: _citAccent,
                leaderName: controller.categoryLeader('Citizen') != null
                    ? _shortName(controller.categoryLeader('Citizen')!.name)
                    : '--',
                points: controller.categoryLeaderPoints('Citizen').round(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color accentColor,
    required String leaderName,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tierGold.withValues(alpha: 0.35),
                  border: Border.all(color: AppColors.tierGold, width: 1),
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.tierGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaderName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$points PTS',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection() {
    return Obx(() {
      final roster = controller.roster;
      if (roster.isEmpty) return const SizedBox.shrink();
      final start = controller.ranked.length - roster.length + 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROSTER ($start-${controller.ranked.length})',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...roster.asMap().entries.map((e) {
            final u = e.value;
            final rank = start + e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRosterRow(u, rank),
            );
          }),
        ],
      );
    });
  }

  // Roster row Figma: radius 48px, padding 12px, gap 12px, fill #181834 50%, border #222249
  static const Color _rosterFill = Color(0x80181834);
  static const Color _rosterBorder = Color(0xFF222249);

  Widget _buildRosterRow(UserModel u, int rank) {
    final prev = u.previousRank;
    int? move;
    if (prev != null) {
      if (prev < rank) {
        move = rank - prev;
      } else if (prev > rank) {
        move = -(prev - rank);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _rosterFill,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: _rosterBorder, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedGlowingBorder(
            diameter: 46,
            borderWidth: 3,
            duration: const Duration(seconds: 4),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tierSilver.withValues(alpha: 0.5), width: 1),
                ),
                child: ClipOval(
                  child: u.profilePicUrl != null && u.profilePicUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: u.profilePicUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarPlaceholder(40, AppColors.tierSilver),
                          errorWidget: (_, __, ___) => _avatarPlaceholder(40, AppColors.tierSilver),
                        )
                      : _avatarPlaceholder(40, AppColors.tierSilver),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (u.positionGroup != null && u.positionGroup!.isNotEmpty)
                  Text(
                    u.positionGroup!,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${u.coachVisibleOvr} OVR',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (move != null)
                Text(
                  move > 0 ? '↓$move' : '↑${-move}',
                  style: GoogleFonts.spaceGrotesk(
                    color: move > 0 ? AppColors.negative : AppColors.positive,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '--',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Team stats bar Figma: height 54, top+bottom border 1px #222249, fill #181834 95%, blur 12
  static const Color _statsBarFill = Color(0xF2181834);
  static const Color _statsBarBorder = Color(0xFF222249);
  static const Color _statsLabel = Color(0xFFB8B8D0);
  static const Color _statsTotalBlue = Color(0xFF00A3FF);

  Widget _buildTeamStatsBar() {
    return Obx(() {
      if (controller.ranked.isEmpty) return const SizedBox.shrink();
      final avg = controller.teamAvgOvr;
      final count = controller.ranked.length;
      final total = controller.totalPoints;
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: _statsBarFill,
          border: const Border(
            top: BorderSide(color: _statsBarBorder, width: 1),
            bottom: BorderSide(color: _statsBarBorder, width: 1),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TEAM AVG',
                        style: GoogleFonts.spaceGrotesk(
                          color: _statsLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$avg OVR',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFF4A4A6A)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ROSTER',
                        style: GoogleFonts.spaceGrotesk(
                          color: _statsLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count ATHLETES',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFF4A4A6A)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.spaceGrotesk(
                          color: _statsLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total PTS',
                        style: GoogleFonts.spaceGrotesk(
                          color: _statsTotalBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
