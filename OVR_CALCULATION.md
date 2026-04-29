# Arena OVR — OVR Calculations (Manual + Assessments + Final)

This document summarizes how OVR is computed in the app flows driven by the coach **Award** screen (`lib/app/modules/coach/views/award_points_view.dart`).

It covers:
- Manual ratings (points) → "Top Dawg" subjective OVR
- Assessment entry (SQ/BP/PC/DL/40yd/10yd/VJ/BJ/Shuttle/GPA) → automated assessment value
- Final OVR shown to coaches/players (50/50 combined curve + gating)

---

## Data fields involved (Firestore `users/{uid}`)

- **Manual rating fields**
  - `currentRating` (Map): **scaled** bucket scores by parent category
    - keys: `Athlete`, `Student`, `Teammate`, `Citizen`
    - values: integers 0–99 (scaled relative to team Top Dawg per category)
  - `ovr` (int): Top Dawg-curved manual OVR (average of the 4 scaled buckets)
  - `actualOvr` (int): same as `ovr` (no daily cap in v2.0)

- **Assessment fields**
  - `assessmentData` (Map): raw assessment inputs and derived values:
    - raw inputs: `squat`, `bench_press`, `power_clean`, `dead_lift`, `40_yard_dash`, `10_yard_fly`, `shuttle_5_10_5`, `vertical_jump`, `standing_long_jump`, `gpa`
    - derived: `powerNumber`, `speedNumber`, `topPerformancePoints`, `updatedAt`

- **Combined / Final fields**
  - `finalOvr` (int): the final displayed OVR (after 50/50 curve + Top Dawg gating)

---

## 1) Manual Ratings → "Top Dawg" Subjective OVR

### Where it happens
From the Award screen (Manual tab), the app creates `transactions` and then recalculates OVR:

- Awards are written as transactions (category + subcategory + value).
- Then `RatingRepository.recalculateOvr(teamId, seasonId)` recomputes each athlete's manual OVR.

### Phase 1: Accumulate raw bucket totals

For each athlete, per season:
- \(A_{raw}\) = sum of all Athlete/Competitor/Performance transactions
- \(S_{raw}\) = sum of all Student/Class/Classroom transactions
- \(T_{raw}\) = sum of all Teammate/Program transactions
- \(C_{raw}\) = sum of all Citizen/Standard transactions

**Important:** Raw totals are NOT clamped to 0–99. They accumulate freely so the Top Dawg pre-pass can identify the true team leader in each category.

### Phase 2: Top Dawg pre-pass (roster-relative scaling)

Before calculating any individual OVR, the engine iterates the entire roster to find the highest raw total in each bucket:

\[
maxAthRaw = \max_{roster}(A_{raw})
\]
\[
maxStuRaw = \max_{roster}(S_{raw})
\]
\[
maxTmRaw = \max_{roster}(T_{raw})
\]
\[
maxCitRaw = \max_{roster}(C_{raw})
\]

### Phase 3: Scale each athlete's buckets against Top Dawg

For each athlete and each bucket:

\[
\text{if } maxBucketRaw > 0: \quad bucketScore = \text{round}\left(\frac{playerBucketRaw}{maxBucketRaw} \times 99\right)
\]

\[
\text{if } maxBucketRaw = 0: \quad bucketScore = 0
\]

This produces 4 scaled scores (each 0–99) per athlete:
- `athleteScore`, `studentScore`, `teammateScore`, `citizenScore`

The team's **Top Dawg** in any category always maps to 99 in that category.

### Phase 4: Calculate `manualOvr`

\[
manualBase = \frac{athleteScore + studentScore + teammateScore + citizenScore}{4}
\]

\[
manualOvr = \text{round}(manualBase)
\]

### Stored output
`recalculateOvr` writes:
- `currentRating = { Athlete: athleteScore, Student: studentScore, Teammate: teammateScore, Citizen: citizenScore }`
- `actualOvr = manualOvr`
- `ovr = manualOvr`

### Example

Roster of 3 athletes with raw bucket totals:

| Athlete | Ath raw | Stu raw | Tm raw | Cit raw |
|---------|---------|---------|--------|---------|
| Player A | 120 | 80 | 60 | 40 |
| Player B | 90 | 100 | 45 | 30 |
| Player C | 60 | 50 | 90 | 80 |

**Top Dawg maxima:** Ath=120, Stu=100, Tm=90, Cit=80

**Player A scaled:**
- Ath: round(120/120 × 99) = **99**
- Stu: round(80/100 × 99) = **79**
- Tm: round(60/90 × 99) = **66**
- Cit: round(40/80 × 99) = **50**
- manualOvr = round((99+79+66+50)/4) = round(73.5) = **74**

---

## 2) Assessments → Assessment Value (Objective 50%)

