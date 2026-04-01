import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Single notification item for the list.
class NotificationListItem {
  final String id;
  final String title;
  final String body;
  final String type; // RATING, BADGE, ANNOUNCEMENT, SEASON_RESET, etc.
  final DateTime? createdAt;
  final bool isRead;

  NotificationListItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.createdAt,
    this.isRead = false,
  });
}

/// Streams notifications for the current user. markRead / markAllRead update Firestore; stream updates list and bell count.
class NotificationsController extends GetxController {
  final NotificationRepository _repo = NotificationRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<NotificationListItem> allItems = <NotificationListItem>[].obs;
  final RxInt filterIndex = 0.obs; // 0=ALL, 1=UNREAD, 2=ARCHIVE
  StreamSubscription? _sub;

  List<NotificationListItem> get displayedItems {
    if (filterIndex.value == 1) return allItems.where((e) => !e.isRead).toList();
    if (filterIndex.value == 2) return allItems.where((e) => e.isRead).toList();
    return allItems.toList();
  }

  int get unreadCount => allItems.where((e) => !e.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _subscribe() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      allItems.value = [];
      return;
    }

    _sub?.cancel();
    _sub = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        final n = NotificationModel.fromJson(data);
        return NotificationListItem(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          createdAt: n.createdAt,
          isRead: n.isRead,
        );
      }).toList();
      allItems.value = list;
    });
  }

  void setFilter(int index) => filterIndex.value = index;

  Future<void> markAsRead(String id) async {
    try {
      final item = allItems.firstWhere((e) => e.id == id);
      if (item.type == 'BADGE' && !item.isRead) HapticFeedback.mediumImpact();
    } catch (_) {}
    await _repo.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _repo.markAllAsRead(uid);
  }
}
