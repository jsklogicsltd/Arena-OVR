import '../providers/firebase_provider.dart';
import '../models/transaction_model.dart';
import '../models/season_model.dart';
import '../models/challenge_catalog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'badge_repository.dart';
import '../../core/services/ovr_engine_service.dart';

class RatingRepository {
  final FirebaseProvider _provider = FirebaseProvider();
  final BadgeRepository _badgeRepo = BadgeRepository();
  final OvrEngineService _ovrEngine = OvrEngineService();

  Future<void> awardRating(TransactionModel transaction) async {
    await _provider.firestore.collection('transactions').doc(transaction.id).set(transaction.toJson());
  }

  Future<List<TransactionModel>> getAthleteHistory(String athleteId) async {
    final snapshot = await _provider.firestore.collection('transactions')
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
  }

  Future<void> recalculateOvr(String teamId, String seasonId) async {
    final seasonDoc = await _provider.firestore.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists || seasonDoc.data() == null) return;
    
    final season = SeasonModel.fromJson(seasonDoc.data()!);
    final startDate = season.startDate ?? DateTime.now();

    final athletesSnap = await _provider.firestore.collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .get();

    final txSnapshot = await _provider.firestore.collection('transactions')
        .where('teamId', isEqualTo: teamId)
        .where('seasonId', isEqualTo: seasonId)
        .where('isArchived', isEqualTo: false)
        .get();

    final Map<String, Map<String, double>> stats = {};
    for (var doc in athletesSnap.docs) {
      stats[doc.id] = {'ath': 0, 'stu': 0, 'tm': 0, 'cit': 0, 'raw': 0};
    }

    for (var doc in txSnapshot.docs) {
      final t = TransactionModel.fromJson(doc.data());
      final aId = t.athleteId;
      if (!stats.containsKey(aId)) continue;
      
      switch (t.category.toLowerCase()) {
        case 'athlete':
        case 'performance':
          stats[aId]!['ath'] = stats[aId]!['ath']! + t.value;
          break;
        case 'student':
        case 'class':
        case 'classroom':
          stats[aId]!['stu'] = stats[aId]!['stu']! + t.value;
          break;
        case 'teammate':
        case 'program':
          stats[aId]!['tm'] = stats[aId]!['tm']! + t.value;
          break;
        case 'citizen':
        case 'standard':
          stats[aId]!['cit'] = stats[aId]!['cit']! + t.value;
          break;
        default:
          stats[aId]!['ath'] = stats[aId]!['ath']! + t.value;
      }
    }

    for (var aId in stats.keys) {
      stats[aId]!['ath'] = stats[aId]!['ath']!.clamp(0.0, 100.0);
      stats[aId]!['stu'] = stats[aId]!['stu']!.clamp(0.0, 100.0);
      stats[aId]!['tm'] = stats[aId]!['tm']!.clamp(0.0, 100.0);
      stats[aId]!['cit'] = stats[aId]!['cit']!.clamp(0.0, 100.0);
    }

    final batch = _provider.firestore.batch();
    
    int totalOvr = 0;
    int ratedAthletes = 0;

    for (var doc in athletesSnap.docs) {
      final aId = doc.id;

      final ath = stats[aId]!['ath']!;
      final stu = stats[aId]!['stu']!;
      final tm = stats[aId]!['tm']!;
      final cit = stats[aId]!['cit']!;

      final result = _ovrEngine.calculateOvr(
        seasonStartDate: startDate,
        athletePts: ath,
        studentPts: stu,
        teammatePts: tm,
        citizenPts: cit,
      );

      final displayedOvr = result.displayedOvr ?? 0;
      totalOvr += result.actualOvr;
      ratedAthletes++;

      batch.update(doc.reference, {
        'ovr': displayedOvr,
        'actualOvr': result.actualOvr,
        'ovrDay': result.currentDay,
        'ovrCap': result.currentCap,
        'currentRating': {
            'Athlete': ath,
            'Student': stu,
            'Teammate': tm,
            'Citizen': cit,
        }
      });
    }

    if (ratedAthletes > 0) {
      int avgOvr = (totalOvr / ratedAthletes).round();
      batch.update(_provider.firestore.collection('teams').doc(teamId), {
        'averageOvr': avgOvr,
        'totalRatingsThisSeason': txSnapshot.docs.length,
      });
    }