### Where it happens
From the Award screen (Assessments tab), coaches enter raw physical metrics and GPA.

Then `CoachController.submitBulkAssessments()`:
- Scores the raw events into **Performance Points**
- Computes athlete "numbers" (Power/Speed/Top Performance)
- Writes `assessmentData` back to `users/{uid}`

### Step 4 — Raw performance → Performance Points (PP, 30..99)
For an event with thresholds:
- `Good`
- `AllAmerican`
- plus a flag `lowerIsBetter` (true for timed events, false for lifts/jumps)

**Formula A (higher is better — lifts/jumps):**

\[
PP = 30 + \left(\frac{raw - Good}{AllAmerican - Good}\right)\times 69
\]
Rounded **up** (ceil), then capped to 99. Boundary rules:
- raw ≤ Good → 30
- raw ≥ AllAmerican → 99

**Formula B (lower is better — timed events):**

\[
PP = 30 + \left(\frac{Good - raw}{Good - AllAmerican}\right)\times 69
\]
Rounded **up** (ceil), then capped to 99. Boundary rules:
- raw ≥ Good → 30
- raw ≤ AllAmerican → 99

Thresholds are looked up from tier tables by:
- event name (e.g. `squat`, `bench_press`, `40_yard_dash`, `10_yard_fly`, etc.)
- grade (7–12)
- profile (`powerProfile`: light/medium/heavy; `speedProfile`: standard/heavy)

### Step 5 — Athlete numbers
Given:
- `powerScores` = list of PP from squat/bench/power clean/dead lift
- `speedScores` = list of PP from 40yd/10yd fly/shuttle/vertical jump/standing long jump

If both lists exist:

\[
powerNumber = \lceil avg(powerScores) \rceil
\]
\[
speedNumber = \lceil avg(speedScores) \rceil
\]
\[
topPerformancePoints = \lceil (powerNumber + speedNumber) / 2 \rceil
\]

### Step 5C — GPA normalization (0 to 99)

\[
gpaScore=
\begin{cases}
0, & gpa \le 0 \\
99, & gpa \ge 3.5 \\
\lceil (gpa/3.5)\times 99 \rceil, & \text{otherwise}
\end{cases}
\]

### Step 5D — Assessment Value (max 49.50)

\[
assessmentValue = 0.20 \times powerNumber + 0.20 \times speedNumber + 0.10 \times gpaScore
\]

---

## 3) Final OVR (50/50 Combined Score → Curve → Gates)

### Combined Score

\[
manualInputValue = \max(0, \text{manualOvr} - \text{baseline}) \times 0.50
\]

\[
combinedScore = assessmentValue + manualInputValue
\]

Where:
- `assessmentValue` = objective half (0..49.5)
- `manualInputValue` = subjective half above baseline (0..49.5)

### Curve (team-relative scaling)

For athlete \(i\):

\[
raw_i = \frac{combined_i}{highestCombined} \times (cap - baseline_i)
\]

\[
curveOvr_i = clamp(baseline_i + \lceil raw_i \rceil, \ baseline_i, \ cap)
\]

Current implementation: `cap = 99` (phase throttling disabled).

### Top Dawg Gating Hierarchy (replaces old milestone gates)

After the curve OVR is computed, the following strict gates are applied using the **scaled bucket scores** from Phase 3:

**Gate 1 — Zero Category Hard Cap (strictest):**
If ANY of the 4 scaled bucket scores equals exactly 0:

\[
finalOvr = \min(curveOvr, 84)
\]

**Gate 2 — Subjective 80 Gate:**
If they passed the zero check, but overall manualOvr < 80 and curveOvr ≥ 90:

\[
finalOvr = 89
\]

**Gate 3 — Otherwise (full OVR allowed):**

\[
finalOvr = curveOvr
\]

After gating, `finalOvr` is clamped to never drop below the athlete's own baseline.

### Stored output
- `finalOvr` is written to `users/{uid}` (single source of truth for display)
- `averageOvr` on the team doc is updated as the mean of all roster `finalOvr` values

---

## Quick Cheat-Sheet

- **Manual points buckets**: sum season transactions (unclamped) → Top Dawg pre-pass finds max per category → each bucket scaled 0–99 relative to team leader → average of 4 buckets = manualOvr.
- **Assessments**: raw event → PP(30..99) → power/speed numbers (ceil averages) → assessmentValue (0..49.5).
- **Combined**: assessmentValue + manualInputValue (above-baseline contribution × 0.5).
- **Curve**: highest combined on roster → cap; everyone else proportional.
- **Gates**: zero-bucket → cap 84; manualOvr < 80 and curveOvr ≥ 90 → cap 89; otherwise full OVR.
- **Final OVR**: gated curved result, displayed as `finalOvr`.
