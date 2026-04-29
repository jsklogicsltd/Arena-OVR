# Arena OVR Scoring System (Complete Explanation)

This document explains the **current implemented logic** for OVR scoring from raw inputs all the way to final displayed OVR.

It is written for both:
- non-technical stakeholders (coaches, admins), and
- developers who need exact formulas to implement or validate behavior.

---

## 1. Overview of the Scoring System

### Purpose and use case

The scoring system is designed to rate athletes on a complete profile:
- **Subjective performance** (coach-rated categories over time), and
- **Objective assessment** (measured athletic tests + GPA),

then combine both into one **team-relative OVR** score.

It supports:
- fairness across a roster (curve model),
- roster-relative "Top Dawg" subjective scaling per category,
- strict gating hierarchy to protect elite OVR tiers,
- configurable starting baseline (for team context),
- max cap of 99.

### High-level flow

1. Coach awards rating transactions (subjective categories).
2. Optional assessment metrics are submitted (objective data).
3. **Top Dawg pre-pass**: team-wide maxima are found for each of the 4 subjective categories.
4. Each athlete's 4 bucket scores are scaled relative to the team's best in each category.
5. Scaled buckets are averaged into `manualOvr`.
6. Objective numbers are calculated from tier tables.
7. Subjective + objective combine into a single decimal score (50/50).
8. Team-wide curve converts combined score into `curveOvr`.
9. **Top Dawg gating hierarchy** caps elite tiers where subjective is lacking.
10. Final OVR is saved as `finalOvr` and displayed in app.

---

## 2. Subjective Scoring Logic — "Top Dawg" Curve

### What subjective means in this system

Subjective scoring is built from coach-awarded point transactions across four pillar buckets:

- **Competitor bucket**: `Athlete`, `Competitor`, `Performance`
- **Student bucket**: `Student`, `Class`, `Classroom`
- **Teammate bucket**: `Teammate`, `Program`
- **Citizen bucket**: `Citizen`, `Standard`

Each transaction contributes to one bucket via category mapping.

### Step 1: Accumulate raw bucket totals

For each athlete, per season:

\[
\text{bucketRaw} = \sum \text{all transaction values mapped to that bucket}
\]

**Important:** Raw bucket totals are NOT clamped. They accumulate freely (can exceed 99) so the Top Dawg pre-pass identifies the true team leader.

### Step 2: Top Dawg pre-pass (roster-wide)

Before any individual athlete is scored, the engine scans the **entire roster** to find the highest raw total in each of the 4 categories:

\[
maxAthRaw = \max_{\text{roster}}(A_{raw}), \quad
maxStuRaw = \max_{\text{roster}}(S_{raw}), \quad
maxTmRaw = \max_{\text{roster}}(T_{raw}), \quad
maxCitRaw = \max_{\text{roster}}(C_{raw})
\]

### Step 3: Scale each athlete against the Top Dawg

For each athlete and each bucket:

\[
\text{if } maxBucketRaw > 0: \quad bucketScore = \text{round}\left(\frac{playerBucketRaw}{maxBucketRaw} \times 99\right)
\]

\[
\text{if } maxBucketRaw = 0: \quad bucketScore = 0 \quad \text{(division-by-zero safe)}
\]

This produces 4 **scaled** scores (each 0–99) per athlete:
- `athleteScore`, `studentScore`, `teammateScore`, `citizenScore`

The team's **Top Dawg** in any given category always maps to **99** for that category. Everyone else scales proportionally.

### Step 4: Calculate `manualOvr`

\[
manualBase = \frac{athleteScore + studentScore + teammateScore + citizenScore}{4}
\]

\[
manualOvr = \text{round}(manualBase)
\]

### Weighting

Subjective contributes **50%** to final combined score, but only the part above baseline counts for lift:

\[
manualInputValue =
\max(0, \text{manualOvr} - \text{baseline}) \times 0.50
\]

This prevents baseline-only athletes from being lifted by the curve.

### Subjective example

Roster of 3 athletes with raw bucket totals:

