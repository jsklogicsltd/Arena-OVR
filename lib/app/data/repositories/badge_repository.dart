import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';
import '../models/user_model.dart';

/// All badge IDs matching asset filenames under `assets/badges/`.
class BadgeIds {
  BadgeIds._();

  // OVR headline tiers (must match athlete profile `UserModel.finalOvr`).
  static const int ovrTierCountOnMeMin = 80;
  static const int ovrTierLockedInMin = 86;
  static const int ovrTierAlphaMin = 91;
  static const int ovrTierGoldCardMin = 96;
  static const int ovrTierChampionshipMin = 99;

  // Subjective tiers
  static const String countOnMe = 'count_on_me';
  static const String lockedIn = 'locked_in';
  static const String alpha = 'alpha';
  static const String goldCard = 'gold_card';

  // Physics
  static const String truckStick = 'truck_stick';

  // Streak milestones
  static const String streak3 = 'streak_3';
  static const String streak7 = 'streak_7';
  static const String streak14 = 'streak_14';
  static const String streak21 = 'streak_21';
  static const String streak30 = 'streak_30';

  // Ultimate
  static const String championshipRing = 'championship_ring';

  static List<String> get all => [
        countOnMe,
        lockedIn,
        alpha,
        goldCard,
        truckStick,
        streak3,
        streak7,
        streak14,
        streak21,
        streak30,
        championshipRing,
      ];

  /// Headline-OVR badges only (order matches [all]).
  static const List<String> ovrHeadlineBadgeIds = [
    countOnMe,
    lockedIn,
    alpha,
    goldCard,
    championshipRing,
  ];

  /// IDs unlocked purely by overall OVR ([finalOvr]) at or above each tier floor.
  static List<String> ovrHeadlineUnlockedIds(int finalOvr) {
    final o = finalOvr.clamp(0, 99);
    final out = <String>[];
    if (o >= ovrTierCountOnMeMin) out.add(countOnMe);
    if (o >= ovrTierLockedInMin) out.add(lockedIn);
    if (o >= ovrTierAlphaMin) out.add(alpha);
    if (o >= ovrTierGoldCardMin) out.add(goldCard);
    if (o >= ovrTierChampionshipMin) out.add(championshipRing);
    return out;
  }

  /// Same Truck Stick + streak math as [BadgeRepository._evaluateBadges] (sections B–C).
  /// [data] must include the same keys as a `users/` doc: `weightLbs`, `assessmentData`, `currentStreak`.
  static List<String> streakTruckUnlockedIdsFromData(Map<String, dynamic> data) {
    final earned = <String>[];

    final weightLbs = _badgeNumVal(data, 'weightLbs');
    final blob = data['assessmentData'] is Map
        ? Map<String, dynamic>.from(data['assessmentData'] as Map)
        : <String, dynamic>{};
    final time40 = _badgeDoubleVal(blob, 'time40');

    if (weightLbs > 0 && time40 > 0) {
      final raw40 = weightLbs / (time40 * time40);
      if (raw40 >= 10.0) earned.add(truckStick);
    }

    final streak = data['currentStreak'] is Map
        ? Map<String, dynamic>.from(data['currentStreak'] as Map)
        : <String, dynamic>{};

    var maxStreak = 0;
    for (final key in streak.keys) {
      if (key.endsWith('_lastDate')) continue;
      final v = streak[key];
      if (v is int && v > maxStreak) maxStreak = v;
    }

    if (maxStreak >= 3) earned.add(streak3);
    if (maxStreak >= 7) earned.add(streak7);
    if (maxStreak >= 14) earned.add(streak14);
    if (maxStreak >= 21) earned.add(streak21);
    if (maxStreak >= 30) earned.add(streak30);

    return earned;
  }

  /// User-doc fields needed for [streakTruckUnlockedIdsFromData] (aligned with [UserModel]).
  static Map<String, dynamic> streakTruckEvalSlice(UserModel user) {
    return {
      'weightLbs': user.weightLbs,
      'assessmentData': user.assessmentData ?? <String, dynamic>{},
      'currentStreak': user.currentStreak,
    };
  }

  /// Parses legacy feed copy `Earned the Count On Me badge!` → `count_on_me`.
  static String? assetIdFromEarnedContent(String content) {
    final m = RegExp(r'Earned the (.+?) badge').firstMatch(content.trim());
    if (m == null) return null;
    final label = m.group(1)?.trim();
    if (label == null || label.isEmpty) return null;
    for (final id in all) {
      if (labelFor(id) == label) return id;
    }
    return null;
  }

