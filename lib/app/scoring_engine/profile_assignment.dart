/// Profile assignment functions for the OVR99 Automated Assessment Engine.
///
/// Each player is assigned exactly TWO profiles based on height and weight:
///   1. A [PowerProfile] (light / medium / heavy) — used for strength events.
///   2. A [SpeedProfile] (standard / heavy) — used for speed events.
///
/// Grade does NOT affect profile assignment — only height and weight.
///
/// Reference: OVR99 Technical Implementation Guide, Section 1.

enum PowerProfile { light, medium, heavy }

enum SpeedProfile { standard, heavy }

/// Assigns a [PowerProfile] based on height (inches) and weight (lbs).
///
/// Height brackets determine the medium and heavy weight thresholds.
/// The function checks from heaviest to lightest — first match wins.
///
/// ```text
/// Height Range  |  LIGHT        |  MEDIUM        |  HEAVY
/// Under 69"     |  Under 130    |  130 – 179     |  180+
/// 69" to 72"    |  Under 140    |  140 – 198     |  199+
/// 73" to 74"    |  Under 155    |  155 – 219     |  220+
/// 75"+          |  Under 169    |  169 – 239     |  240+
/// ```
///
/// Updated for Grade 7–8 athletes: the sports scientist provided grade-specific
/// bodyweight cutoffs (CDC + BFS scaled). For grade 9+ we retain the original
/// BFS height-based cutoffs.
PowerProfile assignPowerProfile(
  int heightInches,
  int weightLbs, {
  int? grade,
}) {
  // Grade-specific bodyweight cutoffs for younger athletes.
  if (grade == 7) {
    if (weightLbs > 125) return PowerProfile.heavy;
    if (weightLbs >= 85) return PowerProfile.medium;
    return PowerProfile.light;
  }
  if (grade == 8) {
    if (weightLbs > 140) return PowerProfile.heavy;
    if (weightLbs >= 95) return PowerProfile.medium;
    return PowerProfile.light;
  }

  int heavyThreshold;
  int mediumThreshold;

  if (heightInches < 69) {
    mediumThreshold = 130;
    heavyThreshold = 180;
  } else if (heightInches <= 72) {
    mediumThreshold = 140;
    heavyThreshold = 199;
  } else if (heightInches <= 74) {
    mediumThreshold = 155;
    heavyThreshold = 220;
  } else {
    mediumThreshold = 169;
    heavyThreshold = 240;
  }

  if (weightLbs >= heavyThreshold) return PowerProfile.heavy;
  if (weightLbs >= mediumThreshold) return PowerProfile.medium;
  return PowerProfile.light;
}

/// Assigns a [SpeedProfile] based on height (inches) and weight (lbs).
///
/// Same height brackets as power, but only two outcomes.
///
/// ```text
/// Height Range  |  STANDARD      |  HEAVY
/// Under 69"     |  Under 180     |  180+
/// 69" to 72"    |  Under 199     |  199+
/// 73" to 74"    |  Under 219     |  219+
/// 75"+          |  Under 240     |  240+
/// ```
///
/// Updated for Grade 7–8 athletes: grade-specific bodyweight cutoffs.
SpeedProfile assignSpeedProfile(
  int heightInches,
  int weightLbs, {
  int? grade,
}) {
  if (grade == 7) {
    return weightLbs >= 125 ? SpeedProfile.heavy : SpeedProfile.standard;
  }
  if (grade == 8) {
    return weightLbs >= 140 ? SpeedProfile.heavy : SpeedProfile.standard;
  }

  int heavyThreshold;

  if (heightInches < 69) {
    heavyThreshold = 180;
  } else if (heightInches <= 72) {
    heavyThreshold = 199;
  } else if (heightInches <= 74) {
    heavyThreshold = 219;
  } else {
    heavyThreshold = 240;
  }

  if (weightLbs >= heavyThreshold) return SpeedProfile.heavy;
  return SpeedProfile.standard;
}