| Athlete   | Ath raw | Stu raw | Tm raw | Cit raw |
|-----------|---------|---------|--------|---------|
| Player A  | 120     | 80      | 60     | 40      |
| Player B  | 90      | 100     | 45     | 30      |
| Player C  | 60      | 50      | 90     | 80      |

**Top Dawg maxima:** Ath=120, Stu=100, Tm=90, Cit=80

**Player A scaled:**
- Ath: round(120/120 × 99) = **99**
- Stu: round(80/100 × 99) = **79**
- Tm: round(60/90 × 99) = **66**
- Cit: round(40/80 × 99) = **50**
- manualOvr = round((99+79+66+50)/4) = round(73.5) = **74**

**Player B scaled:**
- Ath: round(90/120 × 99) = **74**
- Stu: round(100/100 × 99) = **99**
- Tm: round(45/90 × 99) = **50**
- Cit: round(30/80 × 99) = **37**
- manualOvr = round((74+99+50+37)/4) = round(65.0) = **65**

**Player C scaled:**
- Ath: round(60/120 × 99) = **50**
- Stu: round(50/100 × 99) = **50**
- Tm: round(90/90 × 99) = **99**
- Cit: round(80/80 × 99) = **99**
- manualOvr = round((50+50+99+99)/4) = round(74.5) = **75**

If baseline is 60:
- Player A: manualInputValue = (74−60) × 0.5 = 7.0
- Player B: manualInputValue = (65−60) × 0.5 = 2.5
- Player C: manualInputValue = (75−60) × 0.5 = 7.5

---

## 3. Objective Scoring Logic

### Objective metrics used

Objective values come from:
- **Power tests**: squat, bench press, power clean, dead lift
- **Speed/athletic tests**: 40-yard dash, 10-yard fly, vertical jump, standing long jump, 5-10-5 shuttle
- **GPA**

Each physical test is converted to a score using grade/profile tier thresholds.

### Physical event normalization (30 to 99)

Each event has thresholds: `Good`, `Great`, `AllState`, `AllAmerican`.
The engine maps raw value to **Performance Points (PP)** from 30 to 99.

#### Formula A (higher is better: lifts/jumps)

\[
PP = 30 + \left(\frac{raw - Good}{AllAmerican - Good}\right)\times 69
\]
Result is rounded up with ceiling and bounded to `[30, 99]`.

Boundary behavior:
- `raw <= Good` -> 30
- `raw >= AllAmerican` -> 99

#### Formula B (lower is better: timed events)

\[
PP = 30 + \left(\frac{Good - raw}{Good - AllAmerican}\right)\times 69
\]
Result is rounded up with ceiling and bounded to `[30, 99]`.

Boundary behavior:
- `raw >= Good` -> 30
- `raw <= AllAmerican` -> 99

### Power and Speed numbers

From all scored power events:

\[
\text{powerNumber}=\left\lceil \text{average(power event scores)} \right\rceil
\]

From all scored speed events:

\[
\text{speedNumber}=\left\lceil \text{average(speed event scores)} \right\rceil
\]

### GPA normalization (0 to 99)

\[
gpaScore=
\begin{cases}
0, & gpa \le 0 \\
99, & gpa \ge 3.5 \\
\left\lceil (gpa/3.5)\times 99 \right\rceil, & \text{otherwise}
\end{cases}
\]

### Objective 50% contribution

\[
\text{assessmentValue}=
0.20\times powerNumber + 0.20\times speedNumber + 0.10\times gpaScore
\]

Max objective contribution is 49.50.

### Objective examples

#### Power example
If scored power-event points are `[81, 74, 77, 79]`:

\[
powerNumber=\lceil(81+74+77+79)/4\rceil = \lceil77.75\rceil = 78
\]

#### Speed example
If scored speed-event points are `[72, 75, 70, 74]`:

\[
speedNumber=\lceil(72+75+70+74)/4\rceil = \lceil72.75\rceil = 73
\]

#### GPA example
If GPA is 3.2:

\[
gpaScore=\left\lceil(3.2/3.5)\times 99\right\rceil
=\lceil90.514...\rceil=91
\]

