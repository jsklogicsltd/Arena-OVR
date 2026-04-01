import 'package:get/get.dart';
import '../../data/repositories/badge_repository.dart';
import '../player/player_controller.dart';

/// Exposes badge definitions and current user's earned badges for the badges view.
class BadgesController extends GetxController {
  final BadgeRepository _badgeRepo = BadgeRepository();

  List<String> get allBadgeIds => BadgeIds.all;

  /// Current athlete's earned badges (from PlayerController when on player flow).
  List<String> get earnedBadgeIds {
    try {
      final athlete = Get.find<PlayerController>().athlete.value;
      return athlete?.badges ?? [];
    } catch (_) {
      return [];
    }
  }

  String descriptionFor(String badgeId) {
    switch (badgeId) {
      case BadgeIds.firstStep:
        return 'First point award';
      case BadgeIds.risingStar:
        return 'OVR ≥ 25';
      case BadgeIds.ironWill:
        return 'Standard ≥ 20';
      case BadgeIds.mvpContender:
        return 'OVR ≥ 75';
      case BadgeIds.ovr90Club:
        return 'OVR ≥ 90';
      default:
        return '';
    }
  }
}