  /// Trophy grid + detail screens: Firestore `badges` plus live OVR tiers + Truck/Streak from [user].
  static List<String> trophyDisplayMerge(UserModel user) {
    final merged = {
      ...user.badges,
      ...ovrHeadlineUnlockedIds(user.finalOvr),
      ...streakTruckUnlockedIdsFromData(streakTruckEvalSlice(user)),
    };
    return all.where(merged.contains).toList();
  }

  static double _badgeNumVal(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    return 0;
  }

  static double _badgeDoubleVal(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static String labelFor(String id) {
    switch (id) {
      case countOnMe:
        return 'Count On Me';
      case lockedIn:
        return 'Locked In';
      case alpha:
        return 'Alpha';
      case goldCard:
        return 'Gold Card';
      case truckStick:
        return 'Truck Stick';
      case streak3:
        return '3-Day Streak';
      case streak7:
        return '7-Day Streak';
      case streak14:
        return '14-Day Streak';
      case streak21:
        return '21-Day Streak';
      case streak30:
        return '30-Day Streak';
      case championshipRing:
        return 'Championship Ring';
      default:
        return id;
    }
  }

  static String descriptionFor(String id) {
    switch (id) {
      case countOnMe:
        return 'Overall OVR reaches $ovrTierCountOnMeMin (80–85 band)';
      case lockedIn:
        return 'Overall OVR reaches $ovrTierLockedInMin (86–90 band)';
      case alpha:
        return 'Overall OVR reaches $ovrTierAlphaMin (91–95 band)';
      case goldCard:
        return 'Overall OVR reaches $ovrTierGoldCardMin (before 99)';
      case truckStick:
        return 'Elite power-to-speed ratio';
      case streak3:
        return '3 consecutive point days';
      case streak7:
        return '7 consecutive point days';
      case streak14:
        return '14 consecutive point days';
      case streak21:
        return '21 consecutive point days';
      case streak30:
        return '30 consecutive point days';
      case championshipRing:
        return 'Earned by reaching the ultimate 99 OVR.';
      default:
        return '';
    }
  }
}

class BadgeRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  /// Evaluate all badge conditions for an athlete and award any newly earned.
  Future<List<String>> evaluateAfterPoints({
    required String athleteId,
    required String teamId,
    required String schoolId,
  }) async {
    final userDoc =
        await _provider.firestore.collection('users').doc(athleteId).get();
    if (!userDoc.exists || userDoc.data() == null) return [];

    final data = userDoc.data()!;
    final List<String> currentBadges =
        data['badges'] != null ? List<String>.from(data['badges']) : [];

    final earned = _evaluateBadges(data, athleteId);

    final toAward =
        earned.where((b) => !currentBadges.contains(b)).toList();
    if (toAward.isEmpty) return [];

    final athleteName = data['name'] as String? ?? 'Athlete';

    for (final badgeName in toAward) {
      await _awardBadge(
        athleteId: athleteId,
        athleteName: athleteName,
        teamId: teamId,
        schoolId: schoolId,
        badgeName: badgeName,
      );
    }

    return toAward;
  }

  /// Pure evaluation — returns all badge IDs the athlete qualifies for right now.
  List<String> _evaluateBadges(Map<String, dynamic> data, String athleteId) {
    final List<String> earned = [];

    final merged = Map<String, dynamic>.from(data);
    merged['uid'] = athleteId;
    final user = UserModel.fromJson(merged);
    final int displayOvr = user.finalOvr;

    // ── A. OVR headline tiers (aligned with profile / leaderboard `finalOvr`) ────
    earned.addAll(BadgeIds.ovrHeadlineUnlockedIds(displayOvr));

    earned.addAll(BadgeIds.streakTruckUnlockedIdsFromData(data));

    return earned;
  }

  Future<void> _awardBadge({
    required String athleteId,
    required String athleteName,
    required String teamId,
    required String schoolId,
    required String badgeName,
  }) async {
    final batch = _provider.firestore.batch();

    final userRef = _provider.firestore.collection('users').doc(athleteId);
    batch.update(userRef, {
      'badges': FieldValue.arrayUnion([badgeName]),
    });

    final label = BadgeIds.labelFor(badgeName);

    final feedRef = _provider.firestore.collection('feed').doc();
    batch.set(feedRef, {
      'id': feedRef.id,
      'teamId': teamId,
      'schoolId': schoolId,
      'type': 'BADGE',
      // Coach feed / dashboards show actorName — use the athlete who earned it (not "System").
      'actorName': athleteName,
      'targetName': athleteName,
      'content': 'Earned the $label badge!',
      'badgeId': badgeName,
      'isPinned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final notifRef = _provider.firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'id': notifRef.id,
      'userId': athleteId,
      'title': 'Badge Unlocked!',
      'body': 'You earned the $label badge.',
      'type': 'BADGE',
      'isRead': false,
      'relatedDocId': feedRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
