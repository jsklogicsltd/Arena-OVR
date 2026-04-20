import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../player_controller.dart';
import '../../coach/coach_controller.dart';
import '../../leaderboard/leaderboard_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/periodic_shimmer_bar.dart';
import '../../../core/widgets/badge_trophy_case.dart';
import '../../../core/utils/elite_ovr_style.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/rating_repository.dart';

/// Can be used in two modes:
/// 1. Own profile from bottom-nav tab → isOwnProfile = true (default)
/// 2. Coach viewing an athlete        → pass via Get.arguments:
///    { 'athlete': UserModel, 'isCoachView': true, 'teamId': '...', 'seasonId': '...' }
class AthleteProfileView extends StatefulWidget {
  final bool isOwnProfile;
  const AthleteProfileView({super.key, this.isOwnProfile = true});

  @override
  State<AthleteProfileView> createState() => _AthleteProfileViewState();
}

class _AthleteProfileViewState extends State<AthleteProfileView>
    with TickerProviderStateMixin {
  late AnimationController _barsCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _athAnim, _stuAnim, _tmAnim, _citAnim;

  UserModel?                    _athlete;
  List<TransactionModel>        _history = [];
  bool                          _historyLoading = false;
  bool                          _isCoachView = false;

  @override
  void initState() {
    super.initState();
    _barsCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _cardCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _resolveData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barsCtrl.forward();
      _cardCtrl.forward();
    });
  }

  void _resolveData() {
    if (widget.isOwnProfile) {
      final c = Get.find<PlayerController>();
      _athlete     = c.athlete.value;
      _isCoachView = false;
      final real   = c.pointHistory.toList();
      _history     = real.isNotEmpty ? real : _staticHistory;
      _historyLoading = false;
    } else {
      final args   = Get.arguments as Map<String, dynamic>? ?? {};
      _athlete     = args['athlete'] as UserModel?;
      _isCoachView = args['isCoachView'] as bool? ?? false;
      _history     = _staticHistory;
      if (_athlete != null) _fetchHistory(_athlete!.uid);
      else _historyLoading = false;
    }
    if (_athlete != null) _setupBarAnims(_athlete!);
  }

  void _setupBarAnims(UserModel a) {
    const maxScore = 100.0;
    final r   = a.currentRating;
    final ath = ((r['Athlete']  ?? r['Competitor'] ?? r['Performance'] ?? 0) as num).toDouble();
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

  List<TransactionModel> get _staticHistory => _mockHistory('static');

  /// Resolves current rank: from athlete.rank if set, else from LeaderboardController.ranked by uid.
  int? _effectiveRank(UserModel athlete) {
    if (athlete.rank != null) return athlete.rank;
    try {
      final lb = Get.find<LeaderboardController>();
      final idx = lb.ranked.indexWhere((u) => u.uid == athlete.uid);
      if (idx >= 0) return idx + 1;
    } catch (_) {}
    return null;
  }

  Future<void> _fetchHistory(String uid) async {
    setState(() => _historyLoading = true);
    try {
      final list = await RatingRepository().getAthleteHistory(uid);
      _history = list.isNotEmpty ? list : _staticHistory;
    } catch (_) {
      _history = _staticHistory;
    }
    if (mounted) setState(() => _historyLoading = false);
  }

  @override
  void dispose() {
    _barsCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For own-profile mode, rebuild reactively when controller data changes
    if (widget.isOwnProfile) {
      final c = Get.find<PlayerController>();
      return Obx(() {
        _athlete = c.athlete.value;
        final real = c.pointHistory.toList();
        _history = real.isNotEmpty ? real : _staticHistory;
        if (_athlete != null) _setupBarAnims(_athlete!);
        return _buildScaffold(c: c);
      });
    }
    return _buildScaffold();
  }

  Widget _buildScaffold({PlayerController? c}) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // const FireSparksBackground(),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A0E1A).withOpacity(0),
                    const Color(0xFF0A0E1A).withOpacity(0.85),
                    const Color(0xFF0A0E1A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: _athlete == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.tierGold))
                : _buildBody(c),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PlayerController? c) {
    final athlete = _athlete!;
    final r       = athlete.currentRating;
    final ath     = ((r['Athlete']  ?? r['Competitor'] ?? r['Performance'] ?? 0) as num).toInt();
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

              // ── Back button (coach view only) ───────────────────────────────
              if (!widget.isOwnProfile)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.12), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ).animate().fade(duration: 300.ms),
              if (!widget.isOwnProfile) const SizedBox(height: 12),

              // ── Trading Card Header ─────────────────────────────────────────
              _buildTradingCard(athlete, c),
              const SizedBox(height: 28),

              // ── Category Stats ──────────────────────────────────────────────
              Text(
                'CATEGORY STATS',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 250.ms).fade(),
              const SizedBox(height: 14),

              AnimatedBuilder(
                animation: _barsCtrl,
                builder: (_, __) => _buildCategoryBars(
                  ath, stu, tm, cit,
                  _athAnim.value, _stuAnim.value, _tmAnim.value, _citAnim.value,
                ),
              ).animate(delay: 250.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 28),

              // ── Achievements ────────────────────────────────────────────────
              Text(
                'ACHIEVEMENTS',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 380.ms).fade(),
              const SizedBox(height: 14),

              _buildAchievements(athlete.badges)
                  .animate(delay: 380.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 28),

              // ── History ─────────────────────────────────────────────────────
              Text(
                'HISTORY',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate(delay: 500.ms).fade(),
              const SizedBox(height: 14),

              if (_historyLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.tierGold),
                  ),
                )
              else
                ..._history.asMap().entries.map((e) =>
                    _buildHistoryItem(e.value)
                        .animate(delay: Duration(milliseconds: 550 + e.key * 70))
                        .fade(duration: 350.ms)
                        .slideX(begin: 0.08, duration: 350.ms)),

              // ── Award Points (Coach view) ─────────────────────────────────────
              if (_isCoachView) ...[
                const SizedBox(height: 16),
                _buildAwardButton()
                    .animate(delay: 700.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              ],

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Player Card Header ───────────────────────────────────────────────────────
  // Figma: radius=24, fill=#FFFFFF@5%, border=1px #FFFFFF@10%, blur=12

  Widget _buildTradingCard(UserModel athlete, PlayerController? c) {
    final isOwnView = widget.isOwnProfile;
    final delta     = isOwnView ? (c?.ovrDelta ?? 0) : _weekDelta();

    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (_, __) {
        final opacity = Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut))
            .value;
        final slide = Tween<double>(begin: 20, end: 0)
            .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut))
            .value;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF), // #FFFFFF @ 5%
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x1AFFFFFF), // #FFFFFF @ 10%
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card body: photo + info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlayerPhoto(athlete),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPlayerInfo(athlete, c)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rank + This Week pills (use Wrap to avoid overflow on small screens)
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                                  _effectiveRank(athlete) != null
                                      ? 'RANK #${_effectiveRank(athlete)}'
                                      : 'RANK —',
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (delta >= 0
                                      ? AppColors.positive
                                      : AppColors.negative)
                                  .withOpacity(0.85),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: (delta >= 0
                                        ? AppColors.positive
                                        : AppColors.negative)
                                    .withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  delta >= 0
                                      ? Icons.change_history_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${delta >= 0 ? '+' : ''}$delta THIS WEEK',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPlayerPhoto(UserModel athlete) {
    const borderColor = AppColors.seasonGold;
    final elite = EliteOvrStyle.isEliteOvr(athlete.coachVisibleOvr);
    return Container(
      width: 120,
      height: 170,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: EliteOvrStyle.tintedAvatar(
          isElite: elite,
          child: athlete.profilePicUrl != null
              ? CachedNetworkImage(
                  imageUrl: athlete.profilePicUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFF0F1923),
                    child: Icon(Icons.person_rounded,
                        color: borderColor.withOpacity(0.5), size: 48),
                  ),
                  errorWidget: (_, __, ___) => _photoPlaceholder(borderColor),
                )
              : _photoPlaceholder(borderColor),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(Color color) {
    return Container(
      color: const Color(0xFF0F1923),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, color: color.withOpacity(0.5), size: 48),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(UserModel athlete, PlayerController? c) {
    final shownOvr = widget.isOwnProfile
        ? (c?.displayedOvr ?? 0)
        : athlete.coachVisibleOvr;
    // Match athlete dashboard: ??? only after season/team streams resolved (not while loading).
    final isOvrHidden = widget.isOwnProfile &&
        c != null &&
        c.isOvrDisplayResolved &&
        c.displayedOvr == null;
    final showOvrLoading =
        widget.isOwnProfile && c != null && !c.isOvrDisplayResolved;
    String teamName;
    if (widget.isOwnProfile && c != null) {
      teamName = c.team.value?.name ?? '—';
    } else {
      // Coach view: use current team name if athlete belongs to it
      try {
        final coachTeam = Get.find<CoachController>().currentTeam.value;
        teamName = (coachTeam != null && athlete.teamId == coachTeam.id)
            ? coachTeam.name
            : '—';
      } catch (_) {
        teamName = '—';
      }
    }
    final tierColor = AppColors.seasonGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          athlete.name.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            color: Colors.white,
            fontSize: 28,
            letterSpacing: 1.0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Builder(
          builder: (_) {
            final pos = (athlete.positionGroup ?? '').trim();
            final rawJersey = (athlete.jerseyNumber ?? '').trim();
            final hasJerseyField =
                rawJersey.isNotEmpty && rawJersey.toLowerCase() != 'null';
            if (!hasJerseyField && pos.isEmpty) return const SizedBox.shrink();
            return Text(
              [
                '#${athlete.displayJerseyNumber}',
                if (pos.isNotEmpty) pos,
              ].join(' • '),
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Team name — same as Player Settings: TEAM label + team name
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEAM',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teamName,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // OVR Number + label
        if (showOvrLoading)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 52,
                width: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.tierGold.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'SYNCING OVR…',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FINAL OVR (50/50 CURVE)',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.seasonGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          )
        else if (isOvrHidden)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '???',
                style: GoogleFonts.bebasNeue(
                  fontSize: 64,
                  color: AppColors.textSecondary,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FINAL OVR (50/50 CURVE)',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.seasonGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          )
        else
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOut,
            tween: Tween(begin: 0, end: shownOvr.toDouble()),
            builder: (_, val, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${val.toInt()}',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 64,
                    color: tierColor,
                    height: 0.9,
                    shadows: [
                      Shadow(
                        color: tierColor.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FINAL OVR (50/50 CURVE)',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.seasonGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Category Stats ─────────────────────────────────────────────────────────────
  // Figma per card: radius=16, padding=12, fill=#FFFFFF@5%, border=1px #FFFFFF@10%,
  //                blur=12, gap=8 (between cards). Labels: PERFORMANCE, TEAMMATE, IMPACT, THE STANDARD.

  Widget _buildCategoryBars(
    int ath, int stu, int tm, int cit,
    double athPct, double stuPct, double tmPct, double citPct,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatCard('COMPETITOR',   ath, athPct, AppColors.primary),
        const SizedBox(height: 8),
        _buildStatCard('STUDENT',   stu, stuPct, AppColors.positive),
        const SizedBox(height: 8),
        _buildStatCard('TEAMMATE',  tm,  tmPct,  const Color(0xFF9B30FF)),
        const SizedBox(height: 8),
        _buildStatCard('CITIZEN',   cit, citPct, const Color(0xFFFF9500)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, double pct, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF), // #FFFFFF @ 5%
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x1AFFFFFF), // #FFFFFF @ 10%
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: 6),
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
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────────

  Widget _buildAchievements(List<String> badges) {
    return BadgeTrophyCase(earnedBadges: badges, badgeSize: 54);
  }

  // ── History ───────────────────────────────────────────────────────────────────
  // Figma: radius 16px, padding 12px, fill #FFFFFF 5%, border 1px #FFFFFF 10%, blur 12, gap 16px

  static const Color _historyPositiveBar = Color(0xFF2196F3); // bright blue
  static const Color _historyPositiveTitle = Color(0xFF00C853); // vibrant green
  static const Color _historyNegative = Color(0xFFF44336);
  static const Color _historyNegativeDot = Color(0xFFFF9800); // orange

  Widget _buildHistoryItem(TransactionModel tx) {
    final isPos = tx.value > 0;
    final valueStr = '${isPos ? '+' : ''}${tx.value} ${_catDisplay(tx.category)}';
    final barColor = isPos ? _historyPositiveBar : _historyNegative;
    final dotColor = isPos ? _historyPositiveBar : _historyNegativeDot;
    final titleColor = isPos ? _historyPositiveTitle : _historyNegative;

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
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: vertical bar + dot (16px gap to content per Figma)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3,
                      height: 42,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              valueStr,
                              style: GoogleFonts.spaceGrotesk(
                                color: titleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            tx.createdAt != null
                                ? DateFormat('MMM dd').format(tx.createdAt!)
                                : '',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (tx.subcategory != null &&
                          tx.subcategory!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          tx.subcategory!.trim(),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (tx.note != null && tx.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"${tx.note}"',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
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

  // ── Award Points Button (coach view) ──────────────────────────────────────────

  Widget _buildAwardButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to AwardPointsView with pre-selected athlete
        // Arguments passed back to coach flow
        Get.back(result: {'awardFor': _athlete});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.tierGold, Color(0xFFFF9500)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.tierGold.withOpacity(0.40),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFF0A0E1A), size: 20),
            const SizedBox(width: 10),
            Text(
              'AWARD POINTS',
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF0A0E1A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  int _weekDelta() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _history
        .where((t) => t.createdAt != null && t.createdAt!.isAfter(cutoff))
        .fold<int>(0, (sum, t) => sum + t.value);
  }

  String _catDisplay(String cat) {
    switch (cat.toLowerCase()) {
      case 'athlete':
      case 'competitor':
      case 'performance': return 'Competitor';
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

  List<TransactionModel> _mockHistory(String uid) => [
    TransactionModel(
      id: '1', athleteId: uid, coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Competitor', value: 3,
      note: 'Exceptional drive and accuracy on the final quarter.',
      type: 'RATING',
      createdAt: DateTime(2024, 10, 4),
    ),
    TransactionModel(
      id: '2', athleteId: uid, coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Citizen', value: -1,
      note: 'Late arrival to recovery session.',
      type: 'RATING',
      createdAt: DateTime(2024, 10, 1),
    ),
    TransactionModel(
      id: '3', athleteId: uid, coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Student', value: 2,
      note: 'Great support during film review and helping teammates.',
      type: 'RATING',
      createdAt: DateTime(2024, 9, 28),
    ),
    TransactionModel(
      id: '4', athleteId: uid, coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Teammate', value: 1,
      note: 'Consistent attendance and effort in recovery sessions.',
      type: 'RATING',
      createdAt: DateTime(2024, 9, 25),
    ),
  ];
}

