import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'leaderboard_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/components/animated_glowing_border.dart';
import '../../core/utils/elite_ovr_style.dart';
import '../../data/models/user_model.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({Key? key}) : super(key: key);

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
                  if (controller.isLoading.value && controller.ranked.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.tierGold,
                      ),
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

  Widget _buildAppBar(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            )
          else
            const SizedBox(width: 44, height: 44),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.tierGold,
                  size: 24,
                ),
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
          border: Border(bottom: BorderSide(color: _tabBarBorder, width: 1)),
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
                            color: isSel
                                ? _tabIndicatorBlue
                                : Colors.transparent,
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
    final elite = EliteOvrStyle.isEliteOvr(u.coachVisibleOvr);
    final size = isFirst ? 100.0 : 80.0;
    final is1 = rank == 1;
    final is2 = rank == 2;
    final borderColor = is1
        ? _rank1Border
        : (is2 ? _rank2Border : _rank3Border);
    final badgeColor = is1 ? _rank1Badge : (is2 ? _rank2Badge : _rank3Badge);
    final badgeTextColor = is1
        ? _badgeTextDark
        : (is2 ? _rank2Text : _rank3Text);
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
            child: Icon(
              Icons.workspace_premium_rounded,
              color: _rank1Border,
              size: 28,
            ),
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
                      border: Border.all(
                        color: borderColor,
                        width: is1 ? 3 : 2.5,
                      ),
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
                      child: EliteOvrStyle.tintedAvatar(
                        isElite: elite,
                        child:
                            u.profilePicUrl != null &&
                                u.profilePicUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: u.profilePicUrl!,
                                fit: BoxFit.cover,
                                width: size,
                                height: size,
                                placeholder: (_, __) =>
                                    _avatarPlaceholder(size, borderColor),
                                errorWidget: (_, __, ___) =>
                                    _avatarPlaceholder(size, borderColor),
                              )
                            : _avatarPlaceholder(size, borderColor),
                      ),
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
                      padding: EdgeInsets.only(
                        right: i < elite.length - 1 ? gap : 0,
                      ),
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
    final elite = EliteOvrStyle.isEliteOvr(u.coachVisibleOvr);
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
        if (elite)
          Container(
            width: cardWidth,
            height: 2,
            decoration: BoxDecoration(
              gradient: EliteOvrStyle.eliteCardGradient,
              borderRadius: BorderRadius.circular(2),
              boxShadow: EliteOvrStyle.eliteGlow(alpha: 0.45),
            ),
          ),
        if (elite) const SizedBox(height: 6),
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
                        child: EliteOvrStyle.tintedAvatar(
                          isElite: elite,
                          child:
                              u.profilePicUrl != null &&
                                  u.profilePicUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: u.profilePicUrl!,
                                  fit: BoxFit.cover,
                                  width: circleSize,
                                  height: circleSize,
                                  placeholder: (_, __) => _avatarPlaceholder(
                                    circleSize,
                                    borderColor,
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      _avatarPlaceholder(
                                        circleSize,
                                        borderColor,
                                      ),
                                )
                              : _avatarPlaceholder(circleSize, borderColor),
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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

  // ── Category leader cards data ──────────────────────────────────────────
  static const _catCardBg = Color(0xCC141428);

  Widget _buildCategoryLeaders() {
    if (controller.ranked.isEmpty) return const SizedBox.shrink();

    // Define all 7 entries; order: 4 subjective → 3 objective
    final entries = <_CatLeaderEntry>[
      _CatLeaderEntry(
        title: 'COMPETITOR',
        icon: Icons.fitness_center_rounded,
        accent: const Color(0xFF5B8AF5),
        leader: controller.categoryLeader('Athlete'),
        displayValue: '${controller.categoryLeaderPoints('Athlete').round()}',
        suffix: 'PTS',
      ),
      _CatLeaderEntry(
        title: 'STUDENT',
        icon: Icons.school_rounded,
        accent: const Color(0xFF34D399),
        leader: controller.categoryLeader('Student'),
        displayValue: '${controller.categoryLeaderPoints('Student').round()}',
        suffix: 'PTS',
      ),
      _CatLeaderEntry(
        title: 'TEAMMATE',
        icon: Icons.handshake_rounded,
        accent: const Color(0xFF9D84F5),
        leader: controller.categoryLeader('Teammate'),
        displayValue: '${controller.categoryLeaderPoints('Teammate').round()}',
        suffix: 'PTS',
      ),
      _CatLeaderEntry(
        title: 'CITIZEN',
        icon: Icons.shield_rounded,
        accent: const Color(0xFFE4AA4E),
        leader: controller.categoryLeader('Citizen'),
        displayValue: '${controller.categoryLeaderPoints('Citizen').round()}',
        suffix: 'PTS',
      ),
      _CatLeaderEntry(
        title: 'POWER',
        icon: Icons.bolt_rounded,
        accent: const Color(0xFFE07272),
        leader: controller.objectiveLeader('powerNumber'),
        displayValue:
            '${controller.objectiveLeaderValue('powerNumber').round()}',
        suffix: 'PWR',
      ),
      _CatLeaderEntry(
        title: 'SPEED',
        icon: Icons.speed_rounded,
        accent: const Color(0xFF38BDF8),
        leader: controller.objectiveLeader('speedNumber'),
        displayValue:
            '${controller.objectiveLeaderValue('speedNumber').round()}',
        suffix: 'SPD',
      ),
      _CatLeaderEntry(
        title: 'GPA',
        icon: Icons.auto_stories_rounded,
        accent: const Color(0xFF6EE7B7),
        leader: controller.objectiveLeader('gpa'),
        displayValue: controller.objectiveLeaderValue('gpa') > 0
            ? controller.objectiveLeaderValue('gpa').toStringAsFixed(2)
            : '--',
        suffix: 'GPA',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardW = 110.0;
        const gap = 10.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9EFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CATEGORY LEADERS',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 162,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(
                    right: i < entries.length - 1 ? gap : 0,
                  ),
                  child: SizedBox(
                    width: cardW,
                    child: _buildCategoryCard(entries[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(_CatLeaderEntry e) {
    final leader = e.leader;
    final isElite =
        leader != null && EliteOvrStyle.isEliteOvr(leader.coachVisibleOvr);
    const eliteReadable = Color(0xFF0B1A2A);
    final hasLeader = leader != null;
    const avatarSize = 40.0;

    return Container(
      decoration: BoxDecoration(
        color: isElite ? null : _catCardBg,
        gradient: isElite ? EliteOvrStyle.eliteCardGradient : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isElite
              ? const Color(0xFFFFE08A)
              : e.accent.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: isElite
            ? EliteOvrStyle.eliteGlow(alpha: 0.3)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Subtle top accent stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      e.accent.withValues(alpha: 0.9),
                      e.accent.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon badge + category label
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isElite
                              ? eliteReadable.withValues(alpha: 0.12)
                              : e.accent.withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          e.icon,
                          color: isElite ? eliteReadable : e.accent,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          e.title,
                          style: GoogleFonts.spaceGrotesk(
                            color: isElite ? eliteReadable : e.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Avatar
                  SizedBox(
                    width: avatarSize + 4,
                    height: avatarSize + 12,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedGlowingBorder(
                          diameter: avatarSize + 4,
                          borderWidth: 2.5,
                          duration: const Duration(seconds: 4),
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isElite
                                    ? const Color(0xFFFFD700)
                                    : e.accent.withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: hasLeader
                                  ? EliteOvrStyle.tintedAvatar(
                                      isElite: isElite,
                                      child: leader.profilePicUrl != null &&
                                              leader.profilePicUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: leader.profilePicUrl!,
                                              fit: BoxFit.cover,
                                              width: avatarSize,
                                              height: avatarSize,
                                              placeholder: (_, __) =>
                                                  _catAvatarPlaceholder(
                                                    avatarSize,
                                                    e.accent,
                                                  ),
                                              errorWidget: (_, __, ___) =>
                                                  _catAvatarPlaceholder(
                                                    avatarSize,
                                                    e.accent,
                                                  ),
                                            )
                                          : _catAvatarPlaceholder(
                                              avatarSize,
                                              e.accent,
                                            ),
                                    )
                                  : _catAvatarPlaceholder(avatarSize, e.accent),
                            ),
                          ),
                        ),
                        // Gold crown overlay for elite or just leader
                        if (hasLeader)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isElite
                                      ? const Color(0xFFFFD700)
                                      : e.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#1',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFF0D0D1A),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    hasLeader ? _shortName(leader.name) : '--',
                    style: GoogleFonts.spaceGrotesk(
                      color: isElite ? eliteReadable : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        e.displayValue,
                        style: GoogleFonts.spaceGrotesk(
                          color: isElite ? eliteReadable : e.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        e.suffix,
                        style: GoogleFonts.spaceGrotesk(
                          color: (isElite
                                  ? eliteReadable
                                  : e.accent)
                              .withValues(alpha: 0.55),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catAvatarPlaceholder(double size, Color accent) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      child: Icon(Icons.person_rounded, size: size * 0.5, color: accent.withValues(alpha: 0.5)),
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
    final elite = EliteOvrStyle.isEliteOvr(u.coachVisibleOvr);
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
        color: elite ? null : _rosterFill,
        gradient: elite ? EliteOvrStyle.eliteCardGradient : null,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: elite ? const Color(0xFFFFE08A) : _rosterBorder,
          width: 1,
        ),
        boxShadow: elite ? EliteOvrStyle.eliteGlow(alpha: 0.35) : null,
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
                  border: Border.all(
                    color: AppColors.tierSilver.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: EliteOvrStyle.tintedAvatar(
                    isElite: elite,
                    child:
                        u.profilePicUrl != null && u.profilePicUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: u.profilePicUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _avatarPlaceholder(40, AppColors.tierSilver),
                            errorWidget: (_, __, ___) =>
                                _avatarPlaceholder(40, AppColors.tierSilver),
                          )
                        : _avatarPlaceholder(40, AppColors.tierSilver),
                  ),
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
                  color: elite ? const Color(0xFF2E1E00) : Colors.white,
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

// ── Category leader card data holder ────────────────────────────────────────
class _CatLeaderEntry {
  final String title;
  final IconData icon;
  final Color accent;
  final UserModel? leader;
  final String displayValue;
  final String suffix;

  const _CatLeaderEntry({
    required this.title,
    required this.icon,
    required this.accent,
    required this.leader,
    required this.displayValue,
    required this.suffix,
  });
}
