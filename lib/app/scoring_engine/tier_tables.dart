/// Complete performance tier reference data for the OVR99 Assessment Engine.
///
/// Contains ALL tier thresholds for 8 events × 4 grades × (2 or 3) profiles.
///   Power events (3 profiles each): squat, bench_press, power_clean, dead_lift
///   Speed events (2 profiles each): 40_yard_dash, 20_yard_dash, vertical_jump,
///                                    standing_long_jump
///
/// Lookup pattern: `tierTables[eventName][grade][profile]`
///
/// Reference: OVR99 Athlete Calculation Scope, Section 7.

import 'scoring_engine.dart' show TierThresholds;

/// Master lookup table:
///   eventName → grade → profile → [TierThresholds].
final Map<String, Map<int, Map<String, TierThresholds>>> tierTables = {
  // ═══════════════════════════════════════════════════════════════════════════
  // POWER EVENTS  (lowerIsBetter: false, profiles: light / medium / heavy)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── SQUAT (lbs) ──────────────────────────────────────────────────────────
  'squat': {
    7: {
      'light': const TierThresholds(
        good: 145, great: 180, allState: 200, allAmerican: 215,
      ),
      'medium': const TierThresholds(
        good: 165, great: 210, allState: 250, allAmerican: 255,
      ),
      'heavy': const TierThresholds(
        good: 195, great: 240, allState: 285, allAmerican: 295,
      ),
    },
    8: {
      'light': const TierThresholds(
        good: 160, great: 200, allState: 225, allAmerican: 245,
      ),
      'medium': const TierThresholds(
        good: 185, great: 230, allState: 265, allAmerican: 290,
      ),
      'heavy': const TierThresholds(
        good: 210, great: 250, allState: 300, allAmerican: 330,
      ),
    },
    9: {
      'light': const TierThresholds(
        good: 200, great: 250, allState: 275, allAmerican: 300,
      ),
      'medium': const TierThresholds(
        good: 225, great: 275, allState: 315, allAmerican: 350,
      ),
      'heavy': const TierThresholds(
        good: 250, great: 300, allState: 350, allAmerican: 400,
      ),
    },
    10: {
      'light': const TierThresholds(
        good: 220, great: 275, allState: 300, allAmerican: 330,
      ),
      'medium': const TierThresholds(
        good: 240, great: 295, allState: 335, allAmerican: 380,
      ),
      'heavy': const TierThresholds(
        good: 265, great: 315, allState: 365, allAmerican: 430,
      ),
    },
    11: {
      'light': const TierThresholds(
        good: 240, great: 300, allState: 325, allAmerican: 360,
      ),
      'medium': const TierThresholds(
        good: 260, great: 315, allState: 355, allAmerican: 410,
      ),
      'heavy': const TierThresholds(
        good: 280, great: 330, allState: 380, allAmerican: 460,
      ),
    },
    12: {
      'light': const TierThresholds(
        good: 260, great: 325, allState: 350, allAmerican: 390,
      ),
      'medium': const TierThresholds(
        good: 280, great: 335, allState: 375, allAmerican: 445,
      ),
      'heavy': const TierThresholds(
        good: 300, great: 350, allState: 400, allAmerican: 500,
      ),
    },
  },

  // ── BENCH PRESS (lbs) ────────────────────────────────────────────────────
  'bench_press': {
    7: {
      'light': const TierThresholds(
        good: 90, great: 110, allState: 125, allAmerican: 145,
      ),
      'medium': const TierThresholds(
        good: 125, great: 140, allState: 165, allAmerican: 195,
      ),
      'heavy': const TierThresholds(
        good: 160, great: 180, allState: 205, allAmerican: 240,
      ),
    },
    8: {
      'light': const TierThresholds(
        good: 100, great: 120, allState: 140, allAmerican: 160,
      ),
      'medium': const TierThresholds(
        good: 135, great: 155, allState: 180, allAmerican: 205,
      ),
      'heavy': const TierThresholds(
        good: 160, great: 190, allState: 220, allAmerican: 250,
      ),
    },
    9: {
      'light': const TierThresholds(
        good: 125, great: 150, allState: 175, allAmerican: 200,
      ),
      'medium': const TierThresholds(
        good: 155, great: 185, allState: 220, allAmerican: 250,
      ),
      'heavy': const TierThresholds(
        good: 185, great: 220, allState: 260, allAmerican: 300,
      ),
    },
    10: {
      'light': const TierThresholds(
        good: 135, great: 160, allState: 190, allAmerican: 220,
      ),
      'medium': const TierThresholds(
        good: 165, great: 195, allState: 230, allAmerican: 270,
      ),
      'heavy': const TierThresholds(
        good: 190, great: 230, allState: 270, allAmerican: 315,
      ),
    },
    11: {
      'light': const TierThresholds(
        good: 150, great: 175, allState: 210, allAmerican: 240,
      ),
      'medium': const TierThresholds(
        good: 175, great: 210, allState: 250, allAmerican: 285,
      ),
      'heavy': const TierThresholds(
        good: 195, great: 240, allState: 285, allAmerican: 330,
      ),
    },
    12: {
      'light': const TierThresholds(
        good: 160, great: 195, allState: 225, allAmerican: 260,
      ),
      'medium': const TierThresholds(
        good: 180, great: 225, allState: 265, allAmerican: 305,
      ),
      'heavy': const TierThresholds(
        good: 200, great: 250, allState: 300, allAmerican: 350,
      ),
    },
  },

  // ── POWER CLEAN (lbs) ────────────────────────────────────────────────────
  'power_clean': {
    7: {
      'light': const TierThresholds(
        good: 75, great: 90, allState: 110, allAmerican: 110,
      ),
      'medium': const TierThresholds(
        good: 110, great: 115, allState: 130, allAmerican: 140,
      ),
      'heavy': const TierThresholds(
        good: 135, great: 150, allState: 160, allAmerican: 180,
      ),
    },
    8: {
      'light': const TierThresholds(
        good: 85, great: 100, allState: 120, allAmerican: 125,
      ),
      'medium': const TierThresholds(
        good: 110, great: 125, allState: 145, allAmerican: 160,
      ),
      'heavy': const TierThresholds(
        good: 140, great: 160, allState: 170, allAmerican: 200,
      ),
    },
    9: {
      'light': const TierThresholds(
        good: 110, great: 125, allState: 150, allAmerican: 160,
      ),
      'medium': const TierThresholds(
        good: 135, great: 155, allState: 175, allAmerican: 200,
      ),
      'heavy': const TierThresholds(
        good: 160, great: 185, allState: 205, allAmerican: 240,
      ),
    },
    10: {
      'light': const TierThresholds(
        good: 120, great: 135, allState: 165, allAmerican: 175,
      ),
      'medium': const TierThresholds(
        good: 145, great: 165, allState: 195, allAmerican: 215,
      ),
      'heavy': const TierThresholds(
        good: 165, great: 195, allState: 220, allAmerican: 260,
      ),
    },
    11: {
      'light': const TierThresholds(
        good: 135, great: 150, allState: 180, allAmerican: 195,
      ),
      'medium': const TierThresholds(
        good: 155, great: 180, allState: 210, allAmerican: 240,
      ),
      'heavy': const TierThresholds(
        good: 170, great: 205, allState: 235, allAmerican: 280,
      ),
    },
    12: {
      'light': const TierThresholds(
        good: 145, great: 160, allState: 195, allAmerican: 215,
      ),
      'medium': const TierThresholds(
        good: 160, great: 190, allState: 225, allAmerican: 260,
      ),
      'heavy': const TierThresholds(
        good: 175, great: 215, allState: 250, allAmerican: 300,
      ),
    },
  },

  // ── DEAD LIFT (lbs) ──────────────────────────────────────────────────────
  'dead_lift': {
    7: {
      'light': const TierThresholds(
        good: 180, great: 215, allState: 235, allAmerican: 250,
      ),
      'medium': const TierThresholds(
        good: 235, great: 255, allState: 290, allAmerican: 300,
      ),
      'heavy': const TierThresholds(
        good: 290, great: 295, allState: 340, allAmerican: 350,
      ),
    },
    8: {
      'light': const TierThresholds(
        good: 200, great: 245, allState: 265, allAmerican: 285,
      ),
      'medium': const TierThresholds(
        good: 250, great: 290, allState: 320, allAmerican: 340,
      ),
      'heavy': const TierThresholds(
        good: 305, great: 330, allState: 370, allAmerican: 385,
      ),
    },
    9: {
      'light': const TierThresholds(
        good: 250, great: 300, allState: 325, allAmerican: 350,
      ),
      'medium': const TierThresholds(
        good: 300, great: 350, allState: 390, allAmerican: 415,
      ),
      'heavy': const TierThresholds(
        good: 350, great: 400, allState: 450, allAmerican: 480,
      ),
    },
    10: {
      'light': const TierThresholds(
        good: 275, great: 330, allState: 355, allAmerican: 385,
      ),
      'medium': const TierThresholds(
        good: 325, great: 380, allState: 415, allAmerican: 445,
      ),
      'heavy': const TierThresholds(
        good: 375, great: 425, allState: 475, allAmerican: 500,
      ),
    },
    11: {
      'light': const TierThresholds(
        good: 300, great: 360, allState: 390, allAmerican: 420,
      ),
      'medium': const TierThresholds(
        good: 345, great: 420, allState: 440, allAmerican: 470,
      ),
      'heavy': const TierThresholds(
        good: 390, great: 460, allState: 490, allAmerican: 520,
      ),
    },
    12: {
      'light': const TierThresholds(
        good: 325, great: 390, allState: 420, allAmerican: 455,
      ),
      'medium': const TierThresholds(
        good: 365, great: 445, allState: 485, allAmerican: 530,
      ),
      'heavy': const TierThresholds(
        good: 400, great: 500, allState: 550, allAmerican: 600,
      ),
    },
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // SPEED EVENTS  (profiles: standard / heavy)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── 40-YARD DASH (seconds — lower is better) ────────────────────────────
  '40_yard_dash': {
    7: {
      'standard': const TierThresholds(
        good: 6.0, great: 5.6, allState: 5.35, allAmerican: 5.2,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 6.25, great: 5.85, allState: 5.65, allAmerican: 5.55,
        lowerIsBetter: true,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 5.6, great: 5.25, allState: 5.05, allAmerican: 4.95,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.9, great: 5.5, allState: 5.35, allAmerican: 5.25,
        lowerIsBetter: true,
      ),
    },
    9: {
      'standard': const TierThresholds(
        good: 5.25, great: 4.95, allState: 4.75, allAmerican: 4.65,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.50, great: 5.20, allState: 5.05, allAmerican: 4.95,
        lowerIsBetter: true,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 5.20, great: 4.90, allState: 4.70, allAmerican: 4.60,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.40, great: 5.10, allState: 5.00, allAmerican: 4.90,
        lowerIsBetter: true,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 5.10, great: 4.85, allState: 4.65, allAmerican: 4.55,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.30, great: 5.05, allState: 4.95, allAmerican: 4.85,
        lowerIsBetter: true,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 5.00, great: 4.75, allState: 4.60, allAmerican: 4.50,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.20, great: 5.00, allState: 4.90, allAmerican: 4.80,
        lowerIsBetter: true,
      ),
    },
  },

  // ── 10-YARD FLY (seconds — lower is better) ─────────────────────────────
  //
  // NOTE: Kept legacy key '20_yard_dash' for backward compatibility.
  '10_yard_fly': {
    7: {
      'standard': const TierThresholds(
        good: 1.35, great: 1.20, allState: 1.15, allAmerican: 1.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.40, great: 1.30, allState: 1.20, allAmerican: 1.20,
        lowerIsBetter: true,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 1.25, great: 1.15, allState: 1.05, allAmerican: 1.05,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.30, great: 1.20, allState: 1.15, allAmerican: 1.15,
        lowerIsBetter: true,
      ),
    },
    9: {
      'standard': const TierThresholds(
        good: 1.16, great: 1.07, allState: 1.01, allAmerican: 0.98,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.23, great: 1.14, allState: 1.09, allAmerican: 1.07,
        lowerIsBetter: true,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 1.14, great: 1.05, allState: 0.99, allAmerican: 0.96,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.20, great: 1.11, allState: 1.08, allAmerican: 1.05,
        lowerIsBetter: true,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 1.11, great: 1.03, allState: 0.98, allAmerican: 0.95,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.17, great: 1.09, allState: 1.07, allAmerican: 1.03,
        lowerIsBetter: true,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 1.08, great: 1.01, allState: 0.96, allAmerican: 0.93,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.14, great: 1.08, allState: 1.05, allAmerican: 1.02,
        lowerIsBetter: true,
      ),
    },
  },

  // ── 5-10-5 PRO AGILITY SHUTTLE (seconds — lower is better) ──────────────
  //
  // Tier buckets: `good` and `allAmerican` are the user-provided official
  // norms; `great` / `allState` are linearly interpolated for display parity
  // with other speed events (scoring only consumes `good`/`allAmerican`).
  'shuttle_5_10_5': {
    // Middle School — standard profile
    7: {
      'standard': const TierThresholds(
        good: 4.80, great: 4.60, allState: 4.48, allAmerican: 4.40,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.00, great: 4.80, allState: 4.68, allAmerican: 4.60,
        lowerIsBetter: true,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 4.80, great: 4.60, allState: 4.48, allAmerican: 4.40,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 5.00, great: 4.80, allState: 4.68, allAmerican: 4.60,
        lowerIsBetter: true,
      ),
    },
    // High School — standard profile
    9: {
      'standard': const TierThresholds(
        good: 4.50, great: 4.30, allState: 4.18, allAmerican: 4.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 4.80, great: 4.55, allState: 4.40, allAmerican: 4.30,
        lowerIsBetter: true,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 4.50, great: 4.30, allState: 4.18, allAmerican: 4.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 4.80, great: 4.55, allState: 4.40, allAmerican: 4.30,
        lowerIsBetter: true,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 4.50, great: 4.30, allState: 4.18, allAmerican: 4.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 4.80, great: 4.55, allState: 4.40, allAmerican: 4.30,
        lowerIsBetter: true,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 4.50, great: 4.30, allState: 4.18, allAmerican: 4.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 4.80, great: 4.55, allState: 4.40, allAmerican: 4.30,
        lowerIsBetter: true,
      ),
    },
  },

  // Legacy alias (old key name used by earlier builds)
  '20_yard_dash': {
    7: {
      'standard': const TierThresholds(
        good: 1.35, great: 1.20, allState: 1.15, allAmerican: 1.10,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.40, great: 1.30, allState: 1.20, allAmerican: 1.20,
        lowerIsBetter: true,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 1.25, great: 1.15, allState: 1.05, allAmerican: 1.05,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.30, great: 1.20, allState: 1.15, allAmerican: 1.15,
        lowerIsBetter: true,
      ),
    },
    9: {
      'standard': const TierThresholds(
        good: 1.16, great: 1.07, allState: 1.01, allAmerican: 0.98,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.23, great: 1.14, allState: 1.09, allAmerican: 1.07,
        lowerIsBetter: true,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 1.14, great: 1.05, allState: 0.99, allAmerican: 0.96,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.20, great: 1.11, allState: 1.08, allAmerican: 1.05,
        lowerIsBetter: true,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 1.11, great: 1.03, allState: 0.98, allAmerican: 0.95,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.17, great: 1.09, allState: 1.07, allAmerican: 1.03,
        lowerIsBetter: true,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 1.08, great: 1.01, allState: 0.96, allAmerican: 0.93,
        lowerIsBetter: true,
      ),
      'heavy': const TierThresholds(
        good: 1.14, great: 1.08, allState: 1.05, allAmerican: 1.02,
        lowerIsBetter: true,
      ),
    },
  },

  // ── VERTICAL JUMP (inches — higher is better) ───────────────────────────
  'vertical_jump': {
    7: {
      'standard': const TierThresholds(
        good: 13, great: 22, allState: 24, allAmerican: 27,
      ),
      'heavy': const TierThresholds(
        good: 10, great: 19, allState: 21, allAmerican: 23,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 15, great: 24, allState: 27, allAmerican: 29,
      ),
      'heavy': const TierThresholds(
        good: 12, great: 21, allState: 23, allAmerican: 25,
      ),
    },
    9: {
      'standard': const TierThresholds(
        good: 18, great: 26, allState: 29, allAmerican: 32,
      ),
      'heavy': const TierThresholds(
        good: 15, great: 23, allState: 25, allAmerican: 27,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 20, great: 27, allState: 30, allAmerican: 33,
      ),
      'heavy': const TierThresholds(
        good: 17, great: 24, allState: 26, allAmerican: 28,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 22, great: 28, allState: 31, allAmerican: 34,
      ),
      'heavy': const TierThresholds(
        good: 19, great: 25, allState: 27, allAmerican: 29,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 24, great: 29, allState: 32, allAmerican: 35,
      ),
      'heavy': const TierThresholds(
        good: 21, great: 26, allState: 28, allAmerican: 30,
      ),
    },
  },

  // ── STANDING LONG JUMP (inches — higher is better) ──────────────────────
  'standing_long_jump': {
    7: {
      'standard': const TierThresholds(
        good: 76, great: 84, allState: 86, allAmerican: 90,
      ),
      'heavy': const TierThresholds(
        good: 70, great: 78, allState: 82, allAmerican: 85,
      ),
    },
    8: {
      'standard': const TierThresholds(
        good: 83, great: 91, allState: 95, allAmerican: 100,
      ),
      'heavy': const TierThresholds(
        good: 77, great: 86, allState: 88, allAmerican: 95,
      ),
    },
    9: {
      'standard': const TierThresholds(
        good: 90, great: 99, allState: 105, allAmerican: 111,
      ),
      'heavy': const TierThresholds(
        good: 84, great: 93, allState: 99, allAmerican: 105,
      ),
    },
    10: {
      'standard': const TierThresholds(
        good: 93, great: 102, allState: 109, allAmerican: 115,
      ),
      'heavy': const TierThresholds(
        good: 87, great: 96, allState: 103, allAmerican: 109,
      ),
    },
    11: {
      'standard': const TierThresholds(
        good: 96, great: 105, allState: 114, allAmerican: 120,
      ),
      'heavy': const TierThresholds(
        good: 90, great: 99, allState: 111, allAmerican: 115,
      ),
    },
    12: {
      'standard': const TierThresholds(
        good: 99, great: 108, allState: 120, allAmerican: 126,
      ),
      'heavy': const TierThresholds(
        good: 93, great: 102, allState: 114, allAmerican: 120,
      ),
    },
  },
};
