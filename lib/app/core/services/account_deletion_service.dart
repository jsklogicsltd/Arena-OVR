import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';

/// Unified account deletion: Firestore `users/{uid}` then Firebase Auth delete.
/// Callers must pass [onSuccessCleanup] to remove permanent GetX controllers (e.g. CoachController).
class AccountDeletionService {
  AccountDeletionService._();

  static const Color _dialogBg = Color(0xFF101A24);

  /// Shows confirmation, runs deletion, then [onSuccessCleanup], navigates to auth,
  /// and runs [afterNavigation] on the next microtask (use this to [Get.delete]
  /// permanent controllers without deleting them mid-callback).
  static Future<void> confirmAndDeleteAccount({
    required Future<void> Function() onSuccessCleanup,
    void Function()? afterNavigation,
  }) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete account?',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure? This action is permanent and will wipe all your data.',
          style: GoogleFonts.inter(
            color: Colors.white70,
            height: 1.45,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return;

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A1FF)),
      ),
      barrierDismissible: false,
    );

    final result = await _deleteUserDocumentAndAuth();

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    switch (result) {
      case _DeletionResult.success:
        await onSuccessCleanup();
        Get.offAllNamed(Routes.AUTH);
        final navExtra = afterNavigation;
        if (navExtra != null) {
          Future<void>.microtask(navExtra);
        }
        Get.snackbar(
          'Account deleted',
          'Your account has been removed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      case _DeletionResult.notSignedIn:
        Get.snackbar(
          'Error',
          'You are not signed in.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
      case _DeletionResult.requiresRecentLogin:
        Get.snackbar(
          'Security check required',
          'Please sign out, sign back in, and try deleting your account again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.black87,
          duration: const Duration(seconds: 5),
        );
      case _DeletionResult.failure:
        Get.snackbar(
          'Could not delete account',
          'Something went wrong. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
    }
  }

  static Future<_DeletionResult> _deleteUserDocumentAndAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _DeletionResult.notSignedIn;

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('AccountDeletionService: Firestore user delete: $e');
    }

    try {
      await user.delete();
      await FirebaseAuth.instance.signOut();
      return _DeletionResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return _DeletionResult.requiresRecentLogin;
      }
      debugPrint('AccountDeletionService: ${e.code} ${e.message}');
      return _DeletionResult.failure;
    } catch (e) {
      debugPrint('AccountDeletionService: $e');
      return _DeletionResult.failure;
    }
  }
}

enum _DeletionResult {
  success,
  notSignedIn,
  requiresRecentLogin,
  failure,
}
