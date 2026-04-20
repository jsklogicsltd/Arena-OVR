import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _foregroundListenerAttached = false;



  /// Request push-notification permissions (required on iOS / macOS),
  /// retrieve the FCM device token, and persist it to the user's
  /// Firestore document so the backend Cloud Function can target it.
  Future<void> requestPermissionAndSaveToken(String userId) async {
    if (userId.isEmpty) return;
    await Firebase.initializeApp();

    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_foregroundListenerAttached) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
          '🔥 FOREGROUND MESSAGE RECEIVED: ${message.notification?.title}',
        );
      });
      _foregroundListenerAttached = true;
    }

    // ====== 🛑 YAHAN HUMNE CHECKS ADD KIYE HAIN ======
    String? apnsToken = await _messaging.getAPNSToken();
    print("🍎 APPLE APNs Token: $apnsToken");

    final token = await _messaging.getToken();
    print("🔥 FIREBASE FCM Token: $token");
    // ==================================================

    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
    });
  }
}
