import 'package:get/get.dart';
import '../../data/repositories/badge_repository.dart';
import '../player/player_controller.dart';

class BadgesController extends GetxController {
  List<String> get allBadgeIds => BadgeIds.all;

  List<String> get earnedBadgeIds {
    try {
      final athlete = Get.find<PlayerController>().athlete.value;
      return athlete?.badges ?? [];
    } catch (_) {
      return [];
    }
  }

  String labelFor(String badgeId) => BadgeIds.labelFor(badgeId);
  String descriptionFor(String badgeId) => BadgeIds.descriptionFor(badgeId);
}
