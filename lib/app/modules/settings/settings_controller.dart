import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxBool pushNotifications = true.obs;
  final RxBool hapticFeedback = false.obs;

  void togglePushNotifications(bool value) => pushNotifications.value = value;
  void toggleHapticFeedback(bool value) => hapticFeedback.value = value;

  void changePassword() {
    // TODO: Navigate to change password screen
  }

  void deleteAccount() {
    // TODO: Show confirmation and delete account
  }
}
