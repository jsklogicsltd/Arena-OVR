import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../player_controller.dart';
import '../../notifications/notifications_controller.dart';
import '../../feed/feed_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/feed_model.dart';
import '../../../data/models/user_model.dart';

class AthleteDashboardView extends StatelessWidget {
  const AthleteDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PlayerController>();
    return StadiumBackground(
      child: Obx(() {
        if (c.isLoading.value && c.athlete.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.tierGold),
          );
        }
        final athlete = c.athlete.value;
        if (athlete == null) return const SizedBox.shrink();
        return _DashboardBody(c: c, athlete: athlete);
      }),
    );
  }
}

// ── Animated Body ─────────────────────────────────────────────────────────────

class _DashboardBody extends StatefulWidget {
  final PlayerController c;
  final UserModel athlete;
  const _DashboardBody({required this.c, required this.athlete});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with TickerProviderStateMixin {
  late AnimationController _barsCtrl;
  late AnimationController _streakCtrl;
  late Animation<double> _perfAnim, _classAnim, _progAnim, _stdAnim;

  PlayerController get c => widget.c;

  @override
  void initState() {
    super.initState();
    _barsCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _streakCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _setupBarAnims(widget.athlete);
    WidgetsBinding.instance.addPostFrameCallback((_) => _barsCtrl.forward());
  }

  void _setupBarAnims(UserModel a) {
    const maxScore = 100.0;
    final r    = a.currentRating;
    final perf = ((r['Performance'] ?? 0) as num).toDouble();
    final cls  = ((r['Class']       ?? 0) as num).toDouble();
    final prog = ((r['Program']     ?? 0) as num).toDouble();
    final std  = ((r['Standard']    ?? 0) as num).toDouble();

    _perfAnim  = Tween<double>(begin: 0, end: (perf / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.00, 0.75, curve: Curves.easeOut)));
    _classAnim = Tween<double>(begin: 0, end: (cls  / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.12, 0.82, curve: Curves.easeOut)));
    _progAnim  = Tween<double>(begin: 0, end: (prog / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.24, 0.90, curve: Curves.easeOut)));
    _stdAnim   = Tween<double>(begin: 0, end: (std  / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.36, 1.00, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _barsCtrl.dispose();
    _streakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final athlete = widget.athlete;
    final r       = athlete.currentRating;
    final perf    = ((r['Performance'] ?? 0) as num).toInt();
    final cls     = ((r['Class']       ?? 0) as num).toInt();
    final prog    = ((r['Program']     ?? 0) as num).toInt();
    final std     = ((r['Standard']    ?? 0) as num).toInt();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Header ──────────────────────────────────────────────────────
              _buildHeader(athlete),
              const SizedBox(height: 24),

              // ── OVR Hero Card ────────────────────────────────────────────────
              Obx(
                () => _buildOvrHeroCard(c.athlete.value ?? athlete)
                    .animate()
                    .fade(duration: 450.ms)
                    .slideY(begin: 0.15, duration: 450.ms, curve: Curves.easeOut),
              ),
              const SizedBox(height: 16),

              // ── Latest Feed Card ───────────────────────────────────────────
              _buildLatestFeedCard()
                  .animate(delay: 120.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.1, duration: 400.ms),
              const SizedBox(height: 16),

              // ── Streaks Card ─────────────────────────────────────────────────
              _buildStreakCard()
                  .animate(delay: 100.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.1, duration: 400.ms),
              const SizedBox(height: 14),

              // ── Team OVR Card ──────────────────────────────────────────────
              _buildTeamOvrCard()
                  .animate(delay: 120.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.1, duration: 400.ms),

              const SizedBox(height: 20),

              // ── Category Breakdown ───────────────────────────────────────────
              Text(
                'CATEGORY BREAKDOWN',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 200.ms).fade(),
              const SizedBox(height: 14),

              AnimatedBuilder(
                animation: _barsCtrl,
                builder: (_, __) => _buildCategoryBars(
                  perf, cls, prog, std,
                  _perfAnim.value, _classAnim.value, _progAnim.value, _stdAnim.value,
                ),
              ).animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 28),

              // ── Achievements ─────────────────────────────────────────────────
              Text(
                'ACHIEVEMENTS',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 350.ms).fade(),
              const SizedBox(height: 10),

              _buildAchievements(athlete.badges)
                  .animate(delay: 350.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 28),

              // ── Recent Ratings ───────────────────────────────────────────────
              Text(
                'RECENT RATINGS',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 500.ms).fade(),
              const SizedBox(height: 14),

              Obx(() {
                final items = _recentRatingItems(c);
                return Column(
                  children: items.asMap().entries.map((e) =>
                    _buildRecentRatingCard(e.value)
                        .animate(delay: Duration(milliseconds: 550 + e.key * 80))
                        .fade(duration: 400.ms)
                        .slideX(begin: 0.08, duration: 400.ms),
                  ).toList(),
                );
              }),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(UserModel athlete) {
    return Row(
      children: [
        // Avatar with gold ring
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.tierGold, AppColors.tierGold.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF1E293B),
            backgroundImage: athlete.profilePicUrl != null
                ? CachedNetworkImageProvider(athlete.profilePicUrl!)
                : null,
            child: athlete.profilePicUrl == null
                ? Text(
                    athlete.name.isNotEmpty ? athlete.name[0].toUpperCase() : 'A',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                athlete.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '#${athlete.jerseyNumber ?? '0'} • ${athlete.positionGroup ?? 'Athlete'}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 26),
          onPressed: () => c.changeTab(4),
        ),
      ],
    ).animate().fade(duration: 350.ms).slideY(begin: -0.2, duration: 350.ms);
  }

  // ── OVR Hero Card ─────────────────────────────────────────────────────────────
  // Figma: radius=24, border=2px #FFD700@60%, fill=#FFFFFF@3%,
  //        shadow blur=15 #FFD700@30%, backdrop-blur=12

  Widget _buildOvrHeroCard(UserModel athlete) {
    final timingReady = c.isOvrTimingReady;
    final displayedOvr = c.displayedOvr;
    final isHidden   = timingReady && displayedOvr == null;
    final isUnlocked = c.isUnlocked;
    final delta      = c.ovrDelta;


    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF), // #FFFFFF at 3%
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.60),
                width: 2,
              ),
            ),
          child: Column(
            children: [

              // ── Rank badge row ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.seasonGold, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    athlete.rank != null
                        ? 'TEAM RANKING #${athlete.rank}'
                        : 'YOUR RATING',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.seasonGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── OVR number ────────────────────────────────────────────────
              if (!timingReady)
                _buildOvrLoading()
              else if (isHidden)
                _buildHiddenOvr()
              else
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: (displayedOvr ?? 0).toDouble()),
                  builder: (_, val, __) => Text(
                    '${val.toInt()}',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 110,
                      color: const Color(0xFFFFD700),
                      height: 0.9,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFD700).withOpacity(0.60),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),

              // ── "OVERALL RATING" label ────────────────────────────────────
              Text(
                'OVERALL RATING',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.seasonGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 14),

              // ── Season progress pill ──────────────────────────────────────
              // Figma: radius=9999, fill=#FFFFFF@3%, border=1px #00FF88@20%,
              //        backdrop-blur=12, height=30
              if (timingReady && !isHidden)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF), // #FFFFFF @ 3%
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withOpacity(0.20), // #00FF88 @ 20%
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Trending chart icon
                          Icon(Icons.show_chart_rounded,
                              color: AppColors.positive, size: 17),
                          const SizedBox(width: 8),
                          // Solid triangle ▲
                          Icon(
                            delta >= 0
                                ? Icons.change_history_rounded
                                : Icons.details_rounded,
                            color: AppColors.positive,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          // +/- value bold green
                          Text(
                            '${delta >= 0 ? '+' : ''}$delta',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.positive,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // "SEASON PROGRESS" muted label
                          Text(
                            'SEASON PROGRESS',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (timingReady && !isHidden) const SizedBox(height: 14),

              // ── Rank + This Week badges ─────────────────────────────────────
              Row(
                children: [
                  if (athlete.rank != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C5D2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: AppColors.seasonGold,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: AppColors.seasonGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'RANK #${athlete.rank}',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.seasonGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Divider ───────────────────────────────────────────────────
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),

              // ── Phase cap row ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isUnlocked
                            ? Icons.lock_open_rounded
                            : Icons.verified_rounded,
                        color: AppColors.tierGold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timingReady ? c.capStatusLabel : 'SYNCING OVR...',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timingReady ? c.phaseName : 'LOADING',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHiddenOvr() {
    return AnimatedBuilder(
      animation: _streakCtrl,
      builder: (_, __) => Opacity(
        opacity: 0.35 + _streakCtrl.value * 0.65,
        child: Column(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 34,
            ),
            const SizedBox(height: 6),
            Text(
              '???',
              style: GoogleFonts.bebasNeue(
                fontSize: 108,
                color: AppColors.textSecondary,
                height: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvrLoading() {
    return Column(
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.tierGold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '...',
          style: GoogleFonts.bebasNeue(
            fontSize: 92,
            color: AppColors.textSecondary,
            height: 0.9,
          ),
        ),
      ],
    );
  }

  // ── Streaks Card ──────────────────────────────────────────────────────────────
  // Figma: radius=48, border=2px #F2A60D@100%, fill=#F2A60D@10%,
  //        backdrop-blur=12, padding=16, height=76

  Widget _buildStreakCard() {
    const streakColor = Color(0xFFF2A60D); // #F2A60D

    return AnimatedBuilder(
      animation: _streakCtrl,
      builder: (_, __) {
        // Pulse: border and glow breathe together
        final pulseOp = 0.70 + _streakCtrl.value * 0.30; // 70%–100%

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            // Outer glow — kept outside ClipRRect so it doesn't bleed in
            boxShadow: [
              BoxShadow(
                color: streakColor.withOpacity(
                    0.12 + _streakCtrl.value * 0.12),
                blurRadius: 18,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x33F2A60D), // #F2A60D33
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(
                    // #F2A60D full opacity, pulsing
                    color: streakColor.withOpacity(pulseOp),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Fire icon in dark circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.30),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: streakColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "MY STREAKS" — orange label
                        Text(
                          'MY STREAKS',
                          style: GoogleFonts.spaceGrotesk(
                            color: streakColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // "14-DAY STANDARD STREAK" — bold white (fallback if none)
                        Text(
                          c.bestStreakLabel.isNotEmpty
                              ? c.bestStreakLabel
                              : 'NO ACTIVE STREAK',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Latest Feed Card ─────────────────────────────────────────────────────
  Widget _buildLatestFeedCard() {
    final feedCtrl = Get.find<FeedController>();

    return Obx(() {
      // Always show only 1 latest feed item.
      // Prefer non-pinned feed (sorted by createdAt desc in FeedController).
      final items = feedCtrl.feed.take(1).toList();
      if (items.isEmpty && feedCtrl.pinnedItem.value != null) {
        items.add(feedCtrl.pinnedItem.value!);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dynamic_feed_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'LATEST ACTIVITY',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  Text(
                    'No activity yet',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  ...items.asMap().entries.map((e) {
                    final item = e.value;
                    final isLast = e.key == items.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: _buildMiniFeedRow(item),
                    );
                  }),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMiniFeedRow(FeedModel item) {
    final timeText = _feedTimeAgo(item.createdAt);
    final actor = item.actorName.isNotEmpty ? item.actorName : 'Coach';
    final type = item.type.toUpperCase();

    final subtitle = type == 'RATING' || type == 'POINTS'
        ? item.ratingPointsDescription
        : () {
            final category = (item.category ?? '').toString();
            final categoryText = category.isNotEmpty
                ? category.toUpperCase()
                : (type.isNotEmpty ? type : 'ACTIVITY');
            final valuePart = item.value != null
                ? (item.value! > 0 ? '+${item.value}' : '${item.value}')
                : '';
            return valuePart.isNotEmpty
                ? '$categoryText · $valuePart'
                : categoryText;
          }();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: ClipOval(
            child: item.actorProfileUrl != null && item.actorProfileUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.actorProfileUrl!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  )
                : Center(
                    child: Text(
                      actor[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      actor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    timeText,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.content.isNotEmpty &&
                  item.content.trim() != item.ratingPointsDescription) ...[
                const SizedBox(height: 4),
                Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Team OVR Card ─────────────────────────────────────────────────────────
  Widget _buildTeamOvrCard() {
    return Obx(() {
      final t = c.team.value;
      final ovr = t?.averageOvr ?? 0;
      final teamName = (t?.name ?? 'TEAM').toUpperCase();
      final logoUrl = t?.logoUrl;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: logoUrl != null && logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (logoUrl == null || logoUrl.isEmpty)
                      ? const Icon(Icons.sports_football_rounded,
                          color: Colors.white54, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TEAM AVERAGE OVR',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$ovr',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.seasonGold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'OVR',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _feedTimeAgo(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }

  // ── Category Bars ─────────────────────────────────────────────────────────────
  // Figma: radius=24, padding=20, gap=20, fill=#FFFFFF@3%, border=1px #FFFFFF@10%,
  //        backdrop-blur=12

  Widget _buildCategoryBars(
    int perf, int cls, int prog, int std,
    double perfPct, double clsPct, double progPct, double stdPct,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF), // #FFFFFF @ 3%
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x1AFFFFFF), // #FFFFFF @ 10%
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBar('PERFORMANCE', perf, perfPct, AppColors.primary),
              const SizedBox(height: 20),
              _buildBar('CLASSROOM',   cls,  clsPct,  AppColors.positive),
              const SizedBox(height: 20),
              _buildBar('PROGRAM',     prog, progPct, const Color(0xFF9B30FF)),
              const SizedBox(height: 20),
              _buildBar('STANDARD',    std,  stdPct,  const Color(0xFFFF9500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────────
  // Card: radius=24, padding=20, fill=#FFFFFF@3%, border=1px #FFFFFF@10%, blur=12
  // Unlocked: solid color circle, white icon. Locked: grey circle, subtle border, padlock.

  Widget _buildAchievements(List<String> badges) {
    final defs = _kBadgeDefs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        // decoration: BoxDecoration(
        //   color: const Color(0x08FFFFFF), // #FFFFFF @ 3%
        //   // borderRadius: BorderRadius.circular(24),
        //   // border: Border.all(
        //   //   color: const Color(0x1AFFFFFF), // #FFFFFF @ 10%
        //   //   width: 1,
        //   // ),
        // ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: defs.asMap().entries.map((e) {
            final bd       = e.value;
            final unlocked = badges.contains(bd.key);
            return _buildBadgeItem(bd, unlocked, e.key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBadgeItem(_BadgeDef bd, bool unlocked, int idx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? bd.color
                : const Color(0xFF3D454D), // muted grey for locked
            border: unlocked
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: bd.color.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            unlocked ? bd.icon : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
        )
            .animate(delay: Duration(milliseconds: 400 + idx * 70))
            .scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.elasticOut),
        const SizedBox(height: 10),
        Text(
          bd.label,
          style: GoogleFonts.spaceGrotesk(
            color: unlocked
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.40),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Recent Ratings ────────────────────────────────────────────────────────────
  // Design: dark gray cards (#263134), rounded. Left: blue circle+person or gold circle+medal.
  // Main text white, value green/orange, subtitle light gray caps.

  List<_RecentRatingItem> _recentRatingItems(PlayerController c) {
    final history = c.pointHistory.take(3).toList();
    if (history.isNotEmpty) {
      return history.map((tx) {
        final isPos = tx.value > 0;
        final catDisplay = _catDisplay(tx.category);
        final isStandard = tx.category.toLowerCase() == 'standard';
        return _RecentRatingItem(
          mainText: isStandard
              ? 'The Standard goal achieved '
              : 'Your coach awarded you ',
          value: '${isPos ? '+' : ''}${tx.value}',
          valueColor: isPos
              ? (isStandard ? const Color(0xFFFF9800) : const Color(0xFF00C853))
              : AppColors.negative,
          subtitle: '${catDisplay.toUpperCase()} • ${_relTime(tx.createdAt)}',
          useMedalIcon: isStandard,
        );
      }).toList();
    }
    return _kMockRecentRatings;
  }

  // Figma: radius=16, padding=12, gap=12, fill=#FFFFFF@3%, border=1px #FFFFFF@10%, blur=12

  Widget _buildRecentRatingCard(_RecentRatingItem item) {
    final iconBg = item.useMedalIcon
        ? const Color(0xFF96701A)
        : const Color(0xFF243C5B);
    final iconColor = item.useMedalIcon
        ? const Color(0xFFFFC107)
        : const Color(0xFF3E82E0);
    final icon = item.useMedalIcon
        ? Icons.emoji_events_rounded
        : Icons.person_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF), // #FFFFFF @ 3%
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x1AFFFFFF), // #FFFFFF @ 10%
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBg,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD3D4D6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: item.mainText),
                            TextSpan(
                              text: item.value,
                              style: GoogleFonts.inter(
                                color: item.valueColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6E777F),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'performance': return AppColors.primary;
      case 'class':
      case 'classroom':   return AppColors.positive;
      case 'program':     return const Color(0xFF9B30FF);
      case 'standard':    return AppColors.tierGold;
      default:            return AppColors.textSecondary;
    }
  }

  String _catDisplay(String cat) {
    switch (cat.toLowerCase()) {
      case 'class':
      case 'classroom': return 'Classroom';
      case 'program':   return 'Program';
      case 'standard':  return 'Standard';
      default:          return cat;
    }
  }

  String _relTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    return DateFormat('MMM dd').format(dt);
  }
}

// ── Recent rating display item ───────────────────────────────────────────────

class _RecentRatingItem {
  final String mainText;
  final String value;
  final Color valueColor;
  final String subtitle;
  final bool useMedalIcon;
  const _RecentRatingItem({
    required this.mainText,
    required this.value,
    required this.valueColor,
    required this.subtitle,
    required this.useMedalIcon,
  });
}

const _kMockRecentRatings = [
  _RecentRatingItem(
    mainText: 'Coach Smith awarded you ',
    value: '+3',
    valueColor: Color(0xFF00C853),
    subtitle: 'PERFORMANCE • 2H AGO',
    useMedalIcon: false,
  ),
  _RecentRatingItem(
    mainText: 'The Standard goal achieved ',
    value: '+5',
    valueColor: Color(0xFFFF9800),
    subtitle: 'STANDARD • YESTERDAY',
    useMedalIcon: true,
  ),
];

// ── Badge definitions ─────────────────────────────────────────────────────────

class _BadgeDef {
  final String key, label;
  final IconData icon;
  final Color color;
  const _BadgeDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _kBadgeDefs = [
  _BadgeDef(key: 'rising_star', label: 'Rising Star',  icon: Icons.star_outline_rounded, color: Color(0xFFF2A60D)),
  _BadgeDef(key: 'team_player', label: 'Team Player',  icon: Icons.handshake_rounded,   color: AppColors.positive),
  _BadgeDef(key: 'mvp',         label: 'MVP',          icon: Icons.military_tech_rounded, color: AppColors.primary),
  _BadgeDef(key: 'iron_man',    label: 'Iron Man',     icon: Icons.shield_rounded,      color: Color(0xFF9B30FF)),
];
