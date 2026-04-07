import 'dart:math' as math;

/// Result object for OVR calculation.
class OvrResult {
  /// Raw calculated OVR after weighted math and 0.99 multiplier (rounded).
  final int actualOvr;

  /// OVR shown in UI after daily cap is applied.
  /// Returns null on Day 1 (locked state).
  final int? displayedOvr;

  /// Season day clamped to [1..15].
  final int currentDay;

  /// Daily cap for current day. Day 1 returns 0 (locked).
  final int currentCap;

  const OvrResult({
    required this.actualOvr,
    required this.displayedOvr,
    required this.currentDay,
    required this.currentCap,
  });
}

/// Core OVR engine service.
class OvrEngineService {
  static const double _athleteWeight = 0.4;
  static const double _studentWeight = 0.2;
  static const double _teammateWeight = 0.2;
  static const double _citizenWeight = 0.2;
  static const double _ovrScale = 0.99;
  static const int _baseOvr = 50;

  OvrResult calculateOvr({
    required DateTime seasonStartDate,
    DateTime? currentDate,
    required double athletePts,
    required double studentPts,
    required double teammatePts,
    required double citizenPts,
  }) {
    final now = currentDate ?? DateTime.now();
    final day = calculateSeasonDay(
      seasonStartDate: seasonStartDate,
      currentDate: now,
    );

    final ath = _clampPoints(athletePts);
    final stu = _clampPoints(studentPts);
    final tm = _clampPoints(teammatePts);
    final cit = _clampPoints(citizenPts);

    final raw = ((ath * _athleteWeight) +
            (stu * _studentWeight) +
            (tm * _teammateWeight) +
            (cit * _citizenWeight)) *
        _ovrScale;

    final actualOvr = (_baseOvr + raw.round()).clamp(0, 99);
    final cap = capForDay(day);
    final displayed = day == 1 ? null : math.min(actualOvr, cap);

    return OvrResult(
      actualOvr: actualOvr,
      displayedOvr: displayed,
      currentDay: day,
      currentCap: cap,
    );
  }

  /// Returns season day clamped to [1..15].
  int calculateSeasonDay({
    required DateTime seasonStartDate,
    required DateTime currentDate,
  }) {
    final start = DateTime(
      seasonStartDate.year,
      seasonStartDate.month,
      seasonStartDate.day,
    );
    final now = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final diffDays = now.difference(start).inDays;
    final day = diffDays + 1;
    if (day < 1) return 1;
    if (day > 15) return 15;
    return day;
  }

  /// Cap schedule:
  /// Day 1: hidden
  /// Day 2: 79
  /// Day 3: 82
  /// Day 4: 85
  /// Day 5: 88
  /// Day 6: 91
  /// Day 7: 94
  /// Day 8: 97
  /// Day 9..15: 99
  int capForDay(int day) {
    switch (day) {
      case 1:
        return 0;
      case 2:
        return 79;
      case 3:
        return 82;
      case 4:
        return 85;
      case 5:
        return 88;
      case 6:
        return 91;
      case 7:
        return 94;
      case 8:
        return 97;
      default:
        return 99;
    }
  }

  double _clampPoints(double value) => value.clamp(0.0, 100.0);
}

