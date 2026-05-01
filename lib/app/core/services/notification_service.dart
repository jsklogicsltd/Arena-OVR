import 'dart:developer';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  /// Channel id MUST match the value of
  /// `com.google.firebase.messaging.default_notification_channel_id`
  /// declared in `android/app/src/main/AndroidManifest.xml`.
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        'arena_ovr_default_channel',
        'Arena OVR Notifications',
        description: 'Coach announcements, points, and reminders',
        importance: Importance.high,
      );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _foregroundListenerAttached = false;
  bool _channelCreated = false;

  /// Creates the FCM default channel on Android so heads-up banners display
  /// correctly on Android 8+ (Oreo). No-op on iOS and on subsequent calls.
  Future<void> _ensureAndroidChannel() async {
    if (!Platform.isAndroid || _channelCreated) return;
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultChannel);
    _channelCreated = true;
  }

  /// Request push-notification permissions (iOS + Android 13+),
  /// retrieve the FCM device token, and persist it to the user's
  /// Firestore document so the backend Cloud Function can target it.
  Future<void> requestPermissionAndSaveToken(String userId) async {
    if (userId.isEmpty) return;
    await Firebase.initializeApp();

    // `requestPermission` is unified: on iOS it shows the native prompt; on
    // Android 13+ it surfaces the POST_NOTIFICATIONS runtime dialog; on
    // Android <= 12 it is a no-op and returns authorized.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await _ensureAndroidChannel();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    if (!_foregroundListenerAttached) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // iOS shows the banner natively via setForegroundNotificationPresentationOptions.
        // Hook here if you later want to mirror to a local notification on Android
        // for foreground display consistency.
        log('🔥 FOREGROUND MESSAGE RECEIVED: ${message.notification?.title}');
      });
      _foregroundListenerAttached = true;
    }

    if (Platform.isIOS) {
      final apnsToken = await _messaging.getAPNSToken();
      log('🍎 APPLE APNs Token: $apnsToken');
    }

    final token = await _messaging.getToken();
    log('🔥 FIREBASE FCM Token: $token');

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
