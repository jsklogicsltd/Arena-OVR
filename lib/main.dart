import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final focusScope = FocusScope.of(context);
            if (!focusScope.hasPrimaryFocus && focusScope.focusedChild != null) {
              focusScope.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}
