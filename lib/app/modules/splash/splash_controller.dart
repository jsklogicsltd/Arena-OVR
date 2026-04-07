import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';

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
          final role = doc.data()!['role'] as String?;
          final schoolId = doc.data()!['schoolId'] as String?;
          final teamId = doc.data()!['teamId'] as String?;

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
          Get.offAllNamed(Routes.INVITE_CODE);
        }
      } catch (e) {
        Get.offAllNamed(Routes.AUTH);
      }
    } else {
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
