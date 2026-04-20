import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/firebase_auth_messages.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isLoading = false.obs;

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white);
      return;
    }
    
    isLoading.value = true;
    try {
      await _authRepo.signIn(emailController.text.trim(), passwordController.text);
      Get.offAllNamed(Routes.SPLASH);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        firebaseAuthUserMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Login Failed',
        'An unexpected error occurred. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToSignUp() {
    Get.toNamed(Routes.SIGNUP);
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your email address first', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white);
      return;
    }
    try {
      await _authRepo.resetPassword(emailController.text.trim());
      Get.snackbar('Success', 'Password reset email sent', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white);
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
    }
  }
}