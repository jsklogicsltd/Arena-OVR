import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/firebase_auth_messages.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final emailController = TextEditingController();
  final isLoading = false.obs;

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.resetPassword(email);
      Get.snackbar('Success', 'Password reset email sent!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white);
      Get.back(); // Navigate back on success
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        firebaseAuthUserMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goBack() {
    Get.back();
  }
}
