import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a confirmation dialog and sends a Firebase password-reset email
/// for the currently signed-in user.
///
/// Call from any settings screen:
/// ```dart
/// ChangePasswordHelper.show(context);
/// ```
class ChangePasswordHelper {
  ChangePasswordHelper._();

  static Future<void> show(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'No email address associated with this account.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF00A1FF), size: 22),
            const SizedBox(width: 10),
            Text(
              'Change Password',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ll send a password reset link to:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00A1FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00A1FF).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                email,
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00A1FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check your inbox and follow the link to set a new password.',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A1FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Send Reset Email',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Email Sent',
        'Password reset link sent to $email. Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Failed to Send',
        _errorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Failed to Send',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    }
  }

  static String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return e.message ?? 'Failed to send password reset email.';
    }
  }
}
