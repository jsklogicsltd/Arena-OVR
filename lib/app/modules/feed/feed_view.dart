import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'feed_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/fire_sparks_background.dart';
import '../../core/components/animated_glowing_border.dart';
import '../../data/models/feed_model.dart';
import '../coach/coach_controller.dart';
import '../coach/views/announcement_view.dart';

class FeedView extends GetView<FeedController> {
  const FeedView({Key? key}) : super(key: key);

  static String _timeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  static String _dateSectionLabel(DateTime? date) {
    if (date == null) return 'Recent';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'TODAY';
    if (d == yesterday) return 'YESTERDAY';
    return '${date.month}/${date.day}/${date.year}';
  }

  bool get _isCoachContext {
    try {
      return Get.isRegistered<CoachController>() &&
          Get.find<CoachController>().currentTeam.value != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StadiumBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // const FireSparksBackground(),
          SafeArea(
            child: Column(
              children: [
            _buildAppBar(context),
            Expanded(
              child: Obx(() {
                final pinned = controller.pinnedItem.value;
                final rest = <FeedModel>[...controller.feed, ...controller.moreItems];
                final isEmpty = pinned == null && rest.isEmpty;

                if (isEmpty && !controller.isLoadingMore.value) {
                  return Center(
                    child: Text(
                      'No activity yet',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return _FeedList(
                  pinned: pinned,
                  restItems: rest,
                  timeAgo: _timeAgo,
                  dateLabel: _dateSectionLabel,
                  onLoadMore: controller.loadMore,
                  isLoadingMore: controller.isLoadingMore.value,
                  hasMore: controller.hasMore.value,
                );
              }),
            ),
              ],
            ),
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
                Icon(Icons.dynamic_feed_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'RECOGNITION WALL',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.local_fire_department_rounded, color: Colors.orange.shade400, size: 22),
              ],
            ),
          ),
          if (_isCoachContext)
            GestureDetector(
              onTap: () => Get.to(() => const AnnouncementView()),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
              ),
            )
          else
            const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  final FeedModel? pinned;
  final List<FeedModel> restItems;
  final String Function(DateTime?) timeAgo;
  final String Function(DateTime?) dateLabel;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  const _FeedList({
    required this.pinned,
    required this.restItems,
    required this.timeAgo,
    required this.dateLabel,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (widget.hasMore && !widget.isLoadingMore && pos.pixels >= pos.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.pinned != null) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: PinnedAnnouncementCard(
          item: widget.pinned!,
          timeAgo: widget.timeAgo(widget.pinned!.createdAt),
        ),
      ));
    }

    final byDate = <String, List<FeedModel>>{};
    for (final item in widget.restItems) {
      final label = widget.dateLabel(item.createdAt);
      byDate.putIfAbsent(label, () => []).add(item);
    }
    final sortedDates = byDate.keys.toList();
    for (final dateLabel in sortedDates) {
      children.add(_DateDivider(label: dateLabel));
      for (final item in byDate[dateLabel]!) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _buildCard(item, widget.timeAgo),
        ));
      }
    }

    if (widget.isLoadingMore) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  Widget _buildCard(FeedModel item, String Function(DateTime?) timeAgo) {
    switch (item.type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return _AnnouncementCard(item: item, timeAgo: timeAgo(item.createdAt));
      case 'RATING':
      case 'POINTS':
        return PointAwardCard(item: item, timeAgo: timeAgo(item.createdAt));
      case 'BADGE':
        return BadgeEarnedCard(item: item);
      case 'JOINED':
      case 'MEMBER_JOINED':
        return AthleteJoinedCard(item: item);
      case 'ADJUSTMENT':
      case 'NEGATIVE':
        return NegativeAdjustmentCard(item: item, timeAgo: timeAgo(item.createdAt));
      default:
        return _GenericFeedCard(item: item, timeAgo: timeAgo(item.createdAt));
    }
  }
}

class _DateDivider extends StatelessWidget {
  final String label;

  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// Non-pinned announcement in list (no PINNED badge, no gold border)
class _AnnouncementCard extends StatelessWidget {
  final FeedModel item;
  final String timeAgo;

  const _AnnouncementCard({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(item.actorProfileUrl, item.actorName, 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.actorName, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (item.actorRole != null) Text(item.actorRole!, style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11)),
                  ],
                ),
              ),
              Text(timeAgo, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.content, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Pinned Announcement Card ─────────────────────────────────────────────
// Figma: 358x161, radius 24, fill #FFFFFF 3%, border top 2px #FFD700, blur 12
class PinnedAnnouncementCard extends StatelessWidget {
  final FeedModel item;
  final String timeAgo;

  const PinnedAnnouncementCard({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Stack(
            children: [
              // Gold top accent (Figma: 2px top border)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.push_pin_rounded, color: Color(0xFFE53935), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'PINNED',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(item.actorProfileUrl, item.actorName, 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.actorName,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.actorRole != null && item.actorRole!.isNotEmpty)
                          Text(
                            item.actorRole!,
                            style: GoogleFonts.inter(color: const Color(0xFF00A1FF), fontSize: 11),
                          ),
                        const SizedBox(height: 8),
                        _highlightMessage(item.content),
                      ],
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
      ),
    );
  }

  Widget _highlightMessage(String text) {
    // Simple highlight: wrap **text** in yellow
    final spans = <TextSpan>[];
    int i = 0;
    final regex = RegExp(r'\*\*(.+?)\*\*');
    for (final m in regex.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start), style: const TextStyle(color: Colors.white, fontSize: 13)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w700)));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i), style: const TextStyle(color: Colors.white, fontSize: 13)));
    if (spans.isEmpty) return Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 13));
    return RichText(
      text: TextSpan(style: GoogleFonts.inter(fontSize: 13, color: Colors.white), children: spans),
    );
  }
}

