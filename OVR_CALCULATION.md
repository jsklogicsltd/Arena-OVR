# Arena OVR — OVR Calculations (Manual + Assessments + Final)

This document summarizes how OVR is computed in the app flows driven by the coach **Award** screen (`lib/app/modules/coach/views/award_points_view.dart`).

It covers:
- Manual ratings (points) → manual OVR
- Assessment entry (SQ/BP/40yd/GPA) → automated OVR
- Final OVR shown to coaches/players

---

## Data fields involved (Firestore `users/{uid}`)

- **Manual rating fields**
  - `currentRating` (Map): bucket points by parent category
    - keys: `Athlete`, `Student`, `Teammate`, `Citizen`
    - values: numeric points (clamped 0..100 during OVR calc)
  - `ovr` (int): **displayed** manual OVR (after daily cap)
  - `actualOvr` (int): **uncapped** manual OVR (raw)
  - `ovrDay` (int?): season day used for cap logic
  - `ovrCap` (int?): daily cap for that day

- **Assessment fields**
  - `assessmentData` (Map): raw assessment inputs and derived values:
    - raw inputs: `squat`, `bench_press`, `40_yard_dash`, `gpa`
    - derived: `powerNumber`, `speedNumber`, `topPerformancePoints`, `updatedAt`
  - `automatedOvr` (int): automated/assessment OVR (team-relative, see below)

---

## 1) Manual Ratings → Manual OVR

### Where it happens
From the Award screen (Manual tab), the app creates `transactions` and then recalculates OVR:

- Awards are written as transactions (category + subcategory + value).
- Then `RatingRepository.recalculateOvr(teamId, seasonId)` recomputes each athlete’s manual OVR.

### Inputs
For each athlete, per season:
- \(A\) = Athlete bucket points (0..100)
- \(S\) = Student bucket points (0..100)
- \(T\) = Teammate bucket points (0..100)
- \(C\) = Citizen bucket points (0..100)

These are derived by summing season transactions and then clamping each bucket:

- \(A = clamp(sum(athlete-category transactions), 0, 100)\)
- \(S = clamp(sum(student-category transactions), 0, 100)\)
- \(T = clamp(sum(teammate-category transactions), 0, 100)\)
- \(C = clamp(sum(citizen-category transactions), 0, 100)\)

### Weighted score (the “raw” part)
In `OvrEngineService.calculateOvr`:

\[
raw = 0.99 \times (0.4A + 0.2S + 0.2T + 0.2C)
\]

### Actual manual OVR (uncapped)
\[
actualOvr = clamp(50 + round(raw), 0, 99)
\]

### Displayed manual OVR (daily cap)
Let `cap(day)` be:
- Day 1: 0 (hidden/locked)
- Day 2: 79
- Day 3: 82
- Day 4: 85
- Day 5: 88
- Day 6: 91
- Day 7: 94
- Day 8: 97
- Day 9..15: 99

Then:
- If day == 1 → `displayedOvr = null` (stored as `ovr` = 0 or left as-is depending on caller; UI treats it as locked)
- Else:

\[
ovr = min(actualOvr, cap(day))
\]

### Stored output
`recalculateOvr` writes:
- `currentRating = { Athlete: A, Student: S, Teammate: T, Citizen: C }`
- `actualOvr = actualOvr`
- `ovr = displayedOvr` (or 0 if null)
- `ovrDay = day`
- `ovrCap = cap(day)`

---

## 2) Assessments → Automated OVR

### Where it happens
From the Award screen (Assessments tab), coaches enter:
- Squat (SQ)
- Bench Press (BP)
- 40-yard dash (40yd)
- GPA

Then `CoachController.submitBulkAssessments()`:
- Scores the raw events into **Performance Points**
- Computes athlete “numbers” (Power/Speed/Top Performance)
- Computes **team-relative automated OVR**
- Writes `assessmentData` + `automatedOvr` back to `users/{uid}`

### Step 4 — Raw performance → Performance Points (PP, 30..99)
For an event with thresholds:
- `Good`
- `AllAmerican`
- plus a flag `lowerIsBetter` (true for dash events, false for lifts)

**Formula A (higher is better — squat/bench):**

\[
PP = 30 + \left(\frac{raw - Good}{AllAmerican - Good}\right)\times 69
\]
Rounded **up** (ceil), then capped to 99. Boundary rules:
- raw ≤ Good → 30
- raw ≥ AllAmerican → 99

**Formula B (lower is better — 40yd):**

\[
PP = 30 + \left(\frac{Good - raw}{Good - AllAmerican}\right)\times 69
\]
Rounded **up** (ceil), then capped to 99. Boundary rules:
- raw ≥ Good → 30
- raw ≤ AllAmerican → 99

Thresholds are looked up from tier tables by:
- event name (`squat`, `bench_press`, `40_yard_dash`)
- grade
- profile (`powerProfile` or `speedProfile`)

### Step 5 — Athlete numbers
Given:
- `powerScores` = list of PP from squat/bench (whichever are present)
- `speedScores` = list of PP from 40yd (if present)

If both lists exist:

\[
powerNumber = ceil(avg(powerScores))
\]
\[
speedNumber = ceil(avg(speedScores))
\]
\[
topPerformancePoints = ceil\left(\frac{powerNumber + speedNumber}{2}\right)
\]

If **only powerScores** exist:
- `automatedOvr = powerNumber`

If **only speedScores** exist:
- `automatedOvr = speedNumber`

If both exist at this step:
- `automatedOvr = topPerformancePoints` (temporary value used before team-relative ranking)

### Step 6 — Team-relative automated OVR ranking
For the whole team, build a map:
- `playerPoints[uid] = topPerformancePoints` (or the single-number case)

Determine season phase cap:
- Phase 1 cap = 79
- Phase 2 cap = 89
- Phase 3 cap = 99

Let:
- \(P_i\) = that athlete’s points
- \(P_{max}\) = max points in the team
- `cap` = phase cap

Then the **team-relative automated OVR** is:

\[
automatedOvr_i = \min(cap,\ \lceil (P_i / P_{max}) \times cap \rceil)
\]

This is why changing one athlete can change everyone: it’s relative to the best athlete.

### Stored output
For each modified athlete (step A) the app writes:
- `assessmentData` map (raw + derived)
- `automatedOvr` (after step B recalculation for the whole roster)

---

## 3) Final OVR (Manual + Automated)

Final OVR is computed in `UserModel.finalOvr` and used everywhere coaches see OVR:
- `coachVisibleOvr == finalOvr`

Let:
- `manual = actualOvr if actualOvr > 0 else ovr`
- `auto = automatedOvr`

Rules:
- If `auto` is null or 0 → **final = manual**
- If `manual` is 0 → **final = auto**
- Else:

\[
finalOvr = clamp(round((manual + auto) / 2),\ 0,\ 99)
\]

---

## Quick cheat-sheet

- **Manual points buckets**: sum season transactions → clamp 0..100 → weighted sum → \(50 + round(0.99 \times weighted)\) → daily cap.
- **Assessments**: raw event → PP(30..99) → power/speed/topPerf (ceil averages) → team-relative ranking to cap(79/89/99).
- **Final OVR**: average of manual (prefers `actualOvr`) and `automatedOvr` when both exist.

