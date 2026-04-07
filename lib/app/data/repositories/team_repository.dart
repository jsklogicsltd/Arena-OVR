import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../providers/firebase_provider.dart';

class TeamRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final query = await _provider.firestore
        .collection('teams')
        .where('inviteCode', isEqualTo: code.toUpperCase()) // Use inviteCode as the field name might mismatch 'teamCode', fallback to teamCode below just in case.
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
    final seasonData = {
      'id': newSeasonRef.id,
      'teamId': newTeamRef.id,
      'name': 'Season 1',
      'startDate': Timestamp.fromDate(now),
      // 15-day season (day 1..15) => end date is start + 14 days
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 14))),
      'isActive': true,
    };

    final batch = _provider.firestore.batch();
    final teamJson = teamWithCode.toJson();
    teamJson['coachIds'] = [team.createdBy];
    batch.set(newTeamRef, teamJson);
    batch.set(newSeasonRef, seasonData);
    
    final coachRef = _provider.firestore.collection('users').doc(team.createdBy);
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

  /// Single-document payload for an athlete when starting a new season.
  /// Must stay aligned with [CoachController.submitBulkAssessments] / manual entry
  /// (`assessmentData` map: squat, bench_press, 40_yard_dash, gpa, powerNumber, …).
  static Map<String, dynamic> _athleteSeasonResetUpdates() {
    return {
      // Manual OVR must reset to the base starting value (50), not 0.
      'ovr': 50,
      'actualOvr': 50,
      'ovrDay': null,
      'ovrCap': null,
      'currentRating': <String, dynamic>{},
      'currentStreak': <String, dynamic>{},
      'automatedOvr': 0,
      // Wipe the full assessment blob written by the Award → Assessments tab.
      'assessmentData': <String, dynamic>{},
      // Legacy / alternate top-level keys (defensive).
      'assessments': FieldValue.delete(),
      'assessment': FieldValue.delete(),
      'assessmentRaw': FieldValue.delete(),
      'assessmentMetrics': FieldValue.delete(),
      'bodyweight': FieldValue.delete(),
      'squat': FieldValue.delete(),
      'bench': FieldValue.delete(),
      'bench_press': FieldValue.delete(),
      'dash40': FieldValue.delete(),
      '40_yard_dash': FieldValue.delete(),
      'gpa': FieldValue.delete(),
    };
  }

  Future<void> resetSeason(String teamId) async {
    final teamDoc = await _provider.firestore.collection('teams').doc(teamId).get();
    if (!teamDoc.exists) return;

    final teamData = teamDoc.data()!;
    final currentSeasonId = teamData['currentSeasonId'];
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
      final currentSeasonRef = _provider.firestore.collection('seasons').doc(currentSeasonId);
      batch.update(currentSeasonRef, {'isActive': false, 'endDate': FieldValue.serverTimestamp()});
      ops++;
      await flushIfNeeded();
      
      final txSnapshot = await _provider.firestore.collection('transactions')
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
    final seasonSnap = await _provider.firestore.collection('seasons').where('teamId', isEqualTo: teamId).get();
    final newSeasonName = 'Season ${seasonSnap.size + 1}';

    final newStart = DateTime.now();
    batch.set(newSeasonRef, {
      'id': newSeasonRef.id,
      'teamId': teamId,
      'name': newSeasonName,
      'startDate': Timestamp.fromDate(newStart),
      // 15-day season (day 1..15) => end date is start + 14 days
      'endDate': Timestamp.fromDate(newStart.add(const Duration(days: 14))),
      'isActive': true,
    });
    ops++;
    await flushIfNeeded();

    batch.update(_provider.firestore.collection('teams').doc(teamId), {
      'currentSeasonId': newSeasonRef.id,
    });
    ops++;
    await flushIfNeeded();

    final athletesSnap = await _provider.firestore.collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .get();
        
    final athletePayload = _athleteSeasonResetUpdates();
    for (var doc in athletesSnap.docs) {
      batch.update(doc.reference, athletePayload);
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
      final list = snap.docs
          .map((d) {
            final data = d.data();
            data['uid'] = d.id;
            return UserModel.fromJson(data);
          })
          .toList();
      list.sort((a, b) => b.coachVisibleOvr.compareTo(a.coachVisibleOvr));
      for (int i = 0; i < list.length; i++) {
        final u = list[i];
        list[i] = u.copyWith(rank: i + 1, previousRank: u.rank);
      }
      return list;
    });
  }
}