Then objective half:

\[
assessmentValue = 0.2(78)+0.2(73)+0.1(91)=15.6+14.6+9.1=39.3
\]

---

## 4. OVR (Overall Rating) Calculation

### How subjective and objective are combined

Combined score is:

\[
\text{combinedScore} = \text{assessmentValue} + \text{manualInputValue}
\]

Where:
- `assessmentValue` = objective half (0..49.5)
- `manualInputValue` = subjective half above baseline (0..49.5)

### Weight distribution

- Objective: 50%
- Subjective: 50%

### Step-by-step mini example

Assume:
- baseline = 60
- manualOvr = 74 -> manualInputValue = `(74-60)*0.5 = 7.0`
- assessmentValue = `39.3`

\[
\text{combinedScore}=39.3 + 7.0 = 46.3
\]

This 46.3 does **not** directly display as OVR.
It is fed into the team curve step next.

---

## 5. Curve / Scaling Logic

### Why curve is used

OVR is intentionally team-relative (like grading on a classroom curve).
The top combined score on the roster defines the reference point; everyone else scales against it.

### Formula

For athlete \(i\):

\[
raw_i = \left(\frac{combined_i}{highestCombined}\right)\times(cap-baseline_i)
\]

\[
curveOvr_i = clamp\left(baseline_i + \lceil raw_i \rceil,\ baseline_i,\ cap\right)
\]

Current implementation sets:
- `cap = 99` (phase throttling currently disabled)

If `highestCombined <= 0`, everyone returns exactly to own baseline.

### Curve example

Assume baseline 60, cap 99, highestCombined = 46.3.

- Athlete A combined = 46.3:
  \[
  raw = (46.3/46.3)\times39 = 39,\quad curveOvr=60+\lceil39\rceil=99
  \]

- Athlete B combined = 30:
  \[
  raw = (30/46.3)\times39 \approx 25.27,\quad curveOvr=60+\lceil25.27\rceil=86
  \]

- Athlete C combined = 0:
  \[
  raw=0,\quad curveOvr=60
  \]

---

## 6. Top Dawg Gating Hierarchy

After the curve OVR is computed, the **Top Dawg gating hierarchy** is applied using the 4 scaled subjective bucket scores from Section 2. This replaces the old milestone gates (92/88/80).

### Gate 1 — Zero Category Hard Cap (strictest, checked first)

If **ANY** of the athlete's 4 scaled bucket scores equals exactly 0, the athlete cannot reach 89:

\[
\text{if } (athleteScore = 0 \lor studentScore = 0 \lor teammateScore = 0 \lor citizenScore = 0):
\]
\[
finalOvr = \min(curveOvr, 84)
\]

**Why:** An athlete who has received zero points in an entire pillar of the program (e.g., zero Citizen transactions) should not be able to reach elite tiers regardless of how strong their objective or other subjective scores are.

### Gate 2 — Subjective 80 Gate

If they passed the zero check (no zero buckets), but their overall `manualOvr < 80` and their `curveOvr >= 90`:

\[
finalOvr = 89
\]

**Why:** An athlete whose overall subjective is weak (below 80 average across all 4 categories) should not cross into the 90+ elite tier.

### Gate 3 — Otherwise (full OVR allowed)

\[
finalOvr = curveOvr
\]

### Baseline floor

After gating, the engine ensures `finalOvr` never drops below the athlete's own baseline:

\[
finalOvr = \max(finalOvr, \text{athleteBaseline})
\]

### Rounding rules

- Event PP uses ceiling (round up)
- Power/Speed averages use ceiling
- GPA conversion uses ceiling
- Top Dawg bucket scaling uses `round`
- Manual base to manualOvr uses `round`
- Curve delta uses ceiling

### Caps and limits

- Baseline clamped to `[0, 90]`
- Intermediate/event scores clamped to valid ranges
- Final OVR clamped to `[baseline, 99]` before/after gates

### Display source in UI

Primary display OVR is `finalOvr`.
If missing, UI can fall back to manual values (`actualOvr` then `ovr`), then clamp to `[0, 99]`.

