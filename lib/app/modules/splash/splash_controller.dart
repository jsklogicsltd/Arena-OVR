import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';

String? _trimmedStringField(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v == null) return null;
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}

/// Aligns Firestore casing/whitespace with [UserModel.coachRoleValues].
String? _normalizedRoleForRouting(dynamic raw) {
  if (raw == null) return null;
  final s = raw is String ? raw.trim() : raw.toString().trim();
  if (s.isEmpty) return null;
  if (UserModel.coachRoleValues.contains(s)) return s;
  switch (s.toLowerCase()) {
    case 'coach':
      return 'coach';
    case 'head coach':
      return 'Head Coach';
    case 'assistant coach':
      return 'Assistant Coach';
    default:
      return s;
  }
}

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for the animation to finish (6.5s) + an extra long pause on READY (2.0s)
    await Future.delayed(const Duration(milliseconds: 8500));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          // Fire-and-forget: register FCM token for push notifications
          NotificationService().requestPermissionAndSaveToken(user.uid);

          final role = _normalizedRoleForRouting(data['role']);
          final schoolId = _trimmedStringField(data, 'schoolId');
          final teamId = _trimmedStringField(data, 'teamId');

          if (role == 'superadmin') {
            Get.offAllNamed(Routes.ADMIN);
          } else if (UserModel.isCoachRole(role)) {
            if (schoolId == null || schoolId.isEmpty) {
              Get.offAllNamed(Routes.INVITE_CODE);
            } else {
              Get.offAllNamed(Routes.COACH);
            }
          } else if (role == 'athlete') {
            if (teamId == null || teamId.isEmpty) {
              Get.offAllNamed(Routes.INVITE_CODE);
            } else {
              Get.offAllNamed(Routes.PLAYER);
            }
          } else {
            Get.offAllNamed(Routes.INVITE_CODE);
          }
        } else {
          // Auth user exists but Firestore doc is missing (rare crash between
          // Auth creation and Firestore write). Sign out so the user can
          // re-register cleanly without hitting "email already in use".
          Get.snackbar(
            'Profile not found',
            'There is no user profile in the database for this account. '
            'Try signing up again or contact support.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade900,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          await FirebaseAuth.instance.signOut();
          Get.offAllNamed(Routes.AUTH);
        }
      } catch (e, st) {
        debugPrint('SplashController: Firestore/read error: $e\n$st');
        Get.snackbar(
          'Could not load profile',
          kDebugMode
              ? e.toString()
              : 'Check your internet connection and try again. '
                  'If this persists, Firestore rules or your user document may need attention.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        Get.offAllNamed(Routes.AUTH);
      }
    } else {
      debugPrint(
        'SplashController: currentUser was null after splash delay — '
        'session not restored. Likely auth persistence or a very fast sign-out.',
      );
      Get.snackbar(
        'Signed out',
        'Your session was not available after startup. Try logging in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.deepPurple.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
