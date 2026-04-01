import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/team_repository.dart';
import '../player/player_controller.dart';
import '../coach/coach_controller.dart';

enum LeaderboardTimeframe { today, thisWeek, seasonOvr }

class LeaderboardController extends GetxController {
  final TeamRepository _teamRepo = TeamRepository();

  final RxInt selectedTimeframe = 2.obs; // 0=TODAY, 1=THIS WEEK, 2=SEASON OVR
  final RxList<UserModel> ranked = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription<List<UserModel>>? _athletesSub;

  List<UserModel> get podium => ranked.take(3).toList();
  List<UserModel> get elite => ranked.length > 3 ? ranked.sublist(3, ranked.length > 20 ? 20 : ranked.length) : [];
  List<UserModel> get roster => ranked.length > 20 ? ranked.sublist(20) : [];

  int get teamAvgOvr {
    if (ranked.isEmpty) return 0;
    final sum = ranked.fold<int>(0, (s, u) => s + u.coachVisibleOvr);
    return (sum / ranked.length).round();
  }

  int get totalPoints {
    return ranked.fold<int>(0, (sum, u) {
      final r = u.currentRating;
      final p = (r['Performance'] ?? 0) as num;
      final c = (r['Class'] ?? 0) as num;
      final prog = (r['Program'] ?? 0) as num;
      final s = (r['Standard'] ?? 0) as num;
      return sum + (p + c + prog + s).round();
    });
  }

  UserModel? categoryLeader(String categoryKey) {
    if (ranked.isEmpty) return null;
    final key = categoryKey == 'Classroom' ? 'Class' : categoryKey;
    UserModel? best;
    double bestVal = -1;
    for (final u in ranked) {
      final v = (u.currentRating[key] ?? 0) as num;
      if (v > bestVal) {
        bestVal = v.toDouble();
        best = u;
      }
    }
    return best;
  }

  double categoryLeaderPoints(String categoryKey) {
    final u = categoryLeader(categoryKey);
    if (u == null) return 0;
    final key = categoryKey == 'Classroom' ? 'Class' : categoryKey;
    return ((u.currentRating[key] ?? 0) as num).toDouble();
  }

  void setTimeframe(int index) => selectedTimeframe.value = index;

  @override
  void onInit() {
    super.onInit();
    _subscribeToRankings();
    // Re-subscribe when team becomes available (e.g. coach opened leaderboard before currentTeam loaded)
    try {
      ever(Get.find<PlayerController>().athlete, (_) => _subscribeToRankings());
    } catch (_) {}
    try {
      ever(Get.find<CoachController>().currentTeam, (_) => _subscribeToRankings());
    } catch (_) {}
  }

  @override
  void onClose() {
    _athletesSub?.cancel();
    super.onClose();
  }

