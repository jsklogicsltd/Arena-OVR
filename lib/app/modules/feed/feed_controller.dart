import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/feed_model.dart';
import '../player/player_controller.dart';
import '../coach/coach_controller.dart';

/// Feed stream + pagination: first 20 from stream, load more on scroll (20 per page).
class FeedController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 20;

  final Rxn<FeedModel> pinnedItem = Rxn<FeedModel>();
  final RxList<FeedModel> feed = <FeedModel>[].obs;
  final RxList<FeedModel> moreItems = <FeedModel>[].obs;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  StreamSubscription? _pinnedSub;
  StreamSubscription? _feedSub;
  DocumentSnapshot? _lastDoc;

  @override
  void onInit() {
    super.onInit();
    _subscribeToFeed();
    try {
      ever(Get.find<PlayerController>().athlete, (_) => _subscribeToFeed());
    } catch (_) {}
    try {
      ever(Get.find<CoachController>().currentTeam, (_) => _subscribeToFeed());
    } catch (_) {}
  }

  @override
  void onClose() {
    _pinnedSub?.cancel();
    _feedSub?.cancel();
    super.onClose();
  }

  String? get _teamId {
    try {
      final t = Get.find<PlayerController>().athlete.value?.teamId;
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    try {
      final t = Get.find<CoachController>().currentTeam.value?.id;
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    return null;
  }

  void _subscribeToFeed() {
    final teamId = _teamId;
    if (teamId == null || teamId.isEmpty) {
      pinnedItem.value = null;
      feed.clear();
      moreItems.clear();
      _lastDoc = null;
      hasMore.value = true;
      return;
    }

    _pinnedSub?.cancel();
    _feedSub?.cancel();

    _pinnedSub = _firestore
        .collection('feed')
        .where('teamId', isEqualTo: teamId)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) {
        pinnedItem.value = null;
        return;
      }
      final d = snap.docs.first;
      final data = d.data();
      data['id'] = data['id'] ?? d.id;
      pinnedItem.value = FeedModel.fromJson(data);
    });

    _feedSub = _firestore
        .collection('feed')
        .where('teamId', isEqualTo: teamId)
        .where('isPinned', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots()
        .listen((snap) {
      feed.value = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        return FeedModel.fromJson(data);
      }).toList();
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore.value = snap.docs.length >= pageSize;
    });

    moreItems.clear();
    hasMore.value = true;
  }

  /// Load next [pageSize] items. Call when user scrolls near bottom.
  Future<void> loadMore() async {
    final teamId = _teamId;
    if (teamId == null || _lastDoc == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final snap = await _firestore
          .collection('feed')
          .where('teamId', isEqualTo: teamId)
          .where('isPinned', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(pageSize)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        return FeedModel.fromJson(data);
      }).toList();

      moreItems.addAll(list);
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      hasMore.value = snap.docs.length >= pageSize;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// All items to display: [pinned] + [feed] + [moreItems]. Pinned is not included in feed/moreItems.
  List<FeedModel> get displayedItems {
    final list = <FeedModel>[];
    final pinned = pinnedItem.value;
    if (pinned != null) list.add(pinned);
    list.addAll(feed);
    list.addAll(moreItems);
    return list;
  }
}
