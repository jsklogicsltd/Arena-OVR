import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = userDoc.data()?['role'] as String?;

      if (role == 'coach') {
        final school = await _schoolRepo.validateInviteCode(code);
        if (school == null) {
          throw Exception("Invalid school invite code");
        }

        // Update user record with school link
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'schoolId': school.id});

        // Increment school coach counter
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .update({'coachCount': FieldValue.increment(1)});

        Get.offAllNamed(Routes.COACH);
      } else if (role == 'athlete') {
        final team = await _teamRepo.validateInviteCode(code);
        if (team == null) {
          throw Exception("Invalid team invite code");
        }

        final schoolId = team['schoolId'] as String?;

        // Update user record with team + school link
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'teamId': team['id'] ?? code,
              'schoolId': schoolId,
            });

        // Increment school athlete counter
        if (schoolId != null && schoolId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .update({'athleteCount': FieldValue.increment(1)});
        }

        Get.offAllNamed(Routes.PLAYER);
      } else {
        throw Exception("Invalid user role state");
      }
    } catch (e) {
      Get.snackbar(
        'Validation Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
