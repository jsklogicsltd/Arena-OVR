import 'package:firebase_auth/firebase_auth.dart';

/// Maps [FirebaseAuthException.code] to a clean, user-facing message.
///
/// This intentionally avoids showing raw exception strings like:
/// `[firebase_auth/invalid-credential] ...`
String firebaseAuthUserMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password': // older SDKs
    case 'user-not-found': // older SDKs
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

