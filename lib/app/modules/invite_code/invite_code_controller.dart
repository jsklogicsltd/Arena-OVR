import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../routes/app_routes.dart';

class InviteCodeController extends GetxController {
  final SchoolRepository _schoolRepo = SchoolRepository();
  final TeamRepository _teamRepo = TeamRepository();

  final codeController = TextEditingController();
  late final PinInputController pinInputController;
  final isLoading = false.obs;
  final userRole = ''.obs;
  final RxInt _clearTrigger = 0.obs;
  int get clearTrigger => _clearTrigger.value;

  /// Coach-only: 0 = Create Team (school code), 1 = Join Team (team code).
  final coachOnboardingSegment = 0.obs;

  @override
  void onInit() {
    super.onInit();
    pinInputController = PinInputController(textController: codeController);
    _loadUserRole();
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          userRole.value = doc.data()?['role'] ?? '';
        }
      } catch (e) {
        // Ignored
      }
    }
  }

  void clearCode() {
    pinInputController.clear();
    _clearTrigger.value++;
  }

  Future<void> joinTeam() async {
    final code = codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter a valid 6-character code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = userDoc.data()?['role'] as String?;

      if (UserModel.isCoachRole(role)) {
        if (coachOnboardingSegment.value == 0) {
          await _pathCreateTeamSchoolCode(user, code);
        } else {
          await _pathJoinTeamCode(user, code);
        }
      } else if (role == 'athlete') {
        final team = await _teamRepo.validateInviteCode(code);
        if (team == null) {
          throw Exception('Invalid team invite code');
        }

        final schoolId = team['schoolId'] as String?;
        final baseline =
            ((team['startingOvrBaseline'] ?? 50) as num).toInt().clamp(0, 90);

        // ── Athlete-limit guard ─────────────────────────────────────────
        if (schoolId != null && schoolId.isNotEmpty) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
          final maxAthletes =
              (schoolDoc.data()?['maxAthletesLimit'] as num?)?.toInt() ?? 60;
          final currentAthletes = await FirebaseFirestore.instance
              .collection('users')
              .where('schoolId', isEqualTo: schoolId)
              .where('role', isEqualTo: 'athlete')
              .count()
              .get();
          if ((currentAthletes.count ?? 0) >= maxAthletes) {
            throw Exception(
              'School roster is full. Limit of $maxAthletes athletes reached.',
            );
          }
        }
        // ── End athlete-limit guard ─────────────────────────────────────

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'teamId': team['id'] ?? code,
          'schoolId': schoolId,
          'ovr': baseline,
          'actualOvr': baseline,
          'finalOvr': baseline,
        });

        if (schoolId != null && schoolId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .update({'athleteCount': FieldValue.increment(1)});
        }

        Get.offAllNamed(Routes.PLAYER);
      } else {
        throw Exception('Invalid user role state');
      }
    } catch (e) {
      Get.snackbar(
        'Validation Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// PATH A — School code → roster / create team flow (`CreateTeamView`).
  Future<void> _pathCreateTeamSchoolCode(User user, String code) async {
    final school = await _schoolRepo.validateInviteCode(code);
    if (school == null || school.id.isEmpty) {
      throw Exception('Invalid school access code');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'schoolId': school.id,
      'role': 'Head Coach',
    });

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .update({'coachCount': FieldValue.increment(1)});

    Get.snackbar(
      'School verified',
      'Create your team to continue.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    Get.offAllNamed(Routes.CREATE_TEAM);
  }

  /// PATH B — Team code → attach coach to existing team → dashboard.
  Future<void> _pathJoinTeamCode(User user, String code) async {
    final team = await _teamRepo.validateInviteCode(code);
    if (team == null) {
      throw Exception('Invalid team access code');
    }

    final teamId = team['id'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw Exception('Team record is missing an id');
    }

    final priorUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final alreadyLinked = List<String>.from(
      priorUser.data()?['teamIds'] ?? const <dynamic>[],
    );
    if (alreadyLinked.contains(teamId)) {
      Get.snackbar(
        'Already joined',
        'Opening your coach dashboard.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.COACH);
      return;
    }

    final schoolId = team['schoolId'] as String?;
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('Team is not linked to a school');
    }

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);
    final schoolRef =
        FirebaseFirestore.instance.collection('schools').doc(schoolId);

    batch.update(userRef, {
      'schoolId': schoolId,
      'teamIds': FieldValue.arrayUnion([teamId]),
      'activeTeamId': teamId,
      'role': 'Assistant Coach',
    });

    batch.update(teamRef, {
      'coachIds': FieldValue.arrayUnion([user.uid]),
    });

    batch.update(schoolRef, {
      'coachCount': FieldValue.increment(1),
    });

    await batch.commit();

    Get.snackbar(
      'Welcome',
      'You\'ve joined the team dashboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    Get.offAllNamed(Routes.COACH);
  }
}
