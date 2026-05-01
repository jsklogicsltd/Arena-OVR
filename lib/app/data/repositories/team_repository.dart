import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../providers/firebase_provider.dart';
import 'badge_repository.dart' show BadgeIds;

class TeamRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final query = await _provider.firestore
        .collection('teams')
        .where(
          'inviteCode',
          isEqualTo: code.toUpperCase(),
        ) // Use inviteCode as the field name might mismatch 'teamCode', fallback to teamCode below just in case.
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      final fallbackQuery = await _provider.firestore
          .collection('teams')
          .where('teamCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
      if (fallbackQuery.docs.isEmpty) return null;
      final data = fallbackQuery.docs.first.data();
      data['id'] = fallbackQuery.docs.first.id;
      return data;
    }
    final data = query.docs.first.data();
    data['id'] = query.docs.first.id;
    return data;
  }

  Future<String> createTeam(TeamModel team) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[random.nextInt(chars.length)];
    }

    final newTeamRef = _provider.firestore.collection('teams').doc();
    final newSeasonRef = _provider.firestore.collection('seasons').doc();

    final teamWithCode = team.copyWith(
      id: newTeamRef.id,
      teamCode: code,
      currentSeasonId: newSeasonRef.id,
    );

    final now = DateTime.now();
    final seasonLengthDays = teamWithCode.seasonLengthDays.clamp(7, 365);
    final startingOvrBaseline = teamWithCode.startingOvrBaseline.clamp(0, 90);
    final seasonData = {
      'id': newSeasonRef.id,
      'teamId': newTeamRef.id,
      'name': 'Season 1',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(
        now.add(Duration(days: seasonLengthDays - 1)),
      ),
      'seasonLengthDays': seasonLengthDays,
      'startingOvrBaseline': startingOvrBaseline,
      'isActive': true,
    };

    final batch = _provider.firestore.batch();
    final teamJson = teamWithCode.toJson();
    teamJson['coachIds'] = [team.createdBy];
    batch.set(newTeamRef, teamJson);
    batch.set(newSeasonRef, seasonData);

    final coachRef = _provider.firestore
        .collection('users')
        .doc(team.createdBy);
    batch.update(coachRef, {
      'teamIds': FieldValue.arrayUnion([newTeamRef.id]),
      'activeTeamId': newTeamRef.id,
    });

    await batch.commit();
    return newTeamRef.id;
  }

  Future<void> updateTeamBranding(
    String teamId,
    String primary,
    String secondary,
    String? logoUrl, {
    String? name,
  }) async {
    final Map<String, dynamic> updates = {
      'primaryColor': primary,
      'secondaryColor': secondary,
    };
    if (logoUrl != null) {
      updates['logoUrl'] = logoUrl;
    }
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    await _provider.firestore.collection('teams').doc(teamId).update(updates);
  }

  Future<void> updateSeasonSettings({
    required String teamId,
    required int seasonLengthDays,
    required int startingOvrBaseline,
  }) async {
    final safeSeasonLength = seasonLengthDays.clamp(7, 365);
    final safeBaseline = startingOvrBaseline.clamp(0, 90);
    final teamRef = _provider.firestore.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    if (!teamDoc.exists || teamDoc.data() == null) return;

    final currentSeasonId = teamDoc.data()!['currentSeasonId'] as String?;
    final updates = <String, dynamic>{
      'seasonLengthDays': safeSeasonLength,
      'startingOvrBaseline': safeBaseline,
    };

    final batch = _provider.firestore.batch();
    batch.update(teamRef, updates);
    if (currentSeasonId != null && currentSeasonId.isNotEmpty) {
      final seasonRef = _provider.firestore
          .collection('seasons')
          .doc(currentSeasonId);
      final seasonSnap = await seasonRef.get();
      final startTs = seasonSnap.data()?['startDate'] as Timestamp?;
      if (startTs != null) {
        final start = startTs.toDate();
        batch.update(seasonRef, {
          'seasonLengthDays': safeSeasonLength,
          'startingOvrBaseline': safeBaseline,
          'endDate': Timestamp.fromDate(
            start.add(Duration(days: safeSeasonLength - 1)),
          ),
        });
      } else {
        batch.update(seasonRef, {
          'seasonLengthDays': safeSeasonLength,
          'startingOvrBaseline': safeBaseline,
        });
      }
    }
    await batch.commit();
  }

  /// Hard-reset the season after changing base settings (season length / starting OVR).
  /// Writes the new values to the team + season docs, archives all current transactions,
  /// creates a fresh season document, and resets every athlete to the new baseline.
  Future<void> resetSeasonWithNewSettings({
    required String teamId,
    required int seasonLengthDays,
    required int startingOvrBaseline,
  }) async {
    final safeSeasonLength = seasonLengthDays.clamp(7, 365);
    final safeBaseline = startingOvrBaseline.clamp(0, 90);

    final teamRef = _provider.firestore.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    if (!teamDoc.exists || teamDoc.data() == null) return;
    final teamData = teamDoc.data()!;
    final currentSeasonId = teamData['currentSeasonId'] as String?;

    WriteBatch batch = _provider.firestore.batch();
    int ops = 0;
    Future<void> flushIfNeeded() async {
      if (ops >= 450) {
        await batch.commit();
        batch = _provider.firestore.batch();
        ops = 0;
      }
    }

    // 1. Archive old season + transactions
    if (currentSeasonId != null && currentSeasonId.isNotEmpty) {
      final oldSeasonRef = _provider.firestore
          .collection('seasons')
          .doc(currentSeasonId);
      batch.update(oldSeasonRef, {
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
      });
      ops++;
      await flushIfNeeded();

      final txSnapshot = await _provider.firestore
          .collection('transactions')
          .where('teamId', isEqualTo: teamId)
          .where('seasonId', isEqualTo: currentSeasonId)
          .where('isArchived', isEqualTo: false)
          .get();
      for (var doc in txSnapshot.docs) {
        batch.update(doc.reference, {'isArchived': true});
        ops++;
        await flushIfNeeded();
      }
    }

    // 2. Create fresh season doc with new values
    final newSeasonRef = _provider.firestore.collection('seasons').doc();
    final seasonCount = await _provider.firestore
        .collection('seasons')
        .where('teamId', isEqualTo: teamId)
        .get();
    final newStart = DateTime.now();
    batch.set(newSeasonRef, {
      'id': newSeasonRef.id,
      'teamId': teamId,
      'name': 'Season ${seasonCount.size + 1}',
      'startDate': Timestamp.fromDate(newStart),
      'endDate': Timestamp.fromDate(
        newStart.add(Duration(days: safeSeasonLength - 1)),
      ),
      'seasonLengthDays': safeSeasonLength,
      'startingOvrBaseline': safeBaseline,
      'isActive': true,
    });
    ops++;
    await flushIfNeeded();

    // 3. Update team doc with new settings + point to new season
    batch.update(teamRef, {
      'currentSeasonId': newSeasonRef.id,
      'seasonLengthDays': safeSeasonLength,
      'startingOvrBaseline': safeBaseline,
      'averageOvr': safeBaseline,
      'totalRatingsThisSeason': 0,
    });
    ops++;
    await flushIfNeeded();

    // 4. Reset every athlete to the new baseline
    final athletesSnap = await _provider.firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .get();
    for (var doc in athletesSnap.docs) {
      batch.update(doc.reference, {
        ..._athleteSeasonResetUpdates(
          safeBaseline,
          existingAthleteData: doc.data(),
        ),
        'badges': _preserveNonArenaBadges(doc.data()['badges']),
      });
      ops++;
      await flushIfNeeded();
    }

    if (ops > 0) await batch.commit();
  }

  /// Keeps legacy/meta entries (e.g. `"First Step"`) not in [BadgeIds.all].
  static List<String> _preserveNonArenaBadges(dynamic raw) {
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    final arena = BadgeIds.all.toSet();
    return list.where((b) => !arena.contains(b)).toList();
  }

  /// Single-document payload for an athlete when starting a new season.
  /// Must stay aligned with [CoachController.submitBulkAssessments] / manual entry
  /// (`assessmentData` map: squat, bench_press, 40_yard_dash, gpa, powerNumber, …).
  static Map<String, dynamic> _athleteSeasonResetUpdates(
    int baseline, {
    required Map<String, dynamic> existingAthleteData,
  }) {
    final base = baseline.clamp(0, 90);
    final rawAssessment = existingAthleteData['assessmentData'];
    final carriedAssessment = rawAssessment is Map
        ? Map<String, dynamic>.from(rawAssessment)
        : <String, dynamic>{};
    return {
      // Manual OVR resets to team baseline.
      'ovr': base,
      'actualOvr': base,
      // Combined curve OVR baseline.
      'finalOvr': base,
      'ovrDay': null,
      'ovrCap': null,
      'currentRating': <String, dynamic>{},
      'rawBucketPoints': <String, dynamic>{},
      'ratingCount': 0,
      'currentStreak': <String, dynamic>{},
      'automatedOvr': 0,
      // Keep objective assessment metrics across seasons (coach can retest later).
      'assessmentData': carriedAssessment,
      // Clear legacy subjective caches only.
      'assessments': FieldValue.delete(),
      'assessment': FieldValue.delete(),
      'assessmentRaw': FieldValue.delete(),
      'assessmentMetrics': FieldValue.delete(),
    };
  }

  Future<void> resetSeason(String teamId) async {
    final teamDoc = await _provider.firestore
        .collection('teams')
        .doc(teamId)
        .get();
    if (!teamDoc.exists) return;

    final teamData = teamDoc.data()!;
    final currentSeasonId = teamData['currentSeasonId'];
    final seasonLengthDays = ((teamData['seasonLengthDays'] ?? 15) as num)
        .toInt()
        .clamp(7, 365);
    final startingOvrBaseline = ((teamData['startingOvrBaseline'] ?? 50) as num)
        .toInt()
        .clamp(0, 90);
    // Firestore WriteBatch limit is 500 ops. This reset can touch many docs, so we
    // commit in chunks to avoid limit failures while still keeping operations tight.
    WriteBatch batch = _provider.firestore.batch();
    int ops = 0;
    Future<void> flushIfNeeded() async {
      if (ops >= 450) {
        await batch.commit();
        batch = _provider.firestore.batch();
        ops = 0;
      }
    }

    if (currentSeasonId != null) {
      final currentSeasonRef = _provider.firestore
          .collection('seasons')
          .doc(currentSeasonId);
      batch.update(currentSeasonRef, {
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
      });
      ops++;
      await flushIfNeeded();

      final txSnapshot = await _provider.firestore
          .collection('transactions')
          .where('teamId', isEqualTo: teamId)
          .where('seasonId', isEqualTo: currentSeasonId)
          .where('isArchived', isEqualTo: false)
          .get();

      for (var doc in txSnapshot.docs) {
        batch.update(doc.reference, {'isArchived': true});
        ops++;
        await flushIfNeeded();
      }
    }

    final newSeasonRef = _provider.firestore.collection('seasons').doc();
    final seasonSnap = await _provider.firestore
        .collection('seasons')
        .where('teamId', isEqualTo: teamId)
        .get();
    final newSeasonName = 'Season ${seasonSnap.size + 1}';

    final newStart = DateTime.now();
    batch.set(newSeasonRef, {
      'id': newSeasonRef.id,
      'teamId': teamId,
      'name': newSeasonName,
      'startDate': Timestamp.fromDate(newStart),
      // Inclusive duration: e.g. 15 => start + 14.
      'endDate': Timestamp.fromDate(
        newStart.add(Duration(days: seasonLengthDays - 1)),
      ),
      'seasonLengthDays': seasonLengthDays,
      'startingOvrBaseline': startingOvrBaseline,
      'isActive': true,
    });
    ops++;
    await flushIfNeeded();

    batch.update(_provider.firestore.collection('teams').doc(teamId), {
      'currentSeasonId': newSeasonRef.id,
      'averageOvr': startingOvrBaseline,
      'totalRatingsThisSeason': 0,
    });
    ops++;
    await flushIfNeeded();

    final athletesSnap = await _provider.firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .get();

    for (var doc in athletesSnap.docs) {
      batch.update(doc.reference, {
        ..._athleteSeasonResetUpdates(
          startingOvrBaseline,
          existingAthleteData: doc.data(),
        ),
        'badges': _preserveNonArenaBadges(doc.data()['badges']),
      });
      ops++;
      await flushIfNeeded();
    }

    if (ops > 0) {
      await batch.commit();
    }
  }

  /// Stream team athletes sorted by OVR descending. Used for leaderboard.
  Stream<List<UserModel>> streamTeamAthletes(String teamId) {
    return _provider.firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = d.data();
            data['uid'] = d.id;
            return UserModel.fromJson(data);
          }).toList();
          list.sort((a, b) => b.coachVisibleOvr.compareTo(a.coachVisibleOvr));
          for (int i = 0; i < list.length; i++) {
            final u = list[i];
            list[i] = u.copyWith(rank: i + 1, previousRank: u.rank);
          }
          return list;
        });
  }
}
