import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../player_controller.dart';
import '../../feed/feed_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/components/animated_glowing_border.dart';
import '../../../core/widgets/periodic_shimmer_bar.dart';
import '../../../data/models/feed_model.dart';
import '../../../data/models/user_model.dart';

class AthleteDashboardView extends StatelessWidget {
  const AthleteDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PlayerController>();
    return StadiumBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // const FireSparksBackground(),
          Obx(() {
            if (c.isLoading.value && c.athlete.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.tierGold),
              );
            }
            final athlete = c.athlete.value;
            if (athlete == null) return const SizedBox.shrink();
            return _DashboardBody(c: c, athlete: athlete);
          }),
        ],
      ),
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
  late Animation<double> _athAnim, _stuAnim, _tmAnim, _citAnim;

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
    final r   = a.currentRating;
    final ath = ((r['Athlete']  ?? r['Performance'] ?? 0) as num).toDouble();
    final stu = ((r['Student']  ?? r['Class']       ?? 0) as num).toDouble();
    final tm  = ((r['Teammate'] ?? r['Program']     ?? 0) as num).toDouble();
    final cit = ((r['Citizen']  ?? r['Standard']    ?? 0) as num).toDouble();

    _athAnim = Tween<double>(begin: 0, end: (ath / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.00, 0.75, curve: Curves.easeOut)));
    _stuAnim = Tween<double>(begin: 0, end: (stu / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.12, 0.82, curve: Curves.easeOut)));
    _tmAnim  = Tween<double>(begin: 0, end: (tm  / maxScore).clamp(0.0, 1.0)).animate(
        CurvedAnimation(parent: _barsCtrl, curve: const Interval(0.24, 0.90, curve: Curves.easeOut)));
    _citAnim = Tween<double>(begin: 0, end: (cit / maxScore).clamp(0.0, 1.0)).animate(
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
    final ath     = ((r['Athlete']  ?? r['Performance'] ?? 0) as num).toInt();
    final stu     = ((r['Student']  ?? r['Class']       ?? 0) as num).toInt();
    final tm      = ((r['Teammate'] ?? r['Program']     ?? 0) as num).toInt();
    final cit     = ((r['Citizen']  ?? r['Standard']    ?? 0) as num).toInt();

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
                  ath, stu, tm, cit,
                  _athAnim.value, _stuAnim.value, _tmAnim.value, _citAnim.value,
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
        AnimatedGlowingBorder(
          diameter: 58,
          borderWidth: 3,
          duration: const Duration(seconds: 4),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Container(
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
                '#${athlete.displayJerseyNumber} • '
                '${(athlete.positionGroup ?? '').trim().isEmpty ? 'Athlete' : athlete.positionGroup}',
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
  // Premium FUT-style presentation (visual only; logic unchanged).

  /// Icy glass OVR glyphs: outer glow + cool stroke + gradient fill (used for score and ???).
  Widget _crystalOvrText(
    String text, {
    required double fontSize,
    double height = 0.92,
  }) {
    final base = GoogleFonts.bebasNeue(
      fontSize: fontSize,
      height: height,
      color: Colors.white,
    );
    // Transparent ink so only Shadow halos render — reads as bloom behind the face.
    final glowStyle = base.copyWith(
      color: Colors.transparent,
      shadows: [
        Shadow(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.52),
          blurRadius: 11,
        ),
        Shadow(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.42),
          blurRadius: 5,
        ),
        Shadow(
          color: const Color(0xFF7DD3FC).withValues(alpha: 0.32),
          blurRadius: 17,
        ),
        Shadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.16),
          blurRadius: 16,
        ),
        Shadow(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
          blurRadius: 28,
        ),
      ],
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Text(text, textAlign: TextAlign.center, style: glowStyle),
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.35
              ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FF),
              Color(0xFFD0EAFE),
              Color(0xFFF8FCFF),
              Color(0xFFBEE8FF),
            ],
            stops: [0.0, 0.22, 0.45, 0.72, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: base.copyWith(
              shadows: [
                Shadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.55),
                  blurRadius: 1.5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOvrHeroCard(UserModel athlete) {
    final ovrResolved = c.isOvrDisplayResolved;
    final displayedOvr = c.displayedOvr;
    final isHidden   = ovrResolved && displayedOvr == null;
    final isUnlocked = c.isUnlocked;
    final delta      = c.ovrDelta;
    final showOvrLoader = !ovrResolved;

    const Color kGold = Color(0xFFFFD700);
    const Color kElectricBlue = Color(0xFF38BDF8);
    const Color kLightBlue = Color(0xFF7DD3FC);
    const Color kCrystalLabel = Color(0xFFE2C96E);

    Widget coinWrap(Widget inner) {
      return AnimatedBuilder(
        animation: _streakCtrl,
        builder: (context, _) {
          final t = _streakCtrl.value;
          final blurGold = 28.0 + t * 27.0;
          final goldGlowOp = 0.35 + t * 0.30;
          return Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A2540), Color(0xFF080C18)],
                radius: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: goldGlowOp),
                  blurRadius: blurGold,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                width: 2.5,
              ),
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Center(child: inner),
                ],
              ),
            ),
          );
        },
      );
    }

    final Widget ovrCoin = Center(
      child: showOvrLoader
          ? coinWrap(
              Center(child: _buildOvrLoading()),
            )
          : isHidden
              ? coinWrap(
                  Center(child: _buildHiddenOvr()),
                )
              : coinWrap(
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    tween: Tween(
                      begin: 0,
                      end: (displayedOvr ?? 0).toDouble(),
                    ),
                    builder: (_, val, __) => _crystalOvrText(
                      '${val.toInt()}',
                      fontSize: 88,
                    ),
                  ),
                ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1120), Color(0xFF060912)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _streakCtrl,
                builder: (_, __) {
                  final o = 0.25 + _streakCtrl.value * 0.30;
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.0,
                        colors: [
                          const Color(0xFF1B3F6B).withValues(alpha: o),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _CornerPainter(corner: _CornerBracket.topLeft),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(
                    begin: -0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _CornerPainter(corner: _CornerBracket.topRight),
                ),
              )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 600.ms)
                  .slideX(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _CornerPainter(corner: _CornerBracket.bottomLeft),
                ),
              )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 600.ms)
                  .slideX(
                    begin: -0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _CornerPainter(corner: _CornerBracket.bottomRight),
                ),
              )
                  .animate(delay: 240.ms)
                  .fadeIn(duration: 600.ms)
                  .slideX(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFF0D1526),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: kGold.withValues(alpha: 0.95),
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            athlete.rank != null
                                ? 'TEAM RANKING #${athlete.rank}'
                                : 'YOUR RATING',
                            style: GoogleFonts.spaceGrotesk(
                              color: kGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(
                          onPlay: (ac) => ac.repeat(),
                        )
                        .shimmer(
                          duration: 2800.ms,
                          color: Colors.white.withValues(alpha: 0.25),
                          angle: 0.3,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ovrCoin
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        curve: Curves.elasticOut,
                        duration: 900.ms,
                      ),
                  const SizedBox(height: 10),
                  Text(
                    'OVERALL RATING',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: kCrystalLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5.0,
                    ),
                  )
                      .animate(
                        onPlay: (ac) => ac.repeat(),
                      )
                      .shimmer(
                        duration: 3200.ms,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                  const SizedBox(height: 14),
                  if (ovrResolved && !isHidden)
                    Container(
                      width: double.infinity,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF020D1A),
                            Color(0xFF041422),
                          ],
                        ),
                        border: Border.all(
                          color: kElectricBlue.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kElectricBlue.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            color: kElectricBlue,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            delta >= 0
                                ? Icons.change_history_rounded
                                : Icons.details_rounded,
                            color: kLightBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${delta >= 0 ? '+' : ''}$delta',
                            style: GoogleFonts.spaceGrotesk(
                              color: kLightBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'SEASON PROGRESS',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 400.ms)
                        .slideY(
                          begin: 0.4,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        )
                        .fade(duration: 400.ms),
                  if (ovrResolved && !isHidden) const SizedBox(height: 14),
                  Row(
                    children: [
                      if (athlete.rank != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C5D2E)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: AppColors.seasonGold,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppColors.seasonGold,
                                size: 14,
                              ),
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
                        )
                            .animate()
                            .shimmer(
                              duration: 2400.ms,
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            ),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          kElectricBlue.withValues(alpha: 0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            ovrResolved ? c.capStatusLabel : 'SYNCING OVR...',
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
                        ovrResolved ? c.phaseName : 'LOADING',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 600.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.2),
                ],
              ),
            ),
          ],
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
            _crystalOvrText('???', fontSize: 108, height: 0.9),
          ],
        ),
      ),
    );
  }

  Widget _buildOvrLoading() {
    return const SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 2.6,
        color: AppColors.tierGold,
      ),
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
                AnimatedGlowingBorder(
                  diameter: 62,
                  borderWidth: 3,
                  duration: const Duration(seconds: 4),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Container(
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
                  ),
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
    int ath, int stu, int tm, int cit,
    double athPct, double stuPct, double tmPct, double citPct,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x1AFFFFFF),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBar('ATHLETE',   ath, athPct, AppColors.primary),
              const SizedBox(height: 20),
              _buildBar('STUDENT',   stu, stuPct, AppColors.positive),
              const SizedBox(height: 20),
              _buildBar('TEAMMATE',  tm,  tmPct,  const Color(0xFF9B30FF)),
              const SizedBox(height: 20),
              _buildBar('CITIZEN',   cit, citPct, const Color(0xFFFF9500)),
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
        PeriodicShimmerBar(
          baseColor: color,
          shimmerFraction: pct.clamp(0.0, 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
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
        final isCitizen = tx.category.toLowerCase() == 'citizen' || tx.category.toLowerCase() == 'standard';
        return _RecentRatingItem(
          mainText: isCitizen
              ? 'Citizen goal achieved '
              : 'Your coach awarded you ',
          value: '${isPos ? '+' : ''}${tx.value}',
          valueColor: isPos
              ? (isCitizen ? const Color(0xFFFF9800) : const Color(0xFF00C853))
              : AppColors.negative,
          subtitle: '${catDisplay.toUpperCase()} • ${_relTime(tx.createdAt)}',
          useMedalIcon: isCitizen,
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

  String _catDisplay(String cat) {
    switch (cat.toLowerCase()) {
      case 'athlete':
      case 'performance': return 'Athlete';
      case 'student':
      case 'class':
      case 'classroom':   return 'Student';
      case 'teammate':
      case 'program':     return 'Teammate';
      case 'citizen':
      case 'standard':    return 'Citizen';
      default:            return cat;
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

enum _CornerBracket { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.corner});

  final _CornerBracket corner;

  static const double _arm = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    switch (corner) {
      case _CornerBracket.topLeft:
        canvas.drawLine(const Offset(0, _arm), Offset.zero, paint);
        canvas.drawLine(Offset.zero, const Offset(_arm, 0), paint);
        break;
      case _CornerBracket.topRight:
        canvas.drawLine(Offset(w - _arm, 0), Offset(w, 0), paint);
        canvas.drawLine(Offset(w, 0), Offset(w, _arm), paint);
        break;
      case _CornerBracket.bottomLeft:
        canvas.drawLine(Offset(0, h - _arm), Offset(0, h), paint);
        canvas.drawLine(Offset(0, h), Offset(_arm, h), paint);
        break;
      case _CornerBracket.bottomRight:
        canvas.drawLine(Offset(w, h - _arm), Offset(w, h), paint);
        canvas.drawLine(Offset(w - _arm, h), Offset(w, h), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.corner != corner;
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
    subtitle: 'ATHLETE • 2H AGO',
    useMedalIcon: false,
  ),
  _RecentRatingItem(
    mainText: 'Citizen goal achieved ',
    value: '+5',
    valueColor: Color(0xFFFF9800),
    subtitle: 'CITIZEN • YESTERDAY',
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
