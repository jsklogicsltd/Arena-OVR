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
///
/// **v1.0.6 — Time-based ceiling REMOVED.** Per client direction the engine no
/// longer throttles OVR by phase/day; raw curved values are persisted. The
/// function intentionally returns `99` for every phase so callers that still
/// pass [phase] (badge engine, leaderboard, legacy code paths) keep compiling.
///
/// To restore phase-based throttling in the future, revert this function body
/// to the previous baseline-derived `phase1Cap`/`phase2Cap` math.
int phaseCap(SeasonPhase phase, {int startingOvrBaseline = 50}) {
  // Argument ignored on purpose — see header comment.
  // ignore: unused_local_variable
  final _ = startingOvrBaseline.clamp(0, 90);
  return 99;
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

/// Manual Input Value **above baseline** (0..49.50).
///
/// This is critical for the curve engine: a team baseline (e.g. 60) represents
/// "zero earned subjective points", so it must contribute 0 to the combined score.
double manualInputValueFromManualOvrAboveBaseline({
  required int manualOvr,
  required int baseline,
}) {
  final m = manualOvr.clamp(0, 99);
  final b = baseline.clamp(0, 90);
  final earned = (m - b);
  if (earned <= 0) return 0;
  return earned * 0.50;
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

// ---------------------------------------------------------------------------
// "Top Dawg" Subjective Curve + Zero/80 Gates (v2.0)
// ---------------------------------------------------------------------------
//
// Phase 1 — Top Dawg Curve
// For each of the 4 subjective buckets (Athlete/Competitor, Student, Teammate,
// Citizen) the score is scaled relative to the team's best performer in that
// category. The team "Top Dawg" for a bucket always maps to 99; everyone else
// scales proportionally.
//
// Phase 2 — Gating Hierarchy
// After the curve OVR is computed the following strict gates are applied:
//   1. Zero Category Hard Cap: if ANY scaled bucket == 0 → cap at 84.
//   2. Subjective Gate 80: if manualOvr < 80 and curveOvr ≥ 90 → cap at 89.
//   3. Otherwise: full curveOvr is awarded.

/// Holds the 4 scaled subjective bucket scores for a single athlete.
class SubjectiveBucketScores {
  final int athleteScore;
  final int studentScore;
  final int teammateScore;
  final int citizenScore;

  /// The Top Dawg-curved manual OVR (average of the 4 bucket scores, rounded).
  final int manualOvr;

  const SubjectiveBucketScores({
    required this.athleteScore,
    required this.studentScore,
    required this.teammateScore,
    required this.citizenScore,
    required this.manualOvr,
  });

  /// Returns `true` if ANY of the 4 buckets equals exactly 0.
  bool get hasZeroBucket =>
      athleteScore == 0 ||
      studentScore == 0 ||
      teammateScore == 0 ||
      citizenScore == 0;
}

/// Pre-pass: find the highest raw point total for each subjective bucket
/// across the entire roster, then scale each athlete's raw totals against
/// that Top Dawg ceiling.
///
/// [rosterBucketRaw] maps `playerId → { 'ath': double, 'stu': double,
/// 'tm': double, 'cit': double }`.
///
/// Returns a map `playerId → SubjectiveBucketScores`.
Map<String, SubjectiveBucketScores> computeTopDawgSubjectiveScores(
  Map<String, Map<String, double>> rosterBucketRaw,
) {
  // 1. Find team-wide maxima for each bucket.
  double maxAthRaw = 0;
  double maxStuRaw = 0;
  double maxTmRaw = 0;
  double maxCitRaw = 0;

  for (final buckets in rosterBucketRaw.values) {
    final ath = buckets['ath'] ?? 0;
    final stu = buckets['stu'] ?? 0;
    final tm = buckets['tm'] ?? 0;
    final cit = buckets['cit'] ?? 0;
    if (ath > maxAthRaw) maxAthRaw = ath;
    if (stu > maxStuRaw) maxStuRaw = stu;
    if (tm > maxTmRaw) maxTmRaw = tm;
    if (cit > maxCitRaw) maxCitRaw = cit;
  }

  // 2. Scale each athlete's buckets against the team Top Dawg.
  int scaleBucket(double playerRaw, double maxRaw) {
    if (maxRaw <= 0) return 0;
    return ((playerRaw / maxRaw) * 99).round();
  }

  final result = <String, SubjectiveBucketScores>{};
  for (final entry in rosterBucketRaw.entries) {
    final id = entry.key;
    final b = entry.value;
    final athScore = scaleBucket(b['ath'] ?? 0, maxAthRaw);
    final stuScore = scaleBucket(b['stu'] ?? 0, maxStuRaw);
    final tmScore = scaleBucket(b['tm'] ?? 0, maxTmRaw);
    final citScore = scaleBucket(b['cit'] ?? 0, maxCitRaw);

    final manualBase = (athScore + stuScore + tmScore + citScore) / 4.0;
    final manualOvr = manualBase.round();

    result[id] = SubjectiveBucketScores(
      athleteScore: athScore,
      studentScore: stuScore,
      teammateScore: tmScore,
      citizenScore: citScore,
      manualOvr: manualOvr,
    );
  }
  return result;
}

/// Applies the v2.0 Zero Category / Subjective-80 gating hierarchy to a
/// curved OVR.
///
/// 1. If ANY scaled bucket == 0 → hard cap at 84.
/// 2. Else if manualOvr < 80 AND curveOvr ≥ 90 → cap at 89.
/// 3. Else → full curveOvr.
int applyTopDawgGates(int curveOvr, SubjectiveBucketScores buckets) {
  if (buckets.hasZeroBucket) {
    return min(curveOvr, 84);
  }
  if (buckets.manualOvr < 80 && curveOvr >= 90) {
    return 89;
  }
  return curveOvr;
}

/// Curve-engine for the locked 50/50 Combined Score model.
///
/// Each player must have a **combined score** (decimal). The team leader
/// (highest combined score) gets the (effective) cap; everyone else scales
/// proportionally relative to that leader.
///
/// **v2.0 — Top Dawg gates replace the old milestone gates.**
/// * Per-athlete baseline support: pass [baselineByAthlete] to override the
///   team-wide [startingOvrBaseline] for specific athletes (e.g. dual-sport
///   locked-in baselines). Athletes missing from the map fall back to
///   [startingOvrBaseline]. Each athlete's OVR floor is their own baseline.
/// * Top Dawg gating: pass [bucketScoresByAthlete] (pre-computed via
///   [computeTopDawgSubjectiveScores]) and the engine will apply the
///   Zero-Category / Subjective-80 gates (see [applyTopDawgGates]).
///
/// Backwards compatible: callers that don't pass the new map get no gating.
List<PlayerRating> assignOverallRatingsFromCombinedScore(
  Map<String, double> combinedScores, // playerId → combinedScore (decimal)
  SeasonPhase phase, {
  int startingOvrBaseline = 50,
  Map<String, int>? baselineByAthlete,
  Map<String, SubjectiveBucketScores>? bucketScoresByAthlete,
}) {
  if (combinedScores.isEmpty) return [];

  final teamBaseline = startingOvrBaseline.clamp(0, 90);
  final int cap = phaseCap(phase, startingOvrBaseline: teamBaseline);
  final double highest = combinedScores.values.reduce(max);

  int baselineFor(String id) {
    final v = baselineByAthlete?[id];
    if (v == null) return teamBaseline;
    return v.clamp(0, 90);
  }

  if (highest <= 0) {
    return combinedScores.entries
        .map((e) => PlayerRating(
              playerId: e.key,
              topPerformancePoints: e.value.round(),
              overallRating: baselineFor(e.key),
            ))
        .toList()
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
  }

  return combinedScores.entries.map((e) {
    final id = e.key;
    final double score = e.value <= 0 ? 0 : e.value;
    final int athleteBaseline = baselineFor(id);
    // Curve scales the leader to [cap]. Each athlete is floored at their own
    // baseline so per-athlete overrides cannot drag someone below their
    // locked-in starting OVR.
    final double raw = (score / highest) * (cap - athleteBaseline);
    final int curveOvr = (athleteBaseline + raw.ceil()).clamp(athleteBaseline, cap);

    // Apply Top Dawg Zero/80 gates (v2.0) when bucket scores are available.
    int finalOvr = curveOvr;
    final buckets = bucketScoresByAthlete?[id];
    if (buckets != null) {
      finalOvr = applyTopDawgGates(curveOvr, buckets);
      // Never drop below the athlete's own baseline floor due to gating.
      if (finalOvr < athleteBaseline) finalOvr = athleteBaseline;
    }

    return PlayerRating(
      playerId: id,
      topPerformancePoints: e.value.round(),
      overallRating: finalOvr,
    );
  }).toList()
    ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
}
