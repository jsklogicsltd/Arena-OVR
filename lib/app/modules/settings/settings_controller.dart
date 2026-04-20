import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/account_deletion_service.dart';
import '../../core/utils/change_password_helper.dart';
import '../player/player_controller.dart';

class SettingsController extends GetxController {
  final RxBool pushNotifications = true.obs;
  final RxBool hapticFeedback = false.obs;

  void togglePushNotifications(bool value) => pushNotifications.value = value;
  void toggleHapticFeedback(bool value) => hapticFeedback.value = value;

  void changePassword(BuildContext context) {
    ChangePasswordHelper.show(context);
  }

  Future<void> deleteAccount() async {
    await AccountDeletionService.confirmAndDeleteAccount(
      onSuccessCleanup: () async {
        if (Get.isRegistered<PlayerController>()) {
          Get.find<PlayerController>().cancelStreams();
        }
      },
      afterNavigation: () {
        if (Get.isRegistered<PlayerController>()) {
          Get.delete<PlayerController>(force: true);
        }
      },
    );
  }
}
