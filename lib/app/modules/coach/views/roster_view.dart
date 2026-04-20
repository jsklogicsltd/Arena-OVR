import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/components/animated_glowing_border.dart';
import '../../../core/utils/elite_ovr_style.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';

class RosterView extends StatefulWidget {
  const RosterView({super.key});

  @override
  State<RosterView> createState() => _RosterViewState();
}

class _RosterViewState extends State<RosterView> {
  final CoachController controller = Get.find<CoachController>();

  String _filter = 'ALL';

  String _bucketForPositionGroup(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    // Match Award Points + Manage Roster semantics:
    // We only trust explicit Firestore assignments (OFF/DEF/SPECIAL).
    if (v.contains('OFF')) return 'OFFENSE';
    if (v.contains('DEF')) return 'DEFENSE';
    if (v.contains('SPEC')) return 'SPECIAL TEAMS';
    return 'UNASSIGNED';
  }

  static List<String> _uniqueTrimmed(List<String> raw) {
    final out = <String>[];
    final seen = <String>{};
    for (final v in raw) {
      final t = v.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  List<String> _tabsForTeam() {
    final team = controller.currentTeam.value;
    final pos = _uniqueTrimmed(team?.positionGroups ?? const []);
    final tags = _uniqueTrimmed(team?.customTags ?? const []);
    return ['ALL', ...pos, ...tags];
  }

  bool _matchesFilter(UserModel item) {
    if (_filter == 'ALL') return true;

    final team = controller.currentTeam.value;
    final pos = team?.positionGroups ?? const <String>[];
    final tags = team?.customTags ?? const <String>[];

    final isPos = pos.any((e) => e.trim().toLowerCase() == _filter.trim().toLowerCase());
    if (isPos) {
      return _bucketForPositionGroup(item.positionGroup).toLowerCase() ==
          _filter.trim().toLowerCase();
    }

    final isTag = tags.any((e) => e.trim().toLowerCase() == _filter.trim().toLowerCase());
    if (isTag) {
      return (item.customTag ?? '').trim().toLowerCase() == _filter.trim().toLowerCase();
    }

    return true;
  }

  Widget _buildFilterChip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00A1FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected
                ? const Color(0xFF00A1FF)
                : const Color(0x33FFFFFF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    // Match Coach bottom nav scaling (barHeight = 72 * scale)
    final scale = (w / 390).clamp(0.85, 1.0);
    final navHeight = 72.0 * scale;

    final fabSize = (w * 0.148).clamp(52.0, 60.0);
    final fabRight = (w * 0.055).clamp(16.0, 32.0);
    // Place FAB clearly above bottom nav with safe padding for small phones/text
    final fabBottom = navHeight +
        12.0 +
        (h < 700 ? 6.0 : 0.0) +
        (MediaQuery.textScalerOf(context).scale(14) > 16 ? 10.0 : 0.0);
    final listBottomPad = fabBottom + fabSize + 24.0;

    return StadiumBackground(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Premium subtle background layer (non-interactive).
          // const Positioned.fill(child: FireSparksBackground()),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Center(
                  child: Text(
                    'MY TEAM',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
              )
                  .animate()
                  .fade(duration: 400.ms)
                  .slideY(begin: -0.3, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),

              // Team Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Obx(() {
                  final team = controller.currentTeam.value;
                  final teamName = team?.name ?? 'My Team';
                  final teamCode = team?.teamCode ?? 'CODE';
                  final schoolName = team?.schoolName ?? 'Unknown School';

                  return GlassCard(
                    backgroundColor: const Color(0x0DFFFFFF),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            image: team?.logoUrl != null && team!.logoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(team.logoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: team?.logoUrl == null || team!.logoUrl!.isEmpty
                              ? const Icon(Icons.sports_football, color: Colors.white, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teamName,
                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                schoolName,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9999),
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: teamCode.toUpperCase()),
                                  );
                                  Get.snackbar(
                                    'Copied',
                                    'Team code copied',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        Colors.green.withValues(alpha: 0.85),
                                    colorText: Colors.white,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1AFFD700), // 10% FFD700
                                    border: Border.all(
                                        color: const Color(0x80FFD700),
                                        width: 1), // 50% FFD700
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        teamCode.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(
                                            color: AppColors.tierGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.copy,
                                          color: AppColors.tierGold, size: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${controller.roster.length} PLAYERS',
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00A1FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fade(duration: 500.ms)
                      .slideX(begin: -0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
                      .then()
                      .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: 300.ms, curve: Curves.easeOut);
                }),
              ),

              const SizedBox(height: 24),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Obx(() {
                  final tabs = _tabsForTeam();
                  if (!tabs.any((t) => t.trim().toLowerCase() == _filter.trim().toLowerCase())) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _filter = 'ALL');
                    });
                  }
                  return Row(
                    children: tabs
                        .asMap()
                        .entries
                        .map((e) {
                          final chip = _buildFilterChip(e.value);
                          return Padding(
                            padding: EdgeInsets.only(right: e.key == tabs.length - 1 ? 0 : 12),
                            child: chip
                                .animate(delay: (280 + e.key * 80).ms)
                                .fade(duration: 400.ms)
                                .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic)
                                .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1, 1),
                                    duration: 350.ms,
                                    curve: Curves.easeOut),
                          );
                        })
                        .toList(),
                  );
                }),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Obx(() {
                  final items = controller.roster.toList()
                    ..removeWhere((e) => !_matchesFilter(e))
                    ..sort((a, b) {
                      int ovrOf(UserModel x) {
                        return x.coachVisibleOvr;
                      }

                      String nameOf(UserModel x) {
                        return x.name;
                      }

                      final oa = ovrOf(a);
                      final ob = ovrOf(b);
                      final cmpOvr = ob.compareTo(oa); // high OVR first
                      if (cmpOvr != 0) return cmpOvr;

                      final na = nameOf(a).trim().toLowerCase();
                      final nb = nameOf(b).trim().toLowerCase();
                      final cmpName = na.compareTo(nb); // A..Z on tie
                      if (cmpName != 0) return cmpName;

                      // Stable fallback for identical names
                      return nameOf(a).compareTo(nameOf(b));
                    });

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'No athletes found for this team.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, listBottomPad),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      
                      // Safe extraction of real vs mock fields
                      final name = item.name.isNotEmpty ? item.name : 'Unknown';
                      final groupLabel = _bucketForPositionGroup(item.positionGroup);
                      final position = '#${item.displayJerseyNumber} · $groupLabel';
                      final int ovr = item.coachVisibleOvr;
                      final bool isElite = EliteOvrStyle.isEliteOvr(ovr);
                      final bool? trendUp = null; // no real trend signal yet
                      final tierColor = AppColors.getTierColor(ovr);
                      final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                      final String? photoUrl = item.profilePicUrl;

                      final baseCard = GlassCard(
                        backgroundColor: isElite ? null : const Color(0x0DFFFFFF), // #FFFFFF at 0D (5% approx)
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leftBorderColor: isElite ? const Color(0xFFFFE08A) : tierColor,
                        gradient: isElite ? EliteOvrStyle.eliteCardGradient : null,
                        borderColor: isElite ? const Color(0xFFFFE08A) : null,
                        glowColor: isElite ? const Color(0x66FFD700) : null,
                        child: Row(
                          children: [
                            AnimatedGlowingBorder(
                              // Preserve original avatar sizing: 44 (radius 22) + 2*2 padding = 48.
                              // Give the SweepGradient room: add a clean 3px gap around it.
                              diameter: 54,
                              borderWidth: 3,
                              duration: const Duration(seconds: 4),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: tierColor, width: 2),
                                  ),
                                  child: EliteOvrStyle.tintedAvatar(
                                    isElite: isElite,
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white10,
                                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(photoUrl)
                                          : null,
                                      child: photoUrl == null || photoUrl.isEmpty
                                          ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        position,
                                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      if (trendUp != null)
                                        Icon(
                                          trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: trendUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935), // Green / Red
                                          size: 14,
                                        )
                                      else
                                        const Text('—', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$ovr',
                                      style: GoogleFonts.spaceGrotesk(color: isElite ? const Color(0xFF2E1E00) : tierColor, fontSize: 24, fontWeight: FontWeight.w900, height: 1.0),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 28.0, top: 2),
                                  child: Text(
                                    'OVR',
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );

                      final tappableCard = GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final team = controller.currentTeam.value;
                          final season = controller.season.value;
                          Get.toNamed(
                            Routes.ATHLETE_PROFILE,
                            arguments: {
                              'athlete': item,
                              'isCoachView': true,
                              'teamId': team?.id,
                              'seasonId': season?.id,
                            },
                          );
                        },
                        child: baseCard,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey<String>('roster_athlete_${item.uid}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            final confirmed = await Get.dialog<bool>(
                              AlertDialog(
                                backgroundColor: const Color(0xFF101A24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'Remove Player?',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to remove $name from the team?',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    height: 1.45,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.inter(color: Colors.white54),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: Text(
                                      'Remove',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFE53935),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return false;
                            try {
                              await controller.removePlayer(item.uid);
                              Get.snackbar(
                                'Removed',
                                '$name is no longer on this team.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green.withValues(alpha: 0.88),
                                colorText: Colors.white,
                              );
                              return true;
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Could not remove player: $e',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red.withValues(alpha: 0.85),
                                colorText: Colors.white,
                              );
                              return false;
                            }
                          },
                          child: tappableCard,
                        ),
                      )
                          .animate(delay: (120 + index * 90).ms)
                          .fade(duration: 450.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.12, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)
                          .then()
                          .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), duration: 280.ms, curve: Curves.easeOut);
                    },
                  );
                }),
              ),
            ],
            ),
          ),
          // FAB sits above coach bottom nav overlap (34px) + padding
          Positioned(
            right: fabRight,
            bottom: fabBottom,
            child: Material(
              elevation: 12,
              shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.55),
              color: const Color(0xFFFFD700),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.changeTab(2),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: Icon(
                    Icons.add_rounded,
                    color: const Color(0xFF172A36),
                    size: fabSize * 0.54,
                  ),
                ),
              ),
            ),
          )
              .animate(delay: 400.ms)
              .fade(duration: 350.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

}
