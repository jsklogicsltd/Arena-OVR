import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';

/// All badge IDs matching asset filenames under `assets/badges/`.
class BadgeIds {
  BadgeIds._();

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
        return 'All 4 categories ≥ 80';
      case lockedIn:
        return 'All 4 categories ≥ 85';
      case alpha:
        return 'All 4 categories ≥ 90';
      case goldCard:
        return 'All 4 categories ≥ 95';
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

    final earned = _evaluateBadges(data);

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
  List<String> _evaluateBadges(Map<String, dynamic> data) {
    final List<String> earned = [];

    final rating = data['currentRating'] is Map
        ? Map<String, dynamic>.from(data['currentRating'] as Map)
        : <String, dynamic>{};

    // ── A. Subjective tier badges ──────────────────────────────────────────────
    final comp = _ratingVal(rating, 'Athlete') +
        _ratingVal(rating, 'Competitor') +
        _ratingVal(rating, 'Performance');
    final stu =
        _ratingVal(rating, 'Student') + _ratingVal(rating, 'Class');
    final tm =
        _ratingVal(rating, 'Teammate') + _ratingVal(rating, 'Program');
    final cit =
        _ratingVal(rating, 'Citizen') + _ratingVal(rating, 'Standard');

    final minSubjective = [comp, stu, tm, cit].reduce(math.min);

    if (minSubjective >= 80) earned.add(BadgeIds.countOnMe);
    if (minSubjective >= 85) earned.add(BadgeIds.lockedIn);
    if (minSubjective >= 90) earned.add(BadgeIds.alpha);
    if (minSubjective >= 95) earned.add(BadgeIds.goldCard);

    // ── B. Truck Stick (physics) ───────────────────────────────────────────────
    final weightLbs = _numVal(data, 'weightLbs');
    final blob = data['assessmentData'] is Map
        ? Map<String, dynamic>.from(data['assessmentData'] as Map)
        : <String, dynamic>{};
    final time40 = _doubleVal(blob, 'time40');

    if (weightLbs > 0 && time40 > 0) {
      final raw40 = weightLbs / (time40 * time40);
      if (raw40 >= 10.0) earned.add(BadgeIds.truckStick);
    }

    // ── C. Streak badges ───────────────────────────────────────────────────────
    final streak = data['currentStreak'] is Map
        ? Map<String, dynamic>.from(data['currentStreak'] as Map)
        : <String, dynamic>{};

    int maxStreak = 0;
    for (final key in streak.keys) {
      if (key.endsWith('_lastDate')) continue;
      final v = streak[key];
      if (v is int && v > maxStreak) maxStreak = v;
    }

    if (maxStreak >= 3) earned.add(BadgeIds.streak3);
    if (maxStreak >= 7) earned.add(BadgeIds.streak7);
    if (maxStreak >= 14) earned.add(BadgeIds.streak14);
    if (maxStreak >= 21) earned.add(BadgeIds.streak21);
    if (maxStreak >= 30) earned.add(BadgeIds.streak30);

    // ── D. Ultimate 99 OVR badge ───────────────────────────────────────────────
    // Uses the same OVR fields as the app: prefer finalOvr (curve), then actualOvr, then ovr.
    final int finalOvr = (data['finalOvr'] as num?)?.toInt() ?? 0;
    final int actualOvr = (data['actualOvr'] as num?)?.toInt() ?? 0;
    final int manualOvr = (data['ovr'] as num?)?.toInt() ?? 0;
    final int currentOvr = (finalOvr > 0 ? finalOvr : (actualOvr > 0 ? actualOvr : manualOvr));
    if (currentOvr >= 99) earned.add(BadgeIds.championshipRing);

    return earned;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────────

  double _ratingVal(Map<String, dynamic> rating, String key) {
    final v = rating[key];
    if (v is num) return v.toDouble();
    return 0;
  }

  double _numVal(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    return 0;
  }

  double _doubleVal(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
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
      'actorName': 'System',
      'targetName': athleteName,
      'content': 'Earned the $label badge!',
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
