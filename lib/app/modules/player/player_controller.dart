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
import '../../core/services/ovr_engine_service.dart' show SeasonOvrUi;
import '../../scoring_engine/profile_assignment.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../feed/feed_controller.dart';
import '../settings/settings_controller.dart';

class PlayerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RatingRepository _ratingRepo = RatingRepository();

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
  final RxBool isSavingPhysical  = false.obs;

  final ImagePicker _picker = ImagePicker();

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<DocumentSnapshot>? _teamSub;
  StreamSubscription<DocumentSnapshot>? _seasonSub;

  // ── Computed ──────────────────────────────────────────────────────────────────

  int get _daysElapsed {
    final start = season.value?.startDate;
    final seasonLengthDays =
        (season.value?.seasonLengthDays ?? team.value?.seasonLengthDays ?? 15)
            .clamp(7, 365);
    if (start == null) {
      final storedDay = athlete.value?.ovrDay;
      if (storedDay != null) return storedDay.clamp(1, seasonLengthDays);
      return 1;
    }
    return SeasonOvrUi.calculateSeasonDay(
      seasonStartDate: start,
      currentDate: DateTime.now(),
      seasonLengthDays: seasonLengthDays,
    );
  }

  bool get isOvrTimingReady {
    if (athlete.value == null) return false;
    if (season.value?.startDate != null) return true;
    if (athlete.value!.ovrDay != null) return true;
    return false;
  }

  /// True when day/OVR can be shown without flipping (e.g. not ??? then number).
  /// Waits for team (if [UserModel.teamId] is set) and season (if team has [currentSeasonId])
  /// so [_daysElapsed] / visibility does not change when those streams catch up.
  bool get isOvrDisplayResolved {
    if (athlete.value == null) return false;
    final tid = athlete.value!.teamId;
    if (tid != null && tid.isNotEmpty) {
      if (team.value == null) return false;
      final sid = team.value!.currentSeasonId;
      if (sid != null && sid.isNotEmpty) {
        if (season.value == null) return false;
      }
    }
    return isOvrTimingReady;
  }

  int get revealDays {
    final total =
        (season.value?.seasonLengthDays ?? team.value?.seasonLengthDays ?? 15)
            .clamp(7, 365);
    // Client rule:
    // - Season <= 14 days: reveal after 1 day (Day 1 locked)
    // - Season >= 15 days: reveal after 2 days (Days 1-2 locked)
    return (total <= 14) ? 1 : 2;
  }

  int? get displayedOvr {
    final a = athlete.value;
    if (a == null) return null;
    final raw = a.finalOvr;
    if (_daysElapsed <= revealDays) return null; // locked window
    return math.min(raw, currentPhaseCap);
  }

  // Reveal window is dynamic based on season length (see [revealDays]).
  bool get isOvrRevealed => displayedOvr != null;
  // Full unlock starts when the athlete reaches phase 3.
  bool get isUnlocked {
    final total = (season.value?.seasonLengthDays ?? team.value?.seasonLengthDays ?? 15)
        .clamp(7, 365);
    final phase2EndDay = ((total * 2.0) / 3.0).ceil();
    return _daysElapsed > phase2EndDay;
  }

  int get currentPhaseCap {
    if (season.value?.startDate == null && athlete.value?.ovrCap != null) {
      return athlete.value!.ovrCap!.clamp(0, 99);
    }
    final total = (season.value?.seasonLengthDays ?? team.value?.seasonLengthDays ?? 15)
        .clamp(7, 365);
    final baseline =
        (season.value?.startingOvrBaseline ?? team.value?.startingOvrBaseline ?? 50)
            .clamp(0, 90);
    return SeasonOvrUi.phaseCapForDay(
      day: _daysElapsed,
      seasonLengthDays: total,
      startingOvrBaseline: baseline,
    );
  }

  String get capStatusLabel {
    final d = _daysElapsed;
    if (d <= revealDays) return 'DAY $d LOCKED';
    if (isUnlocked) return 'FULLY UNLOCKED';
    return 'CURRENT CAP: $currentPhaseCap OVR';
  }

  String get phaseName {
    final d = _daysElapsed;
    final total = (season.value?.seasonLengthDays ?? team.value?.seasonLengthDays ?? 15)
        .clamp(7, 365);
    final phase1EndDay = (total / 3.0).ceil();
    final phase2EndDay = ((total * 2.0) / 3.0).ceil();
    if (d <= revealDays) return 'DAY $d';
    if (d <= phase1EndDay) return 'PHASE 1 · DAY $d';
    if (d <= phase2EndDay) return 'PHASE 2 · DAY $d';
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
    for (final key in ['Athlete', 'Competitor', 'Student', 'Teammate', 'Citizen',
                        'Performance', 'Class', 'Program', 'Standard']) {
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
        final uid = athlete.value?.uid;
        if (uid != null && uid.isNotEmpty) {
          _loadPointHistory(uid, seasonId: season.value?.id);
        }
      }
    });
  }

  Future<void> _loadPointHistory(String uid, {String? seasonId}) async {
    try {
      pointHistory.value = await _ratingRepo.getAthleteHistory(
        uid,
        seasonId: seasonId,
      );
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
      jerseyNumber: '0',
      positionGroup: 'Quarterback',
      ovr: 92,
      rank: 1,
      previousRank: 2,
      badges: ['rising_star', 'team_player'],
      currentRating: {
        'Athlete': 38.0,
        'Student': 17.0,
        'Teammate': 14.0,
        'Citizen': 15.0,
      },
      currentStreak: {
        'Citizen': 14,
        'Citizen_lastDate': DateTime.now().toIso8601String().split('T')[0],
        'Athlete': 5,
        'Athlete_lastDate': DateTime.now().toIso8601String().split('T')[0],
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
      seasonLengthDays: 15,
      startingOvrBaseline: 50,
      createdBy: 'mock_coach',
    );
    coachName.value = 'Coach Smith';
    season.value = SeasonModel(
      id: 'mock',
      teamId: 'mock',
      schoolId: 'mock',
      seasonNumber: 1,
      startDate: DateTime.now().subtract(const Duration(days: 6)),
      seasonLengthDays: 15,
      startingOvrBaseline: 50,
      isActive: true,
    );
    pointHistory.value = _mockHistory;
    isLoading.value = false;
  }

  List<TransactionModel> get _mockHistory => [
    TransactionModel(
      id: '1', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Athlete', value: 3,
      note: 'Exceptional drive and accuracy on the final quarter.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: '2', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Citizen', value: -1,
      note: 'Late arrival to recovery session.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '3', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Teammate', value: 5,
      note: 'Strong team effort during practice.',
      type: 'RATING',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: '4', athleteId: 'mock', coachId: 'coach1',
      teamId: 'mock', schoolId: 'mock', seasonId: 'mock',
      category: 'Student', value: 2,
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
    String? rawPositionGroup,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = rawName.trim();
    final jersey = rawJerseyNumber.trim();
    final position = (rawPositionGroup ?? '').trim();
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
      final updates = <String, dynamic>{
        'name': name,
        'jerseyNumber': jersey,
        // If the user cleared the field, explicitly overwrite the old value.
        'positionGroup': position.isEmpty ? FieldValue.delete() : position,
      };
      await _firestore.collection('users').doc(uid).update(updates);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      athlete.value = athlete.value?.copyWith(
        name: name,
        jerseyNumber: jersey,
        positionGroup: position.isEmpty ? null : position,
      );
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

  /// Saves grade, height, weight and auto-computed power/speed profiles.
  Future<void> updatePhysicalProfile({
    required int grade,
    required int heightInches,
    required int weightLbs,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (grade < 7 || grade > 12) {
      Get.snackbar('Error', 'Grade must be 7–12',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white);
      return;
    }
    if (heightInches <= 0 || weightLbs <= 0) {
      Get.snackbar('Error', 'Height and weight must be positive',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white);
      return;
    }

    try {
      isSavingPhysical.value = true;

      final power =
          assignPowerProfile(heightInches, weightLbs, grade: grade);
      final speed =
          assignSpeedProfile(heightInches, weightLbs, grade: grade);

      final data = <String, dynamic>{
        'grade': grade,
        'heightInches': heightInches,
        'weightLbs': weightLbs,
        'powerProfile': power.name,
        'speedProfile': speed.name,
      };

      await _firestore.collection('users').doc(uid).update(data);

      athlete.value = athlete.value?.copyWith(
        grade: grade,
        heightInches: heightInches,
        weightLbs: weightLbs,
        powerProfile: power.name,
        speedProfile: speed.name,
      );

      Get.snackbar('Done', 'Physical profile saved — '
          '${power.name.toUpperCase()} power, '
          '${speed.name.toUpperCase()} speed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save physical profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white);
    } finally {
      isSavingPhysical.value = false;
    }
  }

  /// Stops Firestore listeners (e.g. before account deletion without full logout).
  void cancelStreams() {
    _userSub?.cancel();
    _teamSub?.cancel();
    _seasonSub?.cancel();
  }

  void logout() async {
    cancelStreams();
    await FirebaseAuth.instance.signOut();
    Get.delete<PlayerController>(force: true);
    Get.offAllNamed(Routes.AUTH);
  }
}
