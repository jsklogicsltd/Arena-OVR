import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../data/models/team_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/season_model.dart';
import '../../data/models/feed_model.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/rating_repository.dart';
import '../../data/models/challenge_catalog.dart';

class CoachController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeamRepository _teamRepo = TeamRepository();
  final RatingRepository _ratingRepo = RatingRepository();

  final RxList<TeamModel> coachTeams = <TeamModel>[].obs;
  final Rx<TeamModel?> currentTeam = Rx<TeamModel?>(null);
  final RxList<UserModel> roster = <UserModel>[].obs;
  final Rx<SeasonModel?> season = Rx<SeasonModel?>(null);
  final RxList<FeedModel> feed = <FeedModel>[].obs;
  final RxString coachName = 'Loading...'.obs;
  final RxString coachPhotoUrl = ''.obs;
  final RxBool isUploadingPhoto = false.obs;
  final RxBool isUpdatingName = false.obs;
  final RxBool isUploadingTeamLogo = false.obs;

  final ImagePicker _picker = ImagePicker();

  final RxInt selectedTab = 0.obs;

  // Guards against the Firestore snapshot transiently returning empty during
  // team switching / propagation lag. Once we've confirmed at least one team
  // exists we never send the coach back to CREATE_TEAM automatically.
  bool _hasLoadedInitialTeams = false;

  StreamSubscription? _teamsSub;
  StreamSubscription? _currentTeamSub;
  StreamSubscription? _rosterSub;
  StreamSubscription? _seasonSub;
  StreamSubscription? _feedSub;

  @override
  void onInit() {
    super.onInit();
    _loadCoachProfile();
    getCoachTeams();
  }

  Future<void> _loadCoachProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final name = data['name'] as String?;
      if (name != null && name.isNotEmpty) {
        coachName.value = name;
      }
      final photo = data['profilePicUrl'] as String?;
      if (photo != null && photo.isNotEmpty) {
        coachPhotoUrl.value = photo;
      } else {
        // Fallback to Firebase Auth photoURL
        final authPhoto = FirebaseAuth.instance.currentUser?.photoURL;
        if (authPhoto != null && authPhoto.isNotEmpty) {
          coachPhotoUrl.value = authPhoto;
        }
      }
    }
  }

  /// Pick image from gallery and upload as coach profile photo.
  Future<void> updateCoachPhoto() async {
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
      await _firestore.collection('users').doc(uid).update({'profilePicUrl': url});
      coachPhotoUrl.value = url;
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

  Future<void> updateCoachName(String rawName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = rawName.trim();
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
      await _firestore.collection('users').doc(uid).update({'name': name});
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      coachName.value = name;
      Get.snackbar(
        'Done', 'Name updated',
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

  @override
  void onClose() {
    _cancelTeamStreams();
    _teamsSub?.cancel();
    super.onClose();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  void getCoachTeams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _teamsSub?.cancel();
    _teamsSub = _firestore.collection('teams')
      .where('createdBy', isEqualTo: uid)
      .snapshots().listen((snapshot) {
        coachTeams.value = snapshot.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return TeamModel.fromJson(data);
        }).toList();

        if (coachTeams.isNotEmpty) {
          // Mark that we've confirmed teams exist — prevents any future
          // empty-snapshot transient from incorrectly redirecting.
          _hasLoadedInitialTeams = true;
          if (currentTeam.value == null) {
            _loadUserActiveTeam(uid);
          }
        } else if (!_hasLoadedInitialTeams) {
          // Only redirect to create-team on the very first load when we are
          // certain the coach has NO teams yet.
          Get.offAllNamed(Routes.CREATE_TEAM);
        }
    });
  }

  Future<void> _loadUserActiveTeam(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final String? activeId = userDoc.data()!['activeTeamId'];
      if (activeId != null && coachTeams.any((t) => t.id == activeId)) {
        switchTeam(activeId);
      } else if (coachTeams.isNotEmpty) {
        switchTeam(coachTeams.first.id);
      }
    } else if (coachTeams.isNotEmpty) {
      switchTeam(coachTeams.first.id);
    }
  }

  void switchTeam(String teamId) async {
    _loadCoachProfile(); // Ensure profile is loaded even on hot reloads
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'activeTeamId': teamId});
    }

    _cancelTeamStreams();
    // Clear reactive state immediately so UI doesn't show stale numbers
    // while new streams connect.
    roster.clear();
    feed.clear();
    season.value = null;

    _currentTeamSub = _firestore
        .collection('teams')
        .doc(teamId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        currentTeam.value = TeamModel.fromJson(data);
        
        final schoolId = currentTeam.value!.schoolId;
        if (schoolId.isNotEmpty) {
          _firestore.collection('schools').doc(schoolId).get().then((sDoc) {
            if (sDoc.exists && sDoc.data() != null) {
              final sName = sDoc.data()!['name'] as String?;
              final sInviteCode = sDoc.data()!['inviteCode'] as String?;
              if (currentTeam.value != null && currentTeam.value!.id == teamId) {
                currentTeam.value = currentTeam.value!.copyWith(
                  schoolName: sName,
                  schoolInviteCode: sInviteCode,
                );
              }
            }
          });
        }
        
        final seasonId = currentTeam.value!.currentSeasonId;
        if (seasonId != null) {
          _seasonSub?.cancel();
          _seasonSub = _firestore
              .collection('seasons')
              .doc(seasonId)
              .snapshots()
              .listen((sDoc) {
            if (sDoc.exists && sDoc.data() != null) {
              final sData = sDoc.data()!;
              sData['id'] = sDoc.id;
              season.value = SeasonModel.fromJson(sData);
            }
          }, onError: (e) {
            season.value = null;
          });
        }
      }
    }, onError: (e) {
      currentTeam.value = null;
    });

    _rosterSub = _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return UserModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.coachVisibleOvr.compareTo(a.coachVisibleOvr));
      roster.value = list;
    }, onError: (e) {
      roster.clear();
      Get.snackbar(
        'Roster error',
        'Failed to load athletes for this team.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    });

    _feedSub = _firestore
        .collection('feed')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      feed.value = snap.docs.map((d) => FeedModel.fromJson(d.data())).toList();
    }, onError: (e) {
      feed.clear();
    });
  }

  void _cancelTeamStreams() {
    _currentTeamSub?.cancel();
    _rosterSub?.cancel();
    _seasonSub?.cancel();
    _feedSub?.cancel();
  }

  Future<String> createTeam(TeamModel team) async {
    final teamId = await _teamRepo.createTeam(team);
    
    // Immediately fetch and populate the new team into coachTeams
    // so the list is warm before navigation (avoids race with Firestore snapshot)
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final newTeam = TeamModel.fromJson(data);
        // Add to coachTeams if not already there
        if (!coachTeams.any((t) => t.id == teamId)) {
          coachTeams.add(newTeam);
        }
      }
    } catch (_) {}

    switchTeam(teamId);
    return teamId;
  }

  Future<void> removePlayer(String athleteUid) async {
    await _firestore.collection('users').doc(athleteUid).update({
      'teamId': FieldValue.delete(),
    });
  }

  Future<void> updateBranding(
    String primary,
    String secondary,
    String? logoUrl, {
    String? teamName,
  }) async {
    if (currentTeam.value == null) return;
    await _teamRepo.updateTeamBranding(
      currentTeam.value!.id,
      primary,
      secondary,
      logoUrl,
      name: teamName,
    );
  }

  /// Pick a team logo from gallery, upload to Storage, update Firestore.
  /// The existing _currentTeamSub stream auto-propagates the new logoUrl everywhere.
  Future<void> updateTeamLogo() async {
    final teamId = currentTeam.value?.id;
    if (teamId == null) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null) return;
      isUploadingTeamLogo.value = true;
      final ref = FirebaseStorage.instance
          .ref()
          .child('team_logos')
          .child('$teamId.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      final team = currentTeam.value!;
      await _teamRepo.updateTeamBranding(
        teamId,
        team.primaryColor,
        team.secondaryColor,
        url,
      );
      Get.snackbar(
        'Done', 'Team logo updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error', 'Failed to update logo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isUploadingTeamLogo.value = false;
    }
  }

  Future<void> resetSeason() async {
    if (currentTeam.value == null) return;
    final teamId = currentTeam.value!.id;
    await _teamRepo.resetSeason(teamId);

    // Force-refresh local reactive state right after reset so percentage/day
    // updates immediately in UI (without waiting for stream timing).
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (teamDoc.exists && teamDoc.data() != null) {
        final tData = teamDoc.data()!;
        tData['id'] = teamDoc.id;
        currentTeam.value = TeamModel.fromJson(tData);

        final newSeasonId = currentTeam.value?.currentSeasonId;
        if (newSeasonId != null) {
          final seasonDoc = await _firestore.collection('seasons').doc(newSeasonId).get();
          if (seasonDoc.exists && seasonDoc.data() != null) {
            final sData = seasonDoc.data()!;
            sData['id'] = seasonDoc.id;
            season.value = SeasonModel.fromJson(sData);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> postAnnouncement(String content, bool pinned) async {
     if (currentTeam.value == null) return;
     final uid = FirebaseAuth.instance.currentUser?.uid;
     final feedRef = _firestore.collection('feed').doc();
     final team = currentTeam.value!;
     final coachDisplayName = coachName.value.isNotEmpty ? coachName.value : 'Coach';
     await feedRef.set({
       'id': feedRef.id,
       'teamId': team.id,
       'schoolId': team.schoolId,
       'type': 'ANNOUNCEMENT',
       'actorName': coachDisplayName,
       'actorRole': 'Head Coach',
       'targetName': 'Team',
       'content': content,
       'isPinned': pinned,
       'actorId': uid,
       'createdAt': FieldValue.serverTimestamp(),
     });
  }

  Future<void> submitPoints({
    required String athleteId,
    required String category,
    required int value,
    required String note,
    required bool isPositive,
  }) async {
    if (currentTeam.value == null || season.value == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final team = currentTeam.value!;
    await _ratingRepo.submitPoints(
      teamId: team.id,
      seasonId: season.value!.id,
      athleteId: athleteId,
      coachId: uid,
      category: category,
      value: value,
      note: note,
      isPositive: isPositive,
      schoolId: team.schoolId,
    );
  }

  Future<void> submitPointsBulk({
    required List<String> athleteIds,
    required List<CategoryAwardInput> awards,
    required String note,
  }) async {
    if (currentTeam.value == null || season.value == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final team = currentTeam.value!;
    await _ratingRepo.submitPointsBulk(
      teamId: team.id,
      seasonId: season.value!.id,
      athleteIds: athleteIds,
      coachId: uid,
      awards: awards,
      note: note,
      schoolId: team.schoolId,
    );
  }

  void logout() async {
    _cancelTeamStreams();
    _teamsSub?.cancel();
    await FirebaseAuth.instance.signOut();
    // The controller is permanent so GetX won't auto-dispose it on route change.
    // Delete it manually here so the next login session starts fresh.
    Get.delete<CoachController>(force: true);
    Get.offAllNamed(Routes.AUTH);
  }
}
