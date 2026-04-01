import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/season_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/rating_repository.dart';
import '../../core/services/ovr_engine_service.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../feed/feed_controller.dart';
import '../settings/settings_controller.dart';

class PlayerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RatingRepository _ratingRepo = RatingRepository();
  final OvrEngineService _ovrEngine = OvrEngineService();

  // ── Observables ───────────────────────────────────────────────────────────────
  final Rx<UserModel?> athlete     = Rx<UserModel?>(null);
  final Rx<TeamModel?> team        = Rx<TeamModel?>(null);
  final Rx<SeasonModel?> season    = Rx<SeasonModel?>(null);
  final Rx<String?> coachName     = Rx<String?>(null);
  final RxList<TransactionModel> pointHistory = <TransactionModel>[].obs;

  final RxBool isLoading         = true.obs;
  final RxBool isUsingMockData   = false.obs;
  final RxInt  selectedTab       = 0.obs;
  final RxBool isUploadingPhoto  = false.obs;
  final RxBool isUpdatingName    = false.obs;

  final ImagePicker _picker = ImagePicker();

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<DocumentSnapshot>? _teamSub;
  StreamSubscription<DocumentSnapshot>? _seasonSub;

  // ── Computed ──────────────────────────────────────────────────────────────────

  int get _daysElapsed {
    final start = season.value?.startDate;
    if (start == null) {
      final storedDay = athlete.value?.ovrDay;
      if (storedDay != null) return storedDay.clamp(1, 15);
      return 1;
    }
    return _ovrEngine.calculateSeasonDay(
      seasonStartDate: start,
      currentDate: DateTime.now(),
    );
  }

  bool get isOvrTimingReady {
    if (season.value?.startDate != null) return true;
    if (athlete.value?.ovrDay != null) return true;
    return false;
  }

  int? get displayedOvr {
    final raw = athlete.value?.actualOvr ?? athlete.value?.ovr;
    if (raw == null) return null;
    if (_daysElapsed <= 1) return null; // Day 1 locked
    return math.min(raw, currentPhaseCap);
  }

  // New rule: Day 1 hidden, Day 2+ revealed.
  bool get isOvrRevealed => displayedOvr != null;
  // Full unlock starts at day 9 (cap becomes 99).
  bool get isUnlocked => _daysElapsed >= 9;

  int get currentPhaseCap {
    if (season.value?.startDate == null && athlete.value?.ovrCap != null) {
      return athlete.value!.ovrCap!.clamp(0, 99);
    }
    return _ovrEngine.capForDay(_daysElapsed);
  }

  String get capStatusLabel {
    final d = _daysElapsed;
    if (d == 1) return 'DAY 1 LOCKED';
    if (d >= 9) return 'FULLY UNLOCKED';
    return 'CURRENT CAP: $currentPhaseCap OVR';
  }

  String get phaseName {
    final d = _daysElapsed;
    if (d == 1) return 'DAY 1';
    if (d <= 8) return 'DAY $d';
    return 'UNLOCKED';
  }

  int get ovrDelta {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return pointHistory
        .where((t) => t.createdAt != null && t.createdAt!.isAfter(cutoff))
        .fold<int>(0, (total, t) => total + t.value);
  }

  String get bestStreakLabel {
    final streak = athlete.value?.currentStreak ?? {};
    if (streak.isEmpty) return '';
    int maxVal = 0;
    String bestKey = '';
    for (final key in ['Performance', 'Class', 'Program', 'Standard']) {
      final v = streak[key];
      if (v is int && v > maxVal) {
        maxVal = v;
        bestKey = key;
      }
    }
    if (maxVal == 0 || bestKey.isEmpty) return '';
    return '$maxVal-DAY ${_catLabel(bestKey).toUpperCase()} STREAK';
  }

  String _catLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'class':
      case 'classroom': return 'Classroom';
      case 'program':   return 'Program';
      case 'standard':  return 'Standard';
      default:          return cat;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    Get.lazyPut<LeaderboardController>(() => LeaderboardController());
    Get.lazyPut<FeedController>(() => FeedController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    _initStreams();
  }

  @override
  void onClose() {
    _userSub?.cancel();
    _teamSub?.cancel();
    _seasonSub?.cancel();
    super.onClose();
  }

  // ── Firebase Streams ──────────────────────────────────────────────────────────

  void _initStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _loadMockData();
      return;
    }
    isLoading.value = true;
    _userSub = _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['uid'] = doc.id;
          athlete.value = UserModel.fromJson(data);
          final teamId = athlete.value!.teamId;
          if (teamId != null) _subscribeToTeam(teamId);
          _loadPointHistory(uid);
          isLoading.value     = false;
          isUsingMockData.value = false;
        } else {
          _loadMockData();
        }
      },
      onError: (_) => _loadMockData(),
    );
  }

  void _subscribeToTeam(String teamId) {
    _teamSub?.cancel();
    _teamSub = _firestore.collection('teams').doc(teamId).snapshots().listen((doc) async {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        team.value = TeamModel.fromJson(data);
        final sid = team.value!.currentSeasonId;
        if (sid != null) _subscribeToSeason(sid);
        final createdBy = team.value!.createdBy;
        if (createdBy.isNotEmpty) _fetchCoachName(createdBy);
        final schoolId = team.value!.schoolId;
        if (schoolId.isNotEmpty && (team.value!.schoolName == null || team.value!.schoolName!.isEmpty)) {
          _fetchSchoolName(schoolId);
        }
      }
    });
  }

  Future<void> _fetchCoachName(String coachUid) async {
    try {
      final doc = await _firestore.collection('users').doc(coachUid).get();
      if (doc.exists && doc.data() != null) {
        coachName.value = doc.data()!['name'] as String?;
      }
    } catch (_) {
      coachName.value = null;
    }
  }

  Future<void> _fetchSchoolName(String schoolId) async {
    try {
      final doc = await _firestore.collection('schools').doc(schoolId).get();
      if (doc.exists && doc.data() != null) {
        final sName = doc.data()!['name'] as String?;
        if (team.value != null && team.value!.schoolId == schoolId && sName != null) {
          team.value = team.value!.copyWith(schoolName: sName);
        }
      }
    } catch (_) {}
  }

  void _subscribeToSeason(String seasonId) {
    _seasonSub?.cancel();
    _seasonSub = _firestore.collection('seasons').doc(seasonId).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        season.value = SeasonModel.fromJson(data);
      }
    });
  }

  Future<void> _loadPointHistory(String uid) async {
    try {
      pointHistory.value = await _ratingRepo.getAthleteHistory(uid);
    } catch (_) {
      if (isUsingMockData.value) pointHistory.value = _mockHistory;
    }
  }

  // ── Mock Data ─────────────────────────────────────────────────────────────────

  void _loadMockData() {
    isUsingMockData.value = true;
    athlete.value = UserModel(
      uid: 'mock',
      email: 'marcus@example.com',
      name: 'Marcus Johnson',
      role: 'athlete',
      jerseyNumber: '7',
      positionGroup: 'Quarterback',
      ovr: 92,
      rank: 1,
      previousRank: 2,
      badges: ['rising_star', 'team_player'],
      currentRating: {
        'Performance': 38.0,
        'Class': 17.0,
        'Program': 14.0,
        'Standard': 15.0,
      },
      currentStreak: {
        'Standard': 14,
        'Standard_lastDate': DateTime.now().toIso8601String().split('T')[0],
        'Performance': 5,
        'Performance_lastDate': DateTime.now().toIso8601String().split('T')[0],
      },
    );
    team.value = TeamModel(
      id: 'mock',
      schoolId: 'mock',
      schoolName: 'Lincoln High School',
      schoolInviteCode: 'MOCK01',
      name: 'Eagles Football',
      teamCode: 'EAG001',
      isActive: true,
      primaryColor: '#00A3FF',
      secondaryColor: '#FFB800',
      createdBy: 'mock_coach',
    );
    coachName.value = 'Coach Smith';
    season.value = SeasonModel(
      id: 'mock',
      teamId: 'mock',
      schoolId: 'mock',
      seasonNumber: 1,
      startDate: DateTime.now().subtract(const Duration(days: 6)),
      isActive: true,
    );
    pointHistory.value = _mockHistory;
    isLoading.value = false;
  }

  List<TransactionModel> get _mockHistory => [
    TransactionModel(
      id: '1', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Performance', value: 3,
      note: 'Exceptional drive and accuracy on the final quarter.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: '2', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Standard', value: -1,
      note: 'Late arrival to recovery session.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '3', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Program', value: 5,
      note: 'Strong team effort during practice.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: '4', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Class', value: 2,
      note: 'Perfect attendance this week.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // ── Actions ───────────────────────────────────────────────────────────────────

  void changeTab(int index) => selectedTab.value = index;

  /// Pick an image from the gallery, upload to Storage, update Firestore.
  /// The real-time _userSub stream auto-propagates the new URL everywhere.
  Future<void> updatePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null) return;
      isUploadingPhoto.value = true;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      // Update Firestore — the _userSub stream will pick this up and refresh
      // athlete.value automatically everywhere in the app.
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'profilePicUrl': url});
      Get.snackbar(
        'Done', 'Profile photo updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error', 'Failed to update photo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> updateAthleteProfile({
    required String rawName,
    required String rawJerseyNumber,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = rawName.trim();
    final jersey = rawJerseyNumber.trim();
    if (uid == null) return;
    if (name.isEmpty) {
      Get.snackbar(
        'Error', 'Name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isUpdatingName.value = true;
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'jerseyNumber': jersey,
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      athlete.value = athlete.value?.copyWith(name: name, jerseyNumber: jersey);
      Get.snackbar(
        'Done', 'Profile updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error', 'Failed to update name: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isUpdatingName.value = false;
    }
  }

  void logout() async {
    _userSub?.cancel();
    _teamSub?.cancel();
    _seasonSub?.cancel();
    await FirebaseAuth.instance.signOut();
    Get.delete<PlayerController>(force: true);
    Get.offAllNamed(Routes.AUTH);
  }
}
