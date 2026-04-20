import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'components/video_background.dart';
import 'app/core/services/notification_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/theme_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  NotificationService();
  Get.put(ThemeController());
  runApp(
    GetMaterialApp(
      title: "Arena Ovr",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: Routes.SPLASH,
      getPages: AppPages.pages,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const VideoBackdrop(),
            Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  final focusScope = FocusScope.of(context);
                  if (!focusScope.hasPrimaryFocus &&
                      focusScope.focusedChild != null) {
                    focusScope.unfocus();
                  }
                },
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    ),
  );
}
