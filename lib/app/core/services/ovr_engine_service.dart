/// Season calendar helpers for player UI (day-in-season and dynamic phase cap).
///
/// Subjective OVR is computed elsewhere (equal average of four buckets + curve).
/// This file intentionally contains **no** legacy 0.4/0.2 weighted bucket math.
class SeasonOvrUi {
  SeasonOvrUi._();

  /// Returns season day clamped to [1..seasonLengthDays].
  static int calculateSeasonDay({
    required DateTime seasonStartDate,
    required DateTime currentDate,
    int seasonLengthDays = 15,
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
    final totalDays = seasonLengthDays.clamp(7, 365);
    if (day < 1) return 1;
    if (day > totalDays) return totalDays;
    return day;
  }

  static int phaseCapForDay({
    required int day,
    required int seasonLengthDays,
    required int startingOvrBaseline,
  }) {
    final totalDays = seasonLengthDays.clamp(7, 365);
    final safeDay = day.clamp(1, totalDays);
    final baseline = startingOvrBaseline.clamp(0, 90);
    final earnablePoints = 99 - baseline;
    final phase1EndDay = (totalDays / 3.0).ceil();
    final phase2EndDay = ((totalDays * 2.0) / 3.0).ceil();
    if (safeDay <= phase1EndDay) {
      return baseline + (earnablePoints / 3.0).floor();
    }
    if (safeDay <= phase2EndDay) {
      return baseline + ((earnablePoints * 2.0) / 3.0).floor();
    }
    return 99;
  }
}
