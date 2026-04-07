/// Core scoring engine for the OVR99 Automated Assessment Engine.
///
/// Implements the three main calculation steps:
///   Step 4 — [scoreEvent]: raw performance value → Performance Points (30–99).
///   Step 5 — [calculateNumbers]: per-athlete POWER / SPEED / Top Performance Points.
///   Step 6 — [assignOverallRatings]: team-wide relative OVR ranking.
///
/// Reference: OVR99 Technical Implementation Guide, Section 3.

import 'dart:math';

// ---------------------------------------------------------------------------
// Model classes
// ---------------------------------------------------------------------------

/// Tier thresholds for a single event at a specific grade + profile.
///
/// The [lowerIsBetter] flag tells [scoreEvent] which formula direction to use.
/// For dash events (40-yard, 20-yard) this is `true`; for all others `false`.
class TierThresholds {
  final double good;
  final double great;
  final double allState;
  final double allAmerican;
  final bool lowerIsBetter;

  const TierThresholds({
    required this.good,
    required this.great,
    required this.allState,
    required this.allAmerican,
    this.lowerIsBetter = false,
  });
}

/// The three numbers produced by Step 5 for a single athlete.
class AthleteNumbers {
  final int powerNumber;
  final int speedNumber;
  final int topPerformancePoints;

  const AthleteNumbers({
    required this.powerNumber,
    required this.speedNumber,
    required this.topPerformancePoints,
  });

  @override
  String toString() =>
      'AthleteNumbers(power: $powerNumber, speed: $speedNumber, '
      'topPerfPts: $topPerformancePoints)';
}

/// A single player's final rating produced by Step 6.
class PlayerRating {
  final String playerId;
  final int topPerformancePoints;
  final int overallRating;

  const PlayerRating({
    required this.playerId,
    required this.topPerformancePoints,
    required this.overallRating,
  });

  @override
  String toString() =>
      'PlayerRating(id: $playerId, topPerfPts: $topPerformancePoints, '
      'ovr: $overallRating)';
}

/// The three season phases and their corresponding OVR caps.
///
/// ```text
/// Phase 1  →  1/3 through season  →  cap 79
/// Phase 2  →  2/3 through season  →  cap 89
/// Phase 3  →  end of season       →  cap 99
/// ```
enum SeasonPhase { phase1, phase2, phase3 }

/// Returns the OVR ceiling for the given [phase].
int phaseCap(SeasonPhase phase) {
  switch (phase) {
    case SeasonPhase.phase1:
      return 79;
    case SeasonPhase.phase2:
      return 89;
    case SeasonPhase.phase3:
      return 99;
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Convert a raw performance value to Performance Points (30–99)
// ---------------------------------------------------------------------------

/// Converts a single [rawValue] into Performance Points (30–99) using the
/// supplied [thresholds].
///
/// **Formula A** (higher is better — lifts and jumps):
/// `PP = 30 + ((raw − Good) / (AllAmerican − Good)) × 69`, rounded UP.
///
/// **Formula B** (lower is better — dash events):
/// `PP = 30 + ((Good − raw) / (Good − AllAmerican)) × 69`, rounded UP.
///
/// Boundary rules:
/// * At or below *Good* (Formula A) / at or above *Good* (Formula B) → **30**.
/// * At or above *AllAmerican* (Formula A) / at or below *AllAmerican*
///   (Formula B) → **99**.
int scoreEvent(double rawValue, TierThresholds thresholds) {
  const int floor = 30;
  const int ceiling = 99;
  const int range = 69; // ceiling - floor

  if (thresholds.lowerIsBetter) {
    // FORMULA B: Lower is better (dash events)
    if (rawValue >= thresholds.good) return floor;
    if (rawValue <= thresholds.allAmerican) return ceiling;
    final double ratio = (thresholds.good - rawValue) /
        (thresholds.good - thresholds.allAmerican);
    return min(ceiling, (floor + ratio * range).ceil());
  } else {
    // FORMULA A: Higher is better (all other events)
    if (rawValue <= thresholds.good) return floor;
    if (rawValue >= thresholds.allAmerican) return ceiling;
    final double ratio = (rawValue - thresholds.good) /
        (thresholds.allAmerican - thresholds.good);
    return min(ceiling, (floor + ratio * range).ceil());
  }
}

/// Convenience wrapper that performs the tier-table lookup for you.
///
/// [tierTables] is the nested map keyed by
/// `eventName → grade → profile → TierThresholds`.
/// Returns `null` if any part of the lookup fails (bad event name, grade, or
/// profile).
int? scoreEventByName(
  String eventName,
  int grade,
  String profile,
  double rawValue,
  Map<String, Map<int, Map<String, TierThresholds>>> tierTables,
) {
  final eventMap = tierTables[eventName];
  if (eventMap == null) return null;
  final gradeMap = eventMap[grade];
  if (gradeMap == null) return null;
  final thresholds = gradeMap[profile];
  if (thresholds == null) return null;
  return scoreEvent(rawValue, thresholds);
}

// ---------------------------------------------------------------------------
// Step 5 — Calculate POWER Number, SPEED Number, Top Performance Points
// ---------------------------------------------------------------------------

/// Computes the three athlete numbers from individual event scores.
///
/// * **POWER Number** = average of [powerScores], rounded UP.
/// * **SPEED Number** = average of [speedScores], rounded UP.
/// * **Top Performance Points** = average of POWER and SPEED numbers,
///   rounded UP.
///
/// Both lists must contain at least one score.
AthleteNumbers calculateNumbers(
  List<int> powerScores,
  List<int> speedScores,
) {
  assert(powerScores.isNotEmpty, 'At least 1 Power score is required');
  assert(speedScores.isNotEmpty, 'At least 1 Speed score is required');

  final int powerNumber =
      (powerScores.reduce((a, b) => a + b) / powerScores.length).ceil();
  final int speedNumber =
      (speedScores.reduce((a, b) => a + b) / speedScores.length).ceil();
  final int topPerfPts = ((powerNumber + speedNumber) / 2).ceil();

  return AthleteNumbers(
    powerNumber: powerNumber,
    speedNumber: speedNumber,
    topPerformancePoints: topPerfPts,
  );
}

// ---------------------------------------------------------------------------
// Step 6 — Assign team-relative Overall Ratings
// ---------------------------------------------------------------------------

/// Ranks all players on a team and assigns OVR ratings relative to the leader.
///
/// **Formula:** `OVR = ceil((playerTopPerfPts / highestTopPerfPts) × phaseCap)`
///
/// The list is returned sorted by [PlayerRating.overallRating] descending.
///
/// **Important:** This must be called for the ENTIRE TEAM whenever:
/// * Any player enters or updates performance data.
/// * The season phase changes (1 → 2 → 3).
/// * A player is added to or removed from the team.
///
/// Because OVR is *relative*, one player's change can affect everyone's rating.
List<PlayerRating> assignOverallRatings(
  Map<String, int> playerPoints, // playerId → Top Performance Points
  SeasonPhase phase,
) {
  if (playerPoints.isEmpty) return [];

  final int cap = phaseCap(phase);
  final int highest = playerPoints.values.reduce(max);

  if (highest <= 0) {
    return playerPoints.entries
        .map((e) => PlayerRating(
              playerId: e.key,
              topPerformancePoints: e.value,
              overallRating: 0,
            ))
        .toList();
  }

  return playerPoints.entries.map((entry) {
    final double raw = (entry.value / highest) * cap;
    final int ovr = min(cap, raw.ceil());
    return PlayerRating(
      playerId: entry.key,
      topPerformancePoints: entry.value,
      overallRating: ovr,
    );
  }).toList()
    ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
}
