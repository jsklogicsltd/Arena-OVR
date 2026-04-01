import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_model.dart';
import '../models/notification_model.dart';
import '../providers/firebase_provider.dart';

/// Badge IDs matching app copy.
class BadgeIds {
  static const String firstStep = 'First Step';
  static const String risingStar = 'Rising Star';
  static const String ironWill = 'Iron Will';
  static const String mvpContender = 'MVP Contender';
  static const String ovr90Club = 'OVR 90 Club';

  static List<String> get all => [firstStep, risingStar, ironWill, mvpContender, ovr90Club];
}

/// Defines conditions and evaluates badges after point transaction.
/// When earned: adds to user, creates feed + notification.
class BadgeRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  /// Evaluate and award any newly earned badges after OVR has been recalculated.
  /// Call from RatingRepository after recalculateOvr(teamId, seasonId).
  Future<List<String>> evaluateAfterPoints({
    required String athleteId,
    required String teamId,
    required String schoolId,
  }) async {
    final userDoc = await _provider.firestore.collection('users').doc(athleteId).get();
    if (!userDoc.exists || userDoc.data() == null) return [];

    final data = userDoc.data()!;
    final List<String> currentBadges = data['badges'] != null
        ? List<String>.from(data['badges'])
        : [];
    final int ovr = data['ovr'] is int
        ? data['ovr'] as int
        : (data['ovr'] as num?)?.toInt() ?? 0;
    final Map<String, dynamic> currentRating = data['currentRating'] != null
        ? Map<String, dynamic>.from(data['currentRating'])
        : {};

    final double std = _getRatingValue(currentRating, 'Standard');

    // Transaction count for First Step (first rating ever for this athlete in this team/season)
    final txSnap = await _provider.firestore
        .collection('transactions')
        .where('athleteId', isEqualTo: athleteId)
        .where('teamId', isEqualTo: teamId)
        .get();
    final bool isFirstTransaction = txSnap.docs.length == 1; // first rating for this athlete

    final List<String> toAward = [];

    if (!currentBadges.contains(BadgeIds.firstStep) && isFirstTransaction) {
      toAward.add(BadgeIds.firstStep);
    }
    if (!currentBadges.contains(BadgeIds.risingStar) && ovr >= 25) {
      toAward.add(BadgeIds.risingStar);
    }
    if (!currentBadges.contains(BadgeIds.ironWill) && std >= 20) {
      toAward.add(BadgeIds.ironWill);
    }
    if (!currentBadges.contains(BadgeIds.mvpContender) && ovr >= 75) {
      toAward.add(BadgeIds.mvpContender);
    }
    if (!currentBadges.contains(BadgeIds.ovr90Club) && ovr >= 90) {
      toAward.add(BadgeIds.ovr90Club);
    }

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

  double _getRatingValue(Map<String, dynamic> rating, String key) {
    final v = rating[key];
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is num) return v.toDouble();
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

    // 1. Add badge to user
    final userRef = _provider.firestore.collection('users').doc(athleteId);
    batch.update(userRef, {
      'badges': FieldValue.arrayUnion([badgeName]),
    });

    // 2. Feed entry (type BADGE)
    final feedRef = _provider.firestore.collection('feed').doc();
    batch.set(feedRef, {
      'id': feedRef.id,
      'teamId': teamId,
      'schoolId': schoolId,
      'type': 'BADGE',
      'actorName': 'System',
      'targetName': athleteName,
      'content': 'Earned $badgeName badge',
      'isPinned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Notification for the athlete
    final notifRef = _provider.firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'id': notifRef.id,
      'userId': athleteId,
      'title': 'Badge Unlocked!',
      'body': 'You earned the $badgeName badge.',
      'type': 'BADGE',
      'isRead': false,
      'relatedDocId': feedRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
