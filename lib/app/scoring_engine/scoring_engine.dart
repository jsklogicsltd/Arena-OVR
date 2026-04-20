/// Core scoring engine for the OVR99 Automated Assessment Engine.
///
/// Implements the three main calculation steps:
///   Step 4 — [scoreEvent]: raw performance value → Performance Points (30–99).
///   Step 5 — [calculateNumbers]: per-athlete POWER / SPEED / Top Performance Points.
///   Step 6/7 — [assignOverallRatings]: team-wide relative OVR ranking.
///
/// Updated April 2026 to support Grade 7–8 tier tables and the locked-in
/// 50/50 "grading on a curve" combined engine:
/// - Assessment Value (max 49.50) + Manual Input Value (max 49.50)
/// - Highest combined score on roster scales to phase cap, others proportional.
///
/// Reference: OVR99 Formula Reference v2.0 (April 2026).

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
/// Caps are now derived from each team's starting baseline:
/// phase 1/2 progressively unlock from baseline toward 99, phase 3 = 99.
enum SeasonPhase { phase1, phase2, phase3 }

/// Returns the OVR ceiling for the given [phase] and team baseline.
int phaseCap(SeasonPhase phase, {int startingOvrBaseline = 50}) {
  final baseline = startingOvrBaseline.clamp(0, 90);
  final earnablePoints = 99 - baseline;
  final phase1Cap = baseline + (earnablePoints / 3.0).floor();
  final phase2Cap = baseline + ((earnablePoints * 2.0) / 3.0).floor();
  switch (phase) {
    case SeasonPhase.phase1:
      return phase1Cap;
    case SeasonPhase.phase2:
      return phase2Cap;
    case SeasonPhase.phase3:
      return 99;
  }
}

SeasonPhase phaseForDay({
  required int currentDay,
  required int seasonLengthDays,
}) {
  final seasonLen = seasonLengthDays.clamp(7, 365);
  final day = currentDay.clamp(1, seasonLen);
  final phase1EndDay = (seasonLen / 3.0).ceil();
  final phase2EndDay = ((seasonLen * 2.0) / 3.0).ceil();
  if (day <= phase1EndDay) return SeasonPhase.phase1;
  if (day <= phase2EndDay) return SeasonPhase.phase2;
  return SeasonPhase.phase3;
}

// ---------------------------------------------------------------------------
// Step 5C — GPA score (0..99)
// ---------------------------------------------------------------------------

/// Converts GPA (0.0..4.0+) to a score on a 0..99 scale.
///
/// - GPA ≤ 0.0 → 0
/// - GPA ≥ 3.5 → 99
/// - Else: `ceil((gpa / 3.5) * 99)`
int gpaScore(double gpa) {
  if (gpa <= 0) return 0;
  if (gpa >= 3.5) return 99;
  return ((gpa / 3.5) * 99).ceil().clamp(0, 99);
}

// ---------------------------------------------------------------------------
// Step 5D — Assessment Value (decimal; max 49.50)
// ---------------------------------------------------------------------------

/// Assessment Value represents exactly 50% of a player's total OVR potential.
///
/// \[
/// assessmentValue = (powerScore * 0.20) + (speedScore * 0.20) + (gpaScore * 0.10)
/// \]
double assessmentValue({
  required int powerScore,
  required int speedScore,
  required int gpaScoreValue,
}) {
  return (powerScore * 0.20) + (speedScore * 0.20) + (gpaScoreValue * 0.10);
}

/// Manual Input Value represents the other 50% of the player's total OVR potential.
///
/// The app stores manual ratings as a 0..99-style score (manual OVR). To convert
/// that into a 50% contribution we scale by 0.50, producing 0..49.50.
double manualInputValueFromManualOvr(int manualOvr) {
  final m = manualOvr.clamp(0, 99);
  return m * 0.50;
}

/// Combined Score fed into the curve engine.
///
/// \[
/// combinedScore = assessmentValue + manualInputValue
/// \]
double combinedScore({
  required double assessmentValue,
  required double manualInputValue,
}) {
  return assessmentValue + manualInputValue;
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
// Step 6/7 — Assign team-relative Overall Ratings (curve)
// ---------------------------------------------------------------------------

/// Ranks all players on a team and assigns OVR ratings relative to the leader.
///
/// **Formula:** `OVR = ceil((playerValue / highestValue) × phaseCap)`
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
  {int startingOvrBaseline = 50}
) {
  if (playerPoints.isEmpty) return [];

  final baseline = startingOvrBaseline.clamp(0, 90);
  final int cap = phaseCap(phase, startingOvrBaseline: baseline);
  final int highest = playerPoints.values.reduce(max);

  if (highest <= 0) {
    return playerPoints.entries
        .map((e) => PlayerRating(
              playerId: e.key,
              topPerformancePoints: e.value,
              overallRating: baseline,
            ))
        .toList();
  }

  return playerPoints.entries.map((entry) {
    final score = entry.value <= 0 ? 0 : entry.value;
    final raw = (score / highest) * (cap - baseline);
    final finalOvr = baseline + raw.ceil();
    final ovr = finalOvr.clamp(baseline, cap);
    return PlayerRating(
      playerId: entry.key,
      topPerformancePoints: entry.value,
      overallRating: ovr,
    );
  }).toList()
    ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
}

/// Curve-engine for the locked 50/50 Combined Score model.
///
/// Each player must have a **combined score** (decimal). The team leader
/// (highest combined score) gets the phase cap; everyone else scales
/// proportionally.
///
/// \[
/// ovr = clamp(
///   baseline + ceil((combined / highestCombined) * (cap - baseline)),
///   baseline,
///   cap
/// )
/// \]
List<PlayerRating> assignOverallRatingsFromCombinedScore(
  Map<String, double> combinedScores, // playerId → combinedScore (decimal)
  SeasonPhase phase, {
  int startingOvrBaseline = 50,
}
) {
  if (combinedScores.isEmpty) return [];

  final baseline = startingOvrBaseline.clamp(0, 90);
  final int cap = phaseCap(phase, startingOvrBaseline: baseline);
  final double highest = combinedScores.values.reduce(max);
  if (highest <= 0) {
    return combinedScores.entries
        .map((e) => PlayerRating(
              playerId: e.key,
              topPerformancePoints: e.value.round(),
              overallRating: baseline,
            ))
        .toList()
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
  }

  return combinedScores.entries.map((e) {
    final double score = e.value <= 0 ? 0 : e.value;
    final double raw = (score / highest) * (cap - baseline);
    final int finalOvr = baseline + raw.ceil();
    final int ovr = finalOvr.clamp(baseline, cap);
    return PlayerRating(
      playerId: e.key,
      topPerformancePoints: e.value.round(),
      overallRating: ovr,
    );
  }).toList()
    ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
}