    await batch.commit();
  }

  /// Awards multiple parent categories (each with a chosen challenge) to many athletes.
  /// One Firestore doc per (athlete × award line). [CategoryAwardInput.category] is the OVR bucket.
  Future<void> submitPointsBulk({
    required String teamId,
    required String seasonId,
    required List<String> athleteIds,
    required String coachId,
    required List<CategoryAwardInput> awards,
    required String note,
    String schoolId = '',
  }) async {
    final ids = athleteIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    final sortedAwards = List<CategoryAwardInput>.from(awards)
      ..sort((a, b) {
        final c = a.category.compareTo(b.category);
        if (c != 0) return c;
        return a.subcategory.compareTo(b.subcategory);
      });

    if (ids.isEmpty || sortedAwards.isEmpty) return;

    final effectiveSchoolId = schoolId.isNotEmpty ? schoolId : 'UNKNOWN_SCHOOL';
    final firestore = _provider.firestore;
    final now = DateTime.now();

    final Map<String, Map<String, dynamic>> streakByAthlete = {};
    final anyPositive = sortedAwards.any((e) => e.value > 0);
    if (anyPositive) {
      final snaps = await Future.wait(
        ids.map((id) => firestore.collection('users').doc(id).get()),
      );
      for (var i = 0; i < ids.length; i++) {
        final doc = snaps[i];
        final athleteId = ids[i];
        if (!doc.exists || doc.data() == null) continue;
        final userData = doc.data()!;
        Map<String, dynamic> streak = userData['currentStreak'] != null
            ? Map<String, dynamic>.from(userData['currentStreak'] as Map)
            : {};
        for (final a in sortedAwards) {
          if (a.value > 0) {
            streak = _nextStreakMap(streak, a.category);
          }
        }
        streakByAthlete[athleteId] = streak;
      }
    }

    final txOps = <void Function(WriteBatch)>[];
    for (final athleteId in ids) {
      for (final a in sortedAwards) {
        final txRef = firestore.collection('transactions').doc();
        final transaction = TransactionModel(
          id: txRef.id,
          athleteId: athleteId,
          teamId: teamId,
          seasonId: seasonId,
          coachId: coachId,
          schoolId: effectiveSchoolId,
          type: 'RATING',
          category: a.category,
          subcategory: a.subcategory,
          value: a.value,
          note: note,
          createdAt: now,
        );
        final json = transaction.toJson();
        txOps.add((b) => b.set(txRef, json));
      }
      if (anyPositive && streakByAthlete.containsKey(athleteId)) {
        final ref = firestore.collection('users').doc(athleteId);
        final streak = streakByAthlete[athleteId]!;
        txOps.add((b) => b.update(ref, {'currentStreak': streak}));
      }
    }

    await _runBatchedOps(firestore, txOps);
    await recalculateOvr(teamId, seasonId);

    final feedOps = <void Function(WriteBatch)>[];
    for (final athleteId in ids) {
      for (final a in sortedAwards) {
        final v = a.value;
        final cat = a.category;
        final sub = a.subcategory;
        feedOps.add((b) {
          final feedRef = firestore.collection('feed').doc();
          final subTrim = sub.trim();
          final pointsLine =
              '${v > 0 ? '+' : ''}$v POINTS in ${cat.toUpperCase()}${subTrim.isNotEmpty ? ' · $subTrim' : ''}';
          b.set(feedRef, {
            'id': feedRef.id,
            'teamId': teamId,
            'schoolId': effectiveSchoolId,
            'type': 'RATING',
            'actorName': 'Coach',
            'targetName': athleteId,
            'content': note.isNotEmpty ? note : pointsLine,
            'category': cat,
            if (subTrim.isNotEmpty) 'subcategory': subTrim,
            'value': v,
            'actorId': coachId,
            'targetId': athleteId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        feedOps.add((b) {
          final notifRef = firestore.collection('notifications').doc();
          final title = v >= 0 ? 'Points Awarded!' : 'Points updated';
          final body = v >= 0
              ? 'You received $v points in $cat ($sub).'
              : 'Adjustment: $v points in $cat ($sub).';
          b.set(notifRef, {
            'id': notifRef.id,
            'userId': athleteId,
            'title': title,
            'body': body,
            'type': 'RATING',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      }
    }
    await _runBatchedOps(firestore, feedOps);

    await Future.wait(
      ids.map(
        (id) => _badgeRepo.evaluateAfterPoints(
              athleteId: id,
              teamId: teamId,
              schoolId: effectiveSchoolId,
            ),
      ),
    );
  }

  Future<void> _runBatchedOps(
    FirebaseFirestore firestore,
    List<void Function(WriteBatch)> ops,
  ) async {
    const maxBatch = 450;
    var batch = firestore.batch();
    var count = 0;
    for (final op in ops) {
      if (count >= maxBatch) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
      op(batch);
      count++;
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Map<String, dynamic> _nextStreakMap(
    Map<String, dynamic> currentStreak,
    String category,
  ) {
    final next = Map<String, dynamic>.from(currentStreak);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (next[category] != null) {
      final lastUpdate = next['${category}_lastDate'];
      if (lastUpdate != today) {
        next[category] = (next[category] as int) + 1;
        next['${category}_lastDate'] = today;
      }
    } else {
      next[category] = 1;
      next['${category}_lastDate'] = today;
    }
    return next;
  }

  Future<void> submitPoints({
    required String teamId,
    required String seasonId,
    required String athleteId,
    required String coachId,
    required String category,
    String? subcategory,
    required int value,
    required String note,
    bool isPositive = true,
    String schoolId = '',
  }) async {
    final actualValue = isPositive ? value : -value;
    final effectiveSchoolId = schoolId.isNotEmpty ? schoolId : 'UNKNOWN_SCHOOL';

    final txRef = _provider.firestore.collection('transactions').doc();
    final transaction = TransactionModel(
      id: txRef.id,
      athleteId: athleteId,
      teamId: teamId,
      seasonId: seasonId,
      coachId: coachId,
      schoolId: effectiveSchoolId,
      type: 'RATING',
      category: category,
      subcategory: subcategory,
      value: actualValue,
      note: note,
      createdAt: DateTime.now(),
    );
    
    await awardRating(transaction);

    if (isPositive) {
      await checkAndUpdateStreaks(athleteId, category);
    }

    await recalculateOvr(teamId, seasonId);

    final subTrim = (subcategory ?? '').trim();
    final pointsLine =
        '${actualValue > 0 ? '+' : ''}$actualValue POINTS in ${category.toUpperCase()}${subTrim.isNotEmpty ? ' · $subTrim' : ''}';

    final feedRef = _provider.firestore.collection('feed').doc();
    await feedRef.set({
      'id': feedRef.id,
      'teamId': teamId,
      'schoolId': effectiveSchoolId,
      'type': 'RATING',
      'actorName': 'Coach',
      'targetName': athleteId,
      'content': note.isNotEmpty ? note : pointsLine,
      'category': category,
      if (subTrim.isNotEmpty) 'subcategory': subTrim,
      'value': actualValue,
      'actorId': coachId,
      'targetId': athleteId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final notifRef = _provider.firestore.collection('notifications').doc();
    await notifRef.set({
      'id': notifRef.id,
      'userId': athleteId,
      'title': 'Points Awarded!',
      'body': subTrim.isNotEmpty
          ? 'You received $actualValue points in $category ($subTrim).'
          : 'You received $actualValue points in $category.',
      'type': 'RATING',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Evaluate badges after OVR update; awards new badges and creates feed + notification
    await _badgeRepo.evaluateAfterPoints(
      athleteId: athleteId,
      teamId: teamId,
      schoolId: effectiveSchoolId,
    );
  }

  Future<void> checkAndUpdateStreaks(String athleteId, String category) async {
    final userDoc = await _provider.firestore.collection('users').doc(athleteId).get();
    if (!userDoc.exists || userDoc.data() == null) return;

    final userData = userDoc.data()!;
    Map<String, dynamic> currentStreak = userData['currentStreak'] != null
        ? Map<String, dynamic>.from(userData['currentStreak'] as Map)
        : {};

    final updated = _nextStreakMap(currentStreak, category);

    await _provider.firestore.collection('users').doc(athleteId).update({
      'currentStreak': updated,
    });
  }
}