  void _subscribeToRankings() {
    String? teamId;
    try {
      teamId = Get.find<PlayerController>().athlete.value?.teamId;
    } catch (_) {}
    if (teamId == null || teamId.isEmpty) {
      try {
        teamId = Get.find<CoachController>().currentTeam.value?.id;
      } catch (_) {}
    }
    if (teamId == null || teamId.isEmpty) {
      ranked.value = _mockRanked();
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _athletesSub?.cancel();
    // Clear old leaderboard immediately so the UI doesn't keep showing
    // previous season totals while Firestore propagates the reset updates.
    ranked.value = [];
    _athletesSub = _teamRepo.streamTeamAthletes(teamId).listen(
      (list) {
        // Only show leaderboard athletes who actually have season points.
        // After `resetSeason()`, currentRating becomes `{}` and we must hide everyone
        // until at least one athlete receives points.
        final filtered = list.where(_hasAnyPoints).toList();
        // Ensure rank is sequential after filtering.
        filtered.sort((a, b) => b.coachVisibleOvr.compareTo(a.coachVisibleOvr));
        for (int i = 0; i < filtered.length; i++) {
          final u = filtered[i];
          filtered[i] = u.copyWith(
            rank: i + 1,
            previousRank: u.previousRank,
          );
        }
        ranked.value = filtered;
        isLoading.value = false;
      },
      onError: (_) {
        ranked.value = _mockRanked();
        isLoading.value = false;
      },
    );
  }

  bool _hasAnyPoints(UserModel u) {
    // currentRating is `{}` immediately after season reset.
    if (u.currentRating.isEmpty) return false;
    for (final v in u.currentRating.values) {
      if (v is num) {
        // Any non-zero means this athlete actually has points.
        if (v != 0) return true;
      } else {
        final parsed = num.tryParse(v.toString());
        if (parsed != null && parsed != 0) return true;
      }
    }
    return false;
  }

  List<UserModel> _mockRanked() {
    const mock = _MockLeaderboardData.athletes;
    final list = mock.map((m) => m.toUserModel()).toList();
    list.sort((a, b) => b.ovr.compareTo(a.ovr));
    for (int i = 0; i < list.length; i++) {
      final u = list[i];
      list[i] = u.copyWith(rank: i + 1);
    }
    return list;
  }
}

class _MockLeaderboardData {
  final String uid;
  final String name;
  final int ovr;
  final int? previousRank;
  final String? positionGroup;
  final Map<String, dynamic> currentRating;

  const _MockLeaderboardData({
    required this.uid,
    required this.name,
    required this.ovr,
    this.previousRank,
    this.positionGroup,
    this.currentRating = const {},
  });

  UserModel toUserModel() => UserModel(
        uid: uid,
        email: '',
        name: name,
        role: 'athlete',
        currentRating: currentRating,
        ovr: ovr,
        previousRank: previousRank,
        positionGroup: positionGroup,
      );

  static const List<_MockLeaderboardData> athletes = [
    _MockLeaderboardData(uid: '1', name: 'Marcus Johnson', ovr: 92, previousRank: 2, positionGroup: 'QB', currentRating: {'Performance': 38.0, 'Class': 17.0, 'Program': 14.0, 'Standard': 15.0}),
    _MockLeaderboardData(uid: '2', name: 'E. Smith', ovr: 88, previousRank: 1, positionGroup: 'WR', currentRating: {'Performance': 32.0, 'Class': 18.0, 'Program': 12.0, 'Standard': 14.0}),
    _MockLeaderboardData(uid: '3', name: 'K. Brown', ovr: 84, previousRank: 3, positionGroup: 'RB', currentRating: {'Performance': 30.0, 'Class': 16.0, 'Program': 14.0, 'Standard': 13.0}),
    _MockLeaderboardData(uid: '4', name: 'T. Rogers', ovr: 82, previousRank: 5, positionGroup: 'WR', currentRating: {'Performance': 28.0, 'Class': 22.0, 'Program': 12.0, 'Standard': 12.0}),
    _MockLeaderboardData(uid: '5', name: 'J. Williams', ovr: 79, previousRank: 4, positionGroup: 'OL', currentRating: {'Performance': 26.0, 'Class': 15.0, 'Program': 16.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '6', name: 'D. Davis', ovr: 78, previousRank: 6, positionGroup: 'LB', currentRating: {'Performance': 29.0, 'Class': 14.0, 'Program': 13.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '7', name: 'M. Wilson', ovr: 76, previousRank: 7, positionGroup: 'DB', currentRating: {'Performance': 25.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '8', name: 'A. Martinez', ovr: 75, previousRank: 9, positionGroup: 'TE', currentRating: {'Performance': 24.0, 'Class': 15.0, 'Program': 14.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '9', name: 'C. Lee', ovr: 74, previousRank: 8, positionGroup: 'DL', currentRating: {'Performance': 23.0, 'Class': 16.0, 'Program': 13.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '10', name: 'R. Taylor', ovr: 73, previousRank: 10, positionGroup: 'WR', currentRating: {'Performance': 22.0, 'Class': 17.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '11', name: 'J. Harris', ovr: 72, previousRank: 11, positionGroup: 'RB', currentRating: {'Performance': 21.0, 'Class': 15.0, 'Program': 14.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '12', name: 'L. Clark', ovr: 71, previousRank: 12, positionGroup: 'OL', currentRating: {'Performance': 20.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '13', name: 'S. Lewis', ovr: 70, previousRank: 14, positionGroup: 'LB', currentRating: {'Performance': 19.0, 'Class': 15.0, 'Program': 13.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '14', name: 'P. Walker', ovr: 69, previousRank: 13, positionGroup: 'DB', currentRating: {'Performance': 18.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '15', name: 'N. Hall', ovr: 68, previousRank: 15, positionGroup: 'QB', currentRating: {'Performance': 17.0, 'Class': 15.0, 'Program': 14.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '16', name: 'K. Young', ovr: 67, previousRank: 16, positionGroup: 'WR', currentRating: {'Performance': 16.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '17', name: 'T. King', ovr: 66, previousRank: 17, positionGroup: 'RB', currentRating: {'Performance': 15.0, 'Class': 15.0, 'Program': 13.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '18', name: 'D. Wright', ovr: 65, previousRank: 18, positionGroup: 'OL', currentRating: {'Performance': 14.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '19', name: 'E. Scott', ovr: 64, previousRank: 19, positionGroup: 'LB', currentRating: {'Performance': 13.0, 'Class': 15.0, 'Program': 14.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '20', name: 'M. Green', ovr: 63, previousRank: 20, positionGroup: 'DL', currentRating: {'Performance': 12.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '21', name: 'A. Davis', ovr: 62, previousRank: 23, positionGroup: 'Forward', currentRating: {'Performance': 28.0, 'Class': 14.0, 'Program': 12.0, 'Standard': 13.0}),
    _MockLeaderboardData(uid: '22', name: 'S. Curry', ovr: 61, previousRank: 22, positionGroup: 'Guard', currentRating: {'Performance': 26.0, 'Class': 16.0, 'Program': 12.0, 'Standard': 12.0}),
    _MockLeaderboardData(uid: '23', name: 'K. Leonard', ovr: 60, previousRank: 21, positionGroup: 'Forward', currentRating: {'Performance': 25.0, 'Class': 15.0, 'Program': 13.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '24', name: 'J. Adams', ovr: 59, previousRank: 24, positionGroup: 'Guard', currentRating: {'Performance': 24.0, 'Class': 14.0, 'Program': 12.0, 'Standard': 12.0}),
    _MockLeaderboardData(uid: '25', name: 'B. Simmons', ovr: 58, previousRank: 25, positionGroup: 'Center', currentRating: {'Performance': 23.0, 'Class': 15.0, 'Program': 11.0, 'Standard': 11.0}),
    _MockLeaderboardData(uid: '26', name: 'R. Jackson', ovr: 57, previousRank: 26, positionGroup: 'Forward', currentRating: {'Performance': 22.0, 'Class': 14.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '27', name: 'D. Mitchell', ovr: 56, previousRank: 27, positionGroup: 'Guard', currentRating: {'Performance': 21.0, 'Class': 15.0, 'Program': 11.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '28', name: 'H. Barnes', ovr: 55, previousRank: 28, positionGroup: 'Forward', currentRating: {'Performance': 20.0, 'Class': 14.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '29', name: 'F. Turner', ovr: 54, previousRank: 29, positionGroup: 'Guard', currentRating: {'Performance': 19.0, 'Class': 15.0, 'Program': 11.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '30', name: 'G. Hill', ovr: 53, previousRank: 30, positionGroup: 'Forward', currentRating: {'Performance': 18.0, 'Class': 14.0, 'Program': 12.0, 'Standard': 10.0}),
    _MockLeaderboardData(uid: '31', name: 'W. Cooper', ovr: 52, previousRank: 31, positionGroup: 'Center', currentRating: {'Performance': 17.0, 'Class': 14.0, 'Program': 11.0, 'Standard': 11.0}),
  ];
}
