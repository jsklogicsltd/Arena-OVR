import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

/// Maps [FirebaseAuthException.code] to copy suitable for snackbars (no `[firebase_auth/...]` noise).
String _userFacingFirebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Invalid email or password. Please try again.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    default:
      return 'An unexpected error occurred. Please try again later.';
  }
}

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
        _userFacingFirebaseAuthMessage(e),
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
        _userFacingFirebaseAuthMessage(e),
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