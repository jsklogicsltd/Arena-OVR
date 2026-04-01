import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'notifications_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/stadium_background.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StadiumBackground(
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildFilterPills(),
            Expanded(
              child: Obx(() {
                final items = controller.displayedItems;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      controller.filterIndex.value == 1
                          ? 'No unread notifications'
                          : controller.filterIndex.value == 2
                              ? 'No archived items'
                              : 'No notifications yet',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      item: items[index],
                      onTap: () => controller.markAsRead(items[index].id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Colors.white70, size: 24),
                    Obx(() {
                      if (controller.unreadCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A1FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'NOTIFICATIONS',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: Text(
              'MARK ALL READ',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    const labels = ['ALL', 'UNREAD', 'ARCHIVE'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = controller.filterIndex.value == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
              child: GestureDetector(
                onTap: () => controller.setFilter(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(9999),
                    border: isActive
                        ? null
                        : Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: GoogleFonts.spaceGrotesk(
                        color: isActive ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Figma card: 356x93, radius 24, fill #FFFFFF 0.2%, shadow #00A1FF 40%, x:-4, y:0, blur 12, spread -2
class _NotificationCard extends StatelessWidget {
  final NotificationListItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final iconData = _iconForType(item.type);
    final iconBg = _iconColorForType(item.type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0x05FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),

        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isUnread)
                    Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBg,
                          ),
                          child: Icon(iconData, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _timeAgo(item.createdAt),
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A1FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  static IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'RATING':
        return Icons.star_rounded;
      case 'POINTS':
        return Icons.bolt_rounded;
      case 'BADGE':
        return Icons.emoji_events_rounded;
      case 'ANNOUNCEMENT':
        return Icons.campaign_rounded;
      case 'SEASON_RESET':
        return Icons.refresh_rounded;
      case 'JOINED':
      case 'MEMBER_JOINED':
        return Icons.person_add_rounded;
      case 'ADJUSTMENT':
      case 'NEGATIVE':
        return Icons.trending_down_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _iconColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'RATING':
      case 'POINTS':
        return const Color(0xFF243C5B);
      case 'BADGE':
        return const Color(0xFF5C4A1A);
      case 'ANNOUNCEMENT':
        return Colors.grey.shade700;
      case 'SEASON_RESET':
        return const Color(0xFF7C4A0A);
      case 'JOINED':
      case 'MEMBER_JOINED':
        return const Color(0xFF00A1FF).withOpacity(0.3);
      case 'ADJUSTMENT':
      case 'NEGATIVE':
        return const Color(0xFFEF4444).withOpacity(0.3);
      default:
        return Colors.white24;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(date);
  }
}