// ─── Point Award Card ─────────────────────────────────────────────────────
// Figma: 358x208.5, radius 24, fill #FFFFFF 0.2%, shadows, left blue accent
class PointAwardCard extends StatelessWidget {
  final FeedModel item;
  final String timeAgo;

  const PointAwardCard({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final categoryLabel = (item.category ?? 'PERFORMANCE').toString().toUpperCase().replaceAll(' ', ' ');
    final detailLine = item.ratingPointsDescription;
    final coachNoteTrim = item.content.trim();
    final hasCoachNote = coachNoteTrim.isNotEmpty &&
        coachNoteTrim != detailLine;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.002),
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 8), blurRadius: 10, spreadRadius: -6),
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 20), blurRadius: 25, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(item.actorProfileUrl, item.actorName, 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.actorName} • $timeAgo',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.actorName} awarded ${item.targetDisplayLabel}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            detailLine,
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryLabel,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (hasCoachNote) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${item.content}"',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.value != null && item.value! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '+${item.value}',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.positive, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                )
              else if (item.value != null && item.value! < 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${item.value}',
                    style: GoogleFonts.spaceGrotesk(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Badge Earned Card ─────────────────────────────────────────────────────
// Figma: gradient #2D1B4E -> #141B2D, border #A855F7 30%, radius 24, padding 16
class BadgeEarnedCard extends StatelessWidget {
  final FeedModel item;

  const BadgeEarnedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B4E), Color(0xFF141B2D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 8), blurRadius: 10, spreadRadius: -6),
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 20), blurRadius: 25, spreadRadius: -5),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade400, Colors.amber.shade700],
              ),
              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.amber.shade400, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'BADGE UNLOCKED',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.amber.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.targetName.isNotEmpty ? item.targetName : 'Athlete',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.content.isNotEmpty ? item.content : 'Earned a new badge',
                  style: GoogleFonts.inter(color: const Color(0xFFB8A8D0), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Athlete Joined Card ───────────────────────────────────────────────────
// Figma: 358x56, radius 24, padding 12, #141B2D, left border 4px #00A1FF
class AthleteJoinedCard extends StatelessWidget {
  final FeedModel item;

  const AthleteJoinedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          left: BorderSide(color: Color(0xFF00A1FF), width: 4),
          top: BorderSide(color: Colors.white12, width: 1),
          right: BorderSide(color: Colors.white12, width: 1),
          bottom: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Row(
        children: [
          _avatar(item.actorProfileUrl, item.targetName.isNotEmpty ? item.targetName : item.actorName, 32),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                children: [
                  const TextSpan(text: '👋 '),
                  TextSpan(
                    text: item.targetName.isNotEmpty ? item.targetName : item.actorName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' joined the team!'),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NEW PRO',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Negative Adjustment Card ─────────────────────────────────────────────
// Figma: 358x68, radius 24, #141B2D 50%, opacity 80%, left border 4px #EF4444 50%
class NegativeAdjustmentCard extends StatelessWidget {
  final FeedModel item;
  final String timeAgo;

  const NegativeAdjustmentCard({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141B2D).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border(
            left: BorderSide(color: AppColors.negative.withValues(alpha: 0.5), width: 4),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.person_off_rounded, color: Colors.white54, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating adjusted for ${item.targetName.isNotEmpty ? item.targetName : 'athlete'}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.content.isNotEmpty || item.category != null)
                    Text(
                      'Reason: ${item.category ?? item.content}',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 22),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericFeedCard extends StatelessWidget {
  final FeedModel item;
  final String timeAgo;

  const _GenericFeedCard({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        children: [
          _avatar(item.actorProfileUrl, item.actorName, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.actorName} — ${item.content}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(timeAgo, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _avatar(String? profileUrl, String name, double size) {
  final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  return AnimatedGlowingBorder(
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
          color: Colors.white12,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: ClipOval(
          child: profileUrl != null && profileUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: profileUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                      child: Text(initials,
                          style: const TextStyle(color: Colors.white70, fontSize: 14))),
                  errorWidget: (_, __, ___) => Center(
                      child: Text(initials,
                          style: const TextStyle(color: Colors.white70, fontSize: 14))),
                )
              : Center(
                  child: Text(initials,
                      style:
                          TextStyle(color: Colors.white70, fontSize: size * 0.4))),
        ),
      ),
    ),
  );
}
