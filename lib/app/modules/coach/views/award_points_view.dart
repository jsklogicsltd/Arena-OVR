import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../coach_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/challenge_catalog.dart';
import '../../../data/models/team_model.dart';

class AwardPointsView extends StatefulWidget {
  const AwardPointsView({super.key});

  @override
  State<AwardPointsView> createState() => _AwardPointsViewState();
}

class _AwardPointsViewState extends State<AwardPointsView> {
  final CoachController controller = Get.find<CoachController>();

  final Set<String> selectedAthleteIds = <String>{};
  /// Points per parent category (Performance, Classroom, …).
  late Map<String, int> categoryPoints;
  /// Selected challenge label per parent category (required when points ≠ 0).
  late Map<String, String?> selectedChallenge;
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> categoryDetails = [
    {
      'id': 'Performance',
      'label': 'PERFORMANCE',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFE53935),
    },
    {
      'id': 'Classroom',
      'label': 'CLASSROOM',
      'icon': Icons.menu_book,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'Program',
      'label': 'PROGRAM',
      'icon': Icons.handshake,
      'color': const Color(0xFF9C27B0),
    },
    {
      'id': 'Standard',
      'label': 'STANDARD',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFFFFB300),
    },
  ];

  bool isLoading = false;
  String _rosterFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    categoryPoints = {
      for (final c in ChallengeCatalog.parentCategories) c: 0,
    };
    selectedChallenge = {
      for (final c in ChallengeCatalog.parentCategories) c: null,
    };
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _bucketForPositionGroup(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v.contains('OFF')) return 'OFFENSE';
    if (v.contains('DEF')) return 'DEFENSE';
    if (v.contains('SPEC')) return 'SPECIAL TEAMS';
    return 'OTHER';
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

  List<String> _tabsForTeam(TeamModel? team) {
    final pos = _uniqueTrimmed(team?.positionGroups ?? const []);
    final tags = _uniqueTrimmed(team?.customTags ?? const []);
    return ['ALL', ...pos, ...tags];
  }

  bool _matchesRosterFilter(UserModel a, TeamModel? team) {
    if (_rosterFilter == 'ALL') return true;

    final pos = team?.positionGroups ?? const <String>[];
    final tags = team?.customTags ?? const <String>[];
    final sel = _rosterFilter.trim().toLowerCase();

    final isPos = pos.any((e) => e.trim().toLowerCase() == sel);
    if (isPos) {
      return _bucketForPositionGroup(a.positionGroup).toLowerCase() == sel;
    }

    final isTag = tags.any((e) => e.trim().toLowerCase() == sel);
    if (isTag) {
      return (a.customTag ?? '').trim().toLowerCase() == sel;
    }

    return true;
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00A1FF).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00A1FF).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  String _categoryShortLabel(String id) {
    switch (id) {
      case 'Performance':
        return 'Perf';
      case 'Classroom':
        return 'Class';
      case 'Program':
        return 'Prog';
      case 'Standard':
        return 'Std';
      default:
        return id;
    }
  }

  String _categorySectionTitle(String id) {
    try {
      return categoryDetails.firstWhere((c) => c['id'] == id)['label'] as String;
    } catch (_) {
      return id;
    }
  }

  String _categoryPointsSummaryLine() {
    final bits = <String>[];
    for (final id in ChallengeCatalog.parentCategories) {
      final v = categoryPoints[id] ?? 0;
      if (v == 0) continue;
      final sign = v > 0 ? '+' : '';
      final ch = selectedChallenge[id];
      final chShort = (ch == null || ch.isEmpty)
          ? '…'
          : (ch.length > 16 ? '${ch.substring(0, 14)}…' : ch);
      bits.add('${_categoryShortLabel(id)} $sign$v ($chShort)');
    }
    if (bits.isEmpty) {
      return 'Pick challenges & points below';
    }
    return bits.join(' · ');
  }

  int get _nonZeroCategoryCount =>
      categoryPoints.values.where((v) => v != 0).length;

  Widget _challengeDropdown({
    required String categoryId,
    required Color accent,
    required bool highlightError,
  }) {
    final items = ChallengeCatalog.challengesFor(categoryId);
    final sel = selectedChallenge[categoryId];
    final validValue = sel != null && items.contains(sel) ? sel : null;

    Future<void> openSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.tune_rounded,
                                color: accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SELECT CHALLENGE',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (validValue != null)
                            TextButton(
                              onPressed: () {
                                setState(() =>
                                    selectedChallenge[categoryId] = null);
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                'CLEAR',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final s = items[i];
                          final selected = s == validValue;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() =>
                                      selectedChallenge[categoryId] = s);
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                        alpha: selected ? 0.10 : 0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? accent.withValues(alpha: 0.7)
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: selected ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: selected
                                            ? accent
                                            : Colors.white.withValues(alpha: 0.35),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    final borderColor = highlightError
        ? const Color(0xFFFFB74D).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openSheet,
            child: Container(
              width: double.infinity,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      validValue ?? 'Select challenge',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: validValue == null
                            ? Colors.white.withValues(alpha: 0.65)
                            : Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryAwardBlock(Map<String, dynamic> cat) {
    final id = cat['id'] as String;
    final color = cat['color'] as Color;
    final pts = categoryPoints[id] ?? 0;
    final active = pts != 0;
    final challengeOk = (selectedChallenge[id] != null &&
        selectedChallenge[id]!.isNotEmpty &&
        ChallengeCatalog.challengesFor(id).contains(selectedChallenge[id]));
    final needsChallenge = active && !challengeOk;

    final cardBorder = needsChallenge
        ? const Color(0xFFFFB74D).withValues(alpha: 0.85)
        : (active ? const Color(0xFF259DF4) : Colors.white.withValues(alpha: 0.12));

    return Container(
      // Slightly tighter padding so the dropdown looks wider in the card.
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        // Keep constant so the card size never changes when it becomes active/error.
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF259DF4).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(cat['icon'] as IconData, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (cat['label'] as String),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _challengeDropdown(
            categoryId: id,
            accent: color,
            highlightError: needsChallenge,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _roundStepButton(
                isPlus: false,
                onTap: () {
                  final v = categoryPoints[id] ?? 0;
                  if (v > -99) setState(() => categoryPoints[id] = v - 1);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(pts < 0 ? '-' : '')}${pts.abs().toString().padLeft(2, '0')}',
                        maxLines: 1,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(width: 10),
              _roundStepButton(
                isPlus: true,
                onTap: () {
                  final v = categoryPoints[id] ?? 0;
                  if (v < 99) setState(() => categoryPoints[id] = v + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundStepButton({
    required bool isPlus,
    required VoidCallback onTap,
  }) {
    final bg = isPlus ? const Color(0x334ADE80) : const Color(0x33EF4444);
    final border = isPlus ? const Color(0x664ADE80) : const Color(0x66EF4444);
    final iconColor = isPlus ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    final icon = isPlus ? Icons.add : Icons.remove;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border, width: 1),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
    );
  }

  bool? _selectAllValueForRoster(List<UserModel> roster) {
    if (roster.isEmpty) return false;
    var count = 0;
    for (final a in roster) {
      if (selectedAthleteIds.contains(a.uid)) count++;
    }
    if (count == 0) return false;
    if (count == roster.length) return true;
    return null;
  }

  void _openAthleteMultiSelectSheet() {
    if (controller.roster.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void syncSelection() {
              setModalState(() {});
              setState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF141B2D),
                        Color(0xFF0F172A),
                        Color(0xFF0A0E1A),
                      ],
                    ),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A1FF).withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A1FF).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checklist_rounded,
                                  color: AppColors.tierGold, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'SELECT ATHLETES',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to include players in this award',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final team = controller.currentTeam.value;
                            final rosterAll = controller.roster.toList()
                              ..sort((a, b) {
                                final an = a.name.trim().toLowerCase();
                                final bn = b.name.trim().toLowerCase();
                                return an.compareTo(bn);
                              });
                            final roster = rosterAll.where((a) => _matchesRosterFilter(a, team)).toList();
                            if (rosterAll.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No athletes on roster.',
                                  style: GoogleFonts.inter(
                                      color: Colors.white54, fontSize: 14),
                                ),
                              );
                            }
                            final selectAllVal = _selectAllValueForRoster(rosterAll);
                            return Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CheckboxListTile(
                                    tristate: true,
                                    value: selectAllVal,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          selectedAthleteIds
                                            ..clear()
                                            ..addAll(rosterAll.map((e) => e.uid));
                                        } else {
                                          selectedAthleteIds.clear();
                                        }
                                      });
                                      syncSelection();
                                    },
                                    activeColor: const Color(0xFF00A1FF),
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                    title: Text(
                                      'Select All (Team)',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${selectedAthleteIds.length} selected',
                                      style: GoogleFonts.inter(
                                          color: Colors.white54, fontSize: 12),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  Divider(
                                      height: 1,
                                      color: Colors.white
                                          .withValues(alpha: 0.08)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: _tabsForTeam(team)
                                            .asMap()
                                            .entries
                                            .map((e) {
                                          final label = e.value;
                                          final selected = _rosterFilter.trim().toLowerCase() ==
                                              label.trim().toLowerCase();
                                          return Padding(
                                            padding: EdgeInsets.only(
                                                right: e.key ==
                                                        _tabsForTeam(team).length - 1
                                                    ? 0
                                                    : 10),
                                            child: _filterChip(
                                              label: label,
                                              selected: selected,
                                              onTap: () {
                                                setState(() => _rosterFilter = label);
                                                syncSelection();
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, bottom: 28),
                                      itemCount: roster.length,
                                      itemBuilder: (context, index) {
                                        final athlete = roster[index];
                                        final tierColor = AppColors.getTierColor(
                                            athlete.coachVisibleOvr);
                                        final checked = selectedAthleteIds
                                            .contains(athlete.uid);
                                        void toggle() {
                                          setState(() {
                                            if (checked) {
                                              selectedAthleteIds.remove(athlete.uid);
                                            } else {
                                              selectedAthleteIds.add(athlete.uid);
                                            }
                                          });
                                          syncSelection();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: toggle,
                                              borderRadius: BorderRadius.circular(22),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                  border: Border.all(
                                                    color: tierColor.withValues(
                                                        alpha: checked ? 0.85 : 0.45),
                                                    width: checked ? 1.6 : 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: tierColor.withValues(
                                                          alpha: checked ? 0.12 : 0.06),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                                color: tierColor,
                                                                width: 2),
                                                          ),
                                                          child: CircleAvatar(
                                                            radius: 26,
                                                            backgroundColor:
                                                                Colors.white10,
                                                            backgroundImage: athlete
                                                                        .profilePicUrl !=
                                                                    null
                                                                ? CachedNetworkImageProvider(
                                                                    athlete
                                                                        .profilePicUrl!,
                                                                  )
                                                                : null,
                                                            child: athlete
                                                                        .profilePicUrl ==
                                                                    null
                                                                ? const Icon(
                                                                    Icons.person,
                                                                    color:
                                                                        Colors.white54,
                                                                  )
                                                                : null,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: -2,
                                                          right: -2,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                    horizontal: 6,
                                                                    vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: tierColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(8),
                                                              border: Border.all(
                                                                color: const Color(
                                                                    0xFF1E293B),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              '${athlete.coachVisibleOvr}',
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight.w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            athlete.name,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                            style: GoogleFonts
                                                                .spaceGrotesk(
                                                              color: Colors.white,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            '#${athlete.jerseyNumber ?? '0'} • ${(athlete.positionGroup ?? 'ATHLETE').toString().toUpperCase()}',
                                                            style: GoogleFonts.inter(
                                                              color: Colors.white54,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Theme(
                                                      data: Theme.of(context).copyWith(
                                                        checkboxTheme: CheckboxThemeData(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    6),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Checkbox(
                                                        value: checked,
                                                        onChanged: (_) => toggle(),
                                                        activeColor:
                                                            const Color(0xFF00A1FF),
                                                        checkColor: Colors.white,
                                                        side: BorderSide(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.35),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (selectedAthleteIds.isEmpty) {
      Get.snackbar('Error', 'Please select at least one athlete.',
          backgroundColor: AppColors.primary, colorText: Colors.white);
      return;
    }
    if (_nonZeroCategoryCount == 0) {
      Get.snackbar('Error',
          'Set OVR points for at least one category (− / +).',
          backgroundColor: AppColors.primary, colorText: Colors.white);
      return;
    }

    for (final id in ChallengeCatalog.parentCategories) {
      final v = categoryPoints[id] ?? 0;
      if (v == 0) continue;
      final ch = selectedChallenge[id];
      final options = ChallengeCatalog.challengesFor(id);
      if (ch == null || ch.isEmpty || !options.contains(ch)) {
        Get.snackbar(
          'Error',
          'Select a challenge for ${_categorySectionTitle(id)} (dropdown).',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
        return;
      }
    }

    final awards = <CategoryAwardInput>[];
    for (final id in ChallengeCatalog.parentCategories) {
      final v = categoryPoints[id] ?? 0;
      if (v == 0) continue;
      final ch = selectedChallenge[id]!;
      awards.add(CategoryAwardInput(
        category: id,
        subcategory: ch,
        value: v,
      ));
    }

    final roster = List<UserModel>.from(controller.roster);
    final ids = selectedAthleteIds
        .where((id) => roster.any((a) => a.uid == id))
        .toList();
    if (ids.isEmpty) {
      Get.snackbar('Error', 'No valid athletes selected.',
          backgroundColor: AppColors.primary, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);
    try {
      await controller.submitPointsBulk(
        athleteIds: ids,
        awards: awards,
        note: _noteController.text.trim(),
      );

      setState(() {
        isLoading = false;
        selectedAthleteIds.clear();
        for (final k in categoryPoints.keys.toList()) {
          categoryPoints[k] = 0;
        }
        for (final k in selectedChallenge.keys.toList()) {
          selectedChallenge[k] = null;
        }
        _noteController.clear();
      });

      Get.snackbar(
          'Success',
          'Awards applied to ${ids.length} athlete(s) (${awards.length} challenge line(s) each).',
          backgroundColor: AppColors.tierGold,
          colorText: Colors.black);
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to submit points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── APP BAR ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        'AWARD POINTS',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),

                // ── TEAM ROSTER (tap opens checklist sheet) ───────────────
                Text('SELECT ATHLETES',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Obx(() {
                  final roster = controller.roster.toList()
                    ..sort((a, b) {
                      final an = a.name.trim().toLowerCase();
                      final bn = b.name.trim().toLowerCase();
                      return an.compareTo(bn);
                    });

                  if (roster.isEmpty) {
                    return GlassCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      leftBorderColor: const Color(0xFF00A1FF),
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No athletes on this roster yet.',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                      ),
                    );
                  }

                  final n = selectedAthleteIds.length;
                  final summary = n == 0
                      ? 'Tap to choose players'
                      : n == roster.length
                          ? 'Full team ($n players)'
                          : '$n of ${roster.length} selected';

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openAthleteMultiSelectSheet,
                    child: GlassCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      leftBorderColor: const Color(0xFF00A1FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A1FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.groups_rounded,
                                color: Color(0xFF00A1FF), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Athletes',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF00A1FF)
                                .withValues(alpha: 0.95),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  );
                }).animate(delay: 100.ms).fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),

                // ── CHALLENGES & POINTS BY CATEGORY ───────────────────────
                // Text('CHALLENGES & OVR',
                //     style: GoogleFonts.spaceGrotesk(
                //         color: Colors.white54,
                //         fontSize: 11,
                //         letterSpacing: 1.5,
                //         fontWeight: FontWeight.bold)),
                // const SizedBox(height: 6),
                // Text(
                //   'Each pillar has its own challenge list. Example: Performance +5 on “Strength Improvement”, Classroom +10 on “GPA 3.5+” — both in one Apply.',
                //   style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, height: 1.35),
                // ),
                // const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  // Always keep two cards per row (per requirement).
                  final w = constraints.maxWidth;
                  const crossAxisCount = 2;
                  final spacing = 14.0;
                  final cardW =
                      (w - (crossAxisCount - 1) * spacing) / crossAxisCount;
                  // Taller cards so header + dropdown + stepper never overflow.
                  // 173w × 210h => ratio ~ 0.82
                  const ratio = 173 / 210;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: ratio,
                    children: categoryDetails.map(_categoryAwardBlock).toList(),
                  );
                }).animate(delay: 200.ms).fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 12),

                // ── COACH NOTE ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ADD COACH NOTE',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold)),
                    Text('Visibility: Athlete & Staff',
                        style:
                            GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText:
                          'Great footwork in the red zone today. Keep that intensity up!',
                      hintStyle:
                          GoogleFonts.inter(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ).animate(delay: 400.ms).fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),

                // ── SUBMIT (hidden when roster is empty) ───────────────────
                Obx(() {
                  if (controller.roster.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: isLoading ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4DA0FF), Color(0xFF1E50FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: isLoading
                          ? const Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)))
                          : Column(
                              children: [
                                Text(
                                  'Apply Points',
                                   style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedAthleteIds.isEmpty
                                      ? _categoryPointsSummaryLine()
                                      : '${selectedAthleteIds.length} athlete(s) · ${_categoryPointsSummaryLine()}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                    ),
                  ).animate(delay: 500.ms).fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic);
                }),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
