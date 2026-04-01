import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  final isLoading = false.obs;

  // 'ADMIN', 'COACH', 'PLAYER'
  final selectedRole = Rxn<String>();
  final showAdminOption = false.obs;

  // Profile picture
  final selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _checkSuperadminExists();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }

  Future<void> _checkSuperadminExists() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'superadmin')
          .limit(1)
          .get();
      showAdminOption.value = snapshot.docs.isEmpty;
    } catch (e) {
      showAdminOption.value = false;
    }
  }

  void selectRole(String role) {
    selectedRole.value = role;
  }

  Future<void> pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked != null) {
        selectedImage.value = File(picked.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();
      Get.snackbar('Error', 'Please fill in all fields',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      // Keep focus deterministic on mismatch to avoid visual multi-cursor glitches.
      passwordFocusNode.unfocus();
      confirmPasswordFocusNode.requestFocus();
      Get.snackbar('Error', 'Passwords do not match',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    if (selectedRole.value == null) {
      Get.snackbar('Error', 'Please select your role',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final credential = await _authRepo.signUp(
        emailController.text.trim(),
        passwordController.text,
      );

      final uid = credential.user!.uid;
      final roleDbValue = selectedRole.value == 'ADMIN'
          ? 'superadmin'
          : (selectedRole.value == 'COACH' ? 'coach' : 'athlete');

      // Upload profile picture if selected
      String? profilePicUrl;
      if (selectedImage.value != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('$uid.jpg');
        await ref.putFile(selectedImage.value!);
        profilePicUrl = await ref.getDownloadURL();

        // Also update Firebase Auth photoURL
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(profilePicUrl);
      }

      // Save user doc
      final userData = <String, dynamic>{
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': roleDbValue,
        'createdAt': FieldValue.serverTimestamp(),
        'hasUploadedPic': profilePicUrl != null,
      };
      // New athlete baseline OVR should start at 50 (not 0).
      if (roleDbValue == 'athlete') {
        userData['ovr'] = 50;
        userData['actualOvr'] = 50;
        userData['ovrDay'] = null;
        userData['ovrCap'] = null;
      }
      if (profilePicUrl != null) {
        userData['profilePicUrl'] = profilePicUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      if (roleDbValue == 'superadmin') {
        Get.offAllNamed(Routes.ADMIN);
      } else {
        Get.offAllNamed(Routes.INVITE_CODE);
      }
    } catch (e) {
      Get.snackbar('Signup Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToSignIn() {
    Get.back();
  }
}