---

## 7. End-to-End Calculation Example

This shows one athlete from raw input to final displayed OVR.

### Inputs

- Team baseline: 60
- Athlete baseline override: none (so baseline = 60)
- Raw bucket totals after transactions:
  - Ath raw = 120
  - Stu raw = 80
  - Tm raw = 60
  - Cit raw = 40
- Team Top Dawg maxima (from roster pre-pass):
  - maxAth = 120, maxStu = 100, maxTm = 90, maxCit = 80
- Physical event PP (already normalized via tier tables):
  - Power events: 81, 74, 77, 79
  - Speed events: 72, 75, 70, 74
- GPA: 3.2
- Team highest combined score this cycle: 46.3

### Step A: Subjective (Top Dawg)

Scale each bucket against team Top Dawg:

\[
athleteScore = \text{round}(120/120 \times 99) = 99
\]
\[
studentScore = \text{round}(80/100 \times 99) = 79
\]
\[
teammateScore = \text{round}(60/90 \times 99) = 66
\]
\[
citizenScore = \text{round}(40/80 \times 99) = 50
\]

\[
manualBase=(99+79+66+50)/4=73.5
\]
\[
manualOvr=\text{round}(73.5) = 74
\]
\[
manualInputValue=\max(0,74-60)\times0.5=7.0
\]

### Step B: Objective

\[
powerNumber=\lceil(81+74+77+79)/4\rceil=78
\]
\[
speedNumber=\lceil(72+75+70+74)/4\rceil=73
\]
\[
gpaScore=\left\lceil(3.2/3.5)\times99\right\rceil=91
\]
\[
assessmentValue=0.2(78)+0.2(73)+0.1(91)=39.3
\]

### Step C: Combined

\[
combinedScore=39.3+7.0=46.3
\]

### Step D: Curve

\[
raw=(46.3/46.3)\times(99-60)=39
\]
\[
curveOvr=60+\lceil39\rceil=99
\]

### Step E: Top Dawg Gates

**Gate 1 check (zero buckets):**
All 4 scaled buckets are > 0 (99, 79, 66, 50) → PASS, no zero cap.

**Gate 2 check (manualOvr < 80?):**
manualOvr = 74, which IS < 80, and curveOvr = 99 which IS ≥ 90 → **GATE TRIGGERED**

\[
finalOvr = 89
\]

### Step F: Display

UI displays `finalOvr = 89`.

**How to unlock higher?** The athlete needs their manualOvr to reach 80 or above. Since manualOvr is an average of the 4 scaled buckets, they need to increase their lowest categories (Teammate: 66, Citizen: 50) to bring the average up. This incentivizes well-rounded participation.

---

## 8. Edge Case: Zero Bucket Example

### Inputs
- Same athlete as above, but they have zero Citizen transactions (Cit raw = 0).
- All other inputs identical.

### Step A: Subjective
\[
citizenScore = \text{round}(0/80 \times 99) = 0
\]

manualOvr = round((99+79+66+0)/4) = round(61.0) = **61**

### Step E: Top Dawg Gates

**Gate 1 check:** citizenScore = 0 → **ZERO CAP TRIGGERED**

\[
finalOvr = \min(curveOvr, 84)
\]

If curveOvr was 99, finalOvr becomes **84**.
If curveOvr was 70, finalOvr stays **70** (min preserves lower values).

---

## Practical Summary for Coaches

- **Baseline** is the athlete's floor — they can never drop below it.
- **Objective and subjective each control half** of the combined score.
- **Team curve** makes OVR relative, not isolated — one player's gain can shift everyone.
- **Top Dawg scoring** means each subjective category is relative to the team's best in that category. The team leader in a category always gets 99 for that bucket.
- **Zero Category Cap (84)**: if an athlete has zero points in ANY category, they cannot reach 85+. This encourages participation across all 4 pillars.
- **Subjective 80 Gate (89)**: even if objective scores are elite, the subjective average must be 80+ to enter the 90+ tier.
- **Final displayed OVR** is the gated curved result (`finalOvr`).
