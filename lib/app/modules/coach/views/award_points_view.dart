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
import '../../../core/components/animated_glowing_border.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/challenge_catalog.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/season_model.dart';

class AwardPointsView extends StatefulWidget {
  const AwardPointsView({super.key});

  @override
  State<AwardPointsView> createState() => _AwardPointsViewState();
}

class _AwardPointsViewState extends State<AwardPointsView>
    with TickerProviderStateMixin {
  final CoachController controller = Get.find<CoachController>();
  static const int _manualPointsMin = -20;
  static const int _manualPointsMax = 20;
  static const double _assessmentColWidth = 62;
  static const double _spreadsheetAthleteColWidth = 130;
  static const double _spreadsheetGap = 4;

  /// Horizontal inset on header/row containers; must be included in [_spreadsheetTableWidth].
  static const double _spreadsheetRowHPadding = 8;

  /// Total horizontal width of the scrollable spreadsheet (padding + columns).
  static double get _spreadsheetTableWidth =>
      _spreadsheetRowHPadding * 2 +
      _spreadsheetAthleteColWidth +
      _spreadsheetGap +
      (_assessmentColWidth * 10);

  final ScrollController _assessmentHScroll = ScrollController();

  final Set<String> selectedAthleteIds = <String>{};

  /// Points per parent category (Athlete, Student, …).
  late Map<String, int> categoryPoints;

  /// Selected challenge label per parent category (required when points ≠ 0).
  late Map<String, String?> selectedChallenge;
  final TextEditingController _noteController = TextEditingController();

  late TabController _tabController;

  // ── Bulk assessment controllers (uid → event → controller) ──────────────
  final Map<String, Map<String, TextEditingController>> _bulkControllers = {};
  final Set<String> _modifiedAthleteIds = {};
  bool _isBulkSaving = false;

  /// When this changes (new season / reset), bulk assessment controllers are cleared.
  String? _assessmentControllersSeasonId;
  Worker? _seasonWorker;

  TextEditingController _ctrlFor(String uid, String event) {
    _bulkControllers[uid] ??= {};
    return _bulkControllers[uid]!.putIfAbsent(
      event,
      () => TextEditingController(),
    );
  }

  void _disposeBulkControllers() {
    for (final m in _bulkControllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _bulkControllers.clear();
  }

  final List<Map<String, dynamic>> categoryDetails = [
    {
      'id': ChallengeCatalog.competitorKey,
      'label': 'COMPETITOR',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFE53935),
    },
    {
      'id': 'Student',
      'label': 'STUDENT',
      'icon': Icons.menu_book,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'Teammate',
      'label': 'TEAMMATE',
      'icon': Icons.handshake,
      'color': const Color(0xFF9C27B0),
    },
    {
      'id': 'Citizen',
      'label': 'CITIZEN',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFFFFB300),
    },
  ];

  bool isLoading = false;
  String _rosterFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    categoryPoints = {for (final c in ChallengeCatalog.parentCategories) c: 0};
    selectedChallenge = {
      for (final c in ChallengeCatalog.parentCategories) c: null,
    };

    _assessmentControllersSeasonId = controller.season.value?.id;
    _seasonWorker = ever(controller.season, (SeasonModel? s) {
      final id = s?.id;
      if (id == null) return;
      if (id != _assessmentControllersSeasonId) {
        _assessmentControllersSeasonId = id;
        _modifiedAthleteIds.clear();
        _disposeBulkControllers();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _assessmentHScroll.dispose();
    _seasonWorker?.dispose();
    _tabController.dispose();
    _noteController.dispose();
    _disposeBulkControllers();
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
    return ChallengeCatalog.shortLabelForCategory(id);
  }

  String _categorySectionTitle(String id) {
    try {
      return categoryDetails.firstWhere((c) => c['id'] == id)['label']
          as String;
    } catch (_) {
      return ChallengeCatalog.displayLabelForCategory(id);
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
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
                            child: Icon(
                              Icons.tune_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SELECT ACTION',
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
                                setState(
                                  () => selectedChallenge[categoryId] = null,
                                );
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
                                  setState(
                                    () => selectedChallenge[categoryId] = s,
                                  );
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: selected ? 0.10 : 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? accent.withValues(alpha: 0.7)
                                          : Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
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
                                            : Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
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
                      validValue ?? 'Select Action',
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
    final valueColor = pts < 0
        ? const Color(0xFFEF4444)
        : (pts > 0 ? const Color(0xFF4ADE80) : Colors.white);
    final challengeOk =
        (selectedChallenge[id] != null &&
        selectedChallenge[id]!.isNotEmpty &&
        ChallengeCatalog.challengesFor(id).contains(selectedChallenge[id]));
    // Coach can also satisfy the requirement with a free-text comment — so
    // don't flash the orange warning border when a note is filled in.
    final hasNoteText = _noteController.text.trim().isNotEmpty;
    final needsChallenge = active && !challengeOk && !hasNoteText;

    final cardBorder = needsChallenge
        ? const Color(0xFFFFB74D).withValues(alpha: 0.85)
        : (active
              ? const Color(0xFF259DF4)
              : Colors.white.withValues(alpha: 0.12));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
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
                  if (v > _manualPointsMin) {
                    setState(() => categoryPoints[id] = v - 1);
                  }
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
                          color: valueColor,
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
                  if (v < _manualPointsMax) {
                    setState(() => categoryPoints[id] = v + 1);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundStepButton({required bool isPlus, required VoidCallback onTap}) {
    final bg = isPlus ? const Color(0x334ADE80) : const Color(0x33EF4444);
    final border = isPlus ? const Color(0x664ADE80) : const Color(0x66EF4444);
    final iconColor = isPlus
        ? const Color(0xFF4ADE80)
        : const Color(0xFFEF4444);
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
                            color: const Color(
                              0xFF00A1FF,
                            ).withValues(alpha: 0.6),
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
                              Icon(
                                Icons.checklist_rounded,
                                color: AppColors.tierGold,
                                size: 22,
                              ),
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
                            final roster = rosterAll
                                .where((a) => _matchesRosterFilter(a, team))
                                .toList();
                            if (rosterAll.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No athletes on roster.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }
                            final selectAllVal = _selectAllValueForRoster(
                              rosterAll,
                            );
                            return Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            tristate: true,
                                            value: selectAllVal,
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  selectedAthleteIds
                                                    ..clear()
                                                    ..addAll(
                                                      rosterAll.map((e) => e.uid),
                                                    );
                                                } else {
                                                  selectedAthleteIds.clear();
                                                }
                                              });
                                              syncSelection();
                                            },
                                            activeColor: const Color(0xFF00A1FF),
                                            checkColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
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
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 34,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.of(
                                              sheetContext,
                                            ).pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF00A1FF,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Done',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      10,
                                      16,
                                      8,
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: _tabsForTeam(team)
                                            .asMap()
                                            .entries
                                            .map((e) {
                                              final label = e.value;
                                              final selected =
                                                  _rosterFilter
                                                      .trim()
                                                      .toLowerCase() ==
                                                  label.trim().toLowerCase();
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  right:
                                                      e.key ==
                                                          _tabsForTeam(
                                                                team,
                                                              ).length -
                                                              1
                                                      ? 0
                                                      : 10,
                                                ),
                                                child: _filterChip(
                                                  label: label,
                                                  selected: selected,
                                                  onTap: () {
                                                    setState(
                                                      () =>
                                                          _rosterFilter = label,
                                                    );
                                                    syncSelection();
                                                  },
                                                ),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        bottom: 28,
                                      ),
                                      itemCount: roster.length,
                                      itemBuilder: (context, index) {
                                        final athlete = roster[index];
                                        final tierColor =
                                            AppColors.getTierColor(
                                              athlete.coachVisibleOvr,
                                            );
                                        final checked = selectedAthleteIds
                                            .contains(athlete.uid);
                                        void toggle() {
                                          setState(() {
                                            if (checked) {
                                              selectedAthleteIds.remove(
                                                athlete.uid,
                                              );
                                            } else {
                                              selectedAthleteIds.add(
                                                athlete.uid,
                                              );
                                            }
                                          });
                                          syncSelection();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: toggle,
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                  border: Border.all(
                                                    color: tierColor.withValues(
                                                      alpha: checked
                                                          ? 0.85
                                                          : 0.45,
                                                    ),
                                                    width: checked ? 1.6 : 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: tierColor
                                                          .withValues(
                                                            alpha: checked
                                                                ? 0.12
                                                                : 0.06,
                                                          ),
                                                      blurRadius: 14,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        AnimatedGlowingBorder(
                                                          // Preserve original avatar sizing:
                                                          // CircleAvatar radius 26 => 52px, plus 2px padding each side => 56px.
                                                          // Add a clean 3px glow gap around it.
                                                          diameter: 62,
                                                          borderWidth: 3,
                                                          duration:
                                                              const Duration(
                                                                seconds: 4,
                                                              ),
                                                          child: SizedBox(
                                                            width: 56,
                                                            height: 56,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      tierColor,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                              child: CircleAvatar(
                                                                radius: 26,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white10,
                                                                backgroundImage:
                                                                    athlete.profilePicUrl !=
                                                                        null
                                                                    ? CachedNetworkImageProvider(
                                                                        athlete
                                                                            .profilePicUrl!,
                                                                      )
                                                                    : null,
                                                                child:
                                                                    athlete.profilePicUrl ==
                                                                        null
                                                                    ? const Icon(
                                                                        Icons
                                                                            .person,
                                                                        color: Colors
                                                                            .white54,
                                                                      )
                                                                    : null,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: -2,
                                                          right: -2,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: tierColor,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFF1E293B,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              '${athlete.coachVisibleOvr}',
                                                              style: GoogleFonts.spaceGrotesk(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            athlete.name,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                GoogleFonts.spaceGrotesk(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            '#${athlete.displayJerseyNumber} • ${(athlete.positionGroup ?? 'ATHLETE').toString().toUpperCase()}',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color: Colors
                                                                      .white54,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Theme(
                                                      data: Theme.of(context).copyWith(
                                                        checkboxTheme:
                                                            CheckboxThemeData(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                            ),
                                                      ),
                                                      child: Checkbox(
                                                        value: checked,
                                                        onChanged: (_) =>
                                                            toggle(),
                                                        activeColor:
                                                            const Color(
                                                              0xFF00A1FF,
                                                            ),
                                                        checkColor:
                                                            Colors.white,
                                                        side: BorderSide(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.35,
                                                              ),
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
      Get.snackbar(
        'Error',
        'Please select at least one athlete.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      return;
    }
    if (_nonZeroCategoryCount == 0) {
      Get.snackbar(
        'Error',
        'Set OVR points for at least one category (− / +).',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      return;
    }

    // Coach satisfies the requirement with EITHER a valid dropdown selection
    // OR a non-empty comment. Only block if neither is present for an active
    // (non-zero) category.
    final hasNote = _noteController.text.trim().isNotEmpty;
    for (final id in ChallengeCatalog.parentCategories) {
      final v = categoryPoints[id] ?? 0;
      if (v == 0) continue;
      final ch = selectedChallenge[id];
      final options = ChallengeCatalog.challengesFor(id);
      final dropdownOk =
          ch != null && ch.isNotEmpty && options.contains(ch);
      if (!dropdownOk && !hasNote) {
        Get.snackbar(
          'Error',
          'Select a reason or write a comment for ${_categorySectionTitle(id)}.',
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
      // If no dropdown was picked, leave subcategory blank — the coach's
      // note becomes the reason on the transaction / feed / notification
      // (see RatingRepository.submitPointsBulk which uses `note` as the
      // feed `content` whenever it is non-empty).
      final ch = selectedChallenge[id] ?? '';
      awards.add(CategoryAwardInput(category: id, subcategory: ch, value: v));
    }

    final roster = List<UserModel>.from(controller.roster);
    final ids = selectedAthleteIds
        .where((id) => roster.any((a) => a.uid == id))
        .toList();
    if (ids.isEmpty) {
      Get.snackbar(
        'Error',
        'No valid athletes selected.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
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
        colorText: Colors.black,
      );
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to submit points: $e');
    }
  }

  // ── Reusable athlete selector card ──────────────────────────────────────

  Widget _buildAthleteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT ATHLETES',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A1FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF00A1FF),
                      size: 28,
                    ),
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
                    color: const Color(0xFF00A1FF).withValues(alpha: 0.95),
                    size: 28,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Subjective (Manual 50%) tab body ──────────────────────────────────────

  Widget _buildManualRatingsBody() {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardBottom),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAthleteSelector()
              .animate(delay: 100.ms)
              .fade(duration: 400.ms)
              .slideX(begin: -0.1, curve: Curves.easeOutCubic),
          const SizedBox(height: 32),

          LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 2;
                  const spacing = 14.0;
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
                },
              )
              .animate(delay: 200.ms)
              .fade(duration: 400.ms)
              .slideX(begin: -0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ADD COACH NOTE',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Visibility: Athlete & Staff',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  // Rebuild so category card borders update live as the coach
                  // types — the note can satisfy the "reason" requirement.
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        'Great footwork in the red zone today. Keep that intensity up!',
                    hintStyle: GoogleFonts.inter(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              )
              .animate(delay: 400.ms)
              .fade(duration: 400.ms)
              .slideX(begin: -0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

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
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Text(
                                'Apply points',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedAthleteIds.isEmpty
                                    ? _categoryPointsSummaryLine()
                                    : '${selectedAthleteIds.length} athlete(s) · ${_categoryPointsSummaryLine()}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
                .animate(delay: 500.ms)
                .fade(duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOutCubic);
          }),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Objective (Assessment 50%) – Bulk Spreadsheet Mode ───────────────────

  List<UserModel> _sortedRosterForAssessments() {
    final list = List<UserModel>.from(controller.roster);
    list.sort((a, b) {
      final gA = a.grade ?? 0;
      final gB = b.grade ?? 0;
      if (gA != gB) return gB.compareTo(gA);

      final partsA = a.name.trim().split(RegExp(r'\s+'));
      final partsB = b.name.trim().split(RegExp(r'\s+'));
      final lastA = (partsA.length > 1 ? partsA.last : partsA.first)
          .toLowerCase();
      final lastB = (partsB.length > 1 ? partsB.last : partsB.first)
          .toLowerCase();
      final c = lastA.compareTo(lastB);
      if (c != 0) return c;
      return partsA.first.toLowerCase().compareTo(partsB.first.toLowerCase());
    });
    return list;
  }

  String _displayLastFirst(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return name;
    return '${parts.last}, ${parts.sublist(0, parts.length - 1).join(' ')}';
  }

  Widget _compactField(
    TextEditingController ctrl, {
    String hint = '',
    VoidCallback? onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (_) => onChanged?.call(),
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.16),
            fontSize: 11,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00A1FF), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSpreadsheetHeader() {
    const headerStyle = TextStyle(
      color: Colors.white54,
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        _spreadsheetRowHPadding,
        10,
        _spreadsheetRowHPadding,
        10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: _spreadsheetAthleteColWidth,
            child: Text('ATHLETE', style: headerStyle),
          ),
          const SizedBox(width: _spreadsheetGap),
          ...[
            ('SQ', const Color(0xFFE53935)),
            ('BP', const Color(0xFFE53935)),
            ('PC', const Color(0xFFE53935)),
            ('DL', const Color(0xFFE53935)),
            ('40yd', const Color(0xFF4CAF50)),
            ('10yd', const Color(0xFF4CAF50)),
            ('5-10-5', const Color(0xFF4CAF50)),
            ('VJ', const Color(0xFF4CAF50)),
            ('BJ', const Color(0xFF4CAF50)),
            ('GPA', const Color(0xFFFFB300)),
          ].map(
            (e) => SizedBox(
              width: _assessmentColWidth,
              child: Center(
                child: Text(e.$1, style: headerStyle.copyWith(color: e.$2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteAssessmentRow(UserModel athlete, int index) {
    final existing = athlete.assessmentData;
    final isDirty = _modifiedAthleteIds.contains(athlete.uid);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        _spreadsheetRowHPadding,
        8,
        _spreadsheetRowHPadding,
        8,
      ),
      decoration: BoxDecoration(
        color: isDirty
            ? const Color(0xFF00C853).withValues(alpha: 0.06)
            : index.isEven
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.centerLeft,
        children: [
          Row(
            children: [
              SizedBox(
                width: _spreadsheetAthleteColWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayLastFirst(athlete.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (athlete.grade != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00A1FF,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Gr ${athlete.grade}',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF00A1FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (athlete.automatedOvr != null &&
                            athlete.automatedOvr! > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00C853,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${athlete.automatedOvr}',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF00C853),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _spreadsheetGap),
              ...[
                ('squat', existing?['squat']),
                ('bench', existing?['bench_press']),
                ('powerClean', existing?['power_clean']),
                ('deadLift', existing?['dead_lift']),
                ('dash40', existing?['40_yard_dash']),
                ('fly10', existing?['10_yard_fly']),
                ('shuttle', existing?['shuttle_5_10_5']),
                ('verticalJump', existing?['vertical_jump']),
                ('broadJump', existing?['standing_long_jump']),
                ('gpa', existing?['gpa']),
              ].map((e) {
                final ctrl = _ctrlFor(athlete.uid, e.$1);
                // Keep fields in sync with Firestore when the row isn't dirty (e.g. after season reset).
                if (!_modifiedAthleteIds.contains(athlete.uid)) {
                  final desired = e.$2 == null ? '' : '${e.$2}';
                  if (ctrl.text != desired) ctrl.text = desired;
                }
                return SizedBox(
                  width: _assessmentColWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _compactField(
                      ctrl,
                      hint: e.$2 != null ? '${e.$2}' : '—',
                      onChanged: () {
                        if (_modifiedAthleteIds.add(athlete.uid)) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
          if (isDirty)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(width: 3, color: const Color(0xFF00C853)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitDirtyAssessments() async {
    if (_modifiedAthleteIds.isEmpty) return;

    final data = <String, Map<String, double?>>{};
    int skipped = 0;

    for (final uid in _modifiedAthleteIds) {
      final ctrls = _bulkControllers[uid];
      if (ctrls == null) continue;

      final squat = double.tryParse(ctrls['squat']?.text.trim() ?? '');
      final bench = double.tryParse(ctrls['bench']?.text.trim() ?? '');
      final powerClean = double.tryParse(
        ctrls['powerClean']?.text.trim() ?? '',
      );
      final deadLift = double.tryParse(ctrls['deadLift']?.text.trim() ?? '');
      final dash = double.tryParse(ctrls['dash40']?.text.trim() ?? '');
      final fly10 = double.tryParse(ctrls['fly10']?.text.trim() ?? '');
      final shuttle = double.tryParse(ctrls['shuttle']?.text.trim() ?? '');
      final verticalJump = double.tryParse(
        ctrls['verticalJump']?.text.trim() ?? '',
      );
      final broadJump = double.tryParse(ctrls['broadJump']?.text.trim() ?? '');
      final gpa = double.tryParse(ctrls['gpa']?.text.trim() ?? '');

      if (squat == null &&
          bench == null &&
          powerClean == null &&
          deadLift == null &&
          dash == null &&
          fly10 == null &&
          shuttle == null &&
          verticalJump == null &&
          broadJump == null &&
          gpa == null) {
        skipped++;
        continue;
      }
      data[uid] = {
        'squat': squat,
        'bench': bench,
        'powerClean': powerClean,
        'deadLift': deadLift,
        'dash40': dash,
        'fly10': fly10,
        'shuttle': shuttle,
        'verticalJump': verticalJump,
        'broadJump': broadJump,
        'gpa': gpa,
      };
    }

    if (data.isEmpty) {
      Get.snackbar(
        'No Athletic Data',
        '$skipped modified athlete(s) had no assessment fields to score.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isBulkSaving = true);
    try {
      await controller.submitBulkAssessments(data);
      final saved = data.length;
      setState(() => _modifiedAthleteIds.clear());
      Get.snackbar(
        'Saved',
        'Updated $saved athlete${saved == 1 ? '' : 's'}.',
        backgroundColor: AppColors.tierGold,
        colorText: Colors.black,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save assessments: $e',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isBulkSaving = false);
    }
  }

  Widget _buildAssessmentsBody() {
    return Obx(() {
      final athletes = _sortedRosterForAssessments();
      if (athletes.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: Colors.white.withValues(alpha: 0.15),
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'No athletes on roster',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSESSMENTS',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _modifiedAthleteIds.isEmpty
                            ? '${athletes.length} athletes'
                            : '${athletes.length} athletes · ${_modifiedAthleteIds.length} unsaved',
                        style: GoogleFonts.inter(
                          color: _modifiedAthleteIds.isEmpty
                              ? Colors.white30
                              : const Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Scrollbar(
                    controller: _assessmentHScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _assessmentHScroll,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: _spreadsheetTableWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSpreadsheetHeader(),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.only(
                                  bottom:
                                      170 +
                                      MediaQuery.viewInsetsOf(context).bottom,
                                ),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                physics: const BouncingScrollPhysics(),
                                itemCount: athletes.length,
                                itemBuilder: (ctx, i) =>
                                    _buildAthleteAssessmentRow(athletes[i], i),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAssessmentTab = _tabController.index == 1;
    final dirtyCount = _modifiedAthleteIds.length;
    final showFab = isAssessmentTab && dirtyCount > 0;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Keep FAB fixed above coach bottom nav; scroll views add viewInsets padding instead.
      resizeToAvoidBottomInset: false,
      floatingActionButton: showFab
          ? Padding(
              padding: EdgeInsets.only(bottom: 72 + bottomInset),
              child: FloatingActionButton.extended(
                onPressed: _isBulkSaving ? null : _submitDirtyAssessments,
                backgroundColor: _isBulkSaving
                    ? const Color(0xFF00C853).withValues(alpha: 0.6)
                    : const Color(0xFF00C853),
                icon: _isBulkSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  _isBulkSaving
                      ? 'Saving…'
                      : dirtyCount == 1
                      ? 'Save 1 Assessment'
                      : 'Save $dirtyCount Assessments',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // const FireSparksBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF00A1FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00A1FF).withValues(alpha: 0.5),
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      labelPadding: EdgeInsets.zero,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_note_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Subjective'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speed_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Objective'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildManualRatingsBody(),
                        _buildAssessmentsBody(),
                      ],
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
}
