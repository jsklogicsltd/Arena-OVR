# Arena OVR — Implementation Guide

> Everything built across prompts 1–7.  
> Last updated: April 2, 2026.

---

## Table of Contents

1. [Architecture Audit (Prompt 1)](#1-architecture-audit)
2. [Scoring Engine — Core Math (Prompts 2–3)](#2-scoring-engine--core-math)
3. [Category Renaming + Admin Delete School (Prompt 4)](#3-category-renaming--admin-delete-school)
4. [Athlete Data Model + Physical Profile (Prompt 5)](#4-athlete-data-model--physical-profile)
5. [Award Points — Tabbed Layout (Prompt 6)](#5-award-points--tabbed-layout)
6. [Dual OVR System + FinalOVR Merge (Prompt 6–7)](#6-dual-ovr-system--finalovr-merge)
7. [Assessments Tab — Bulk Spreadsheet Mode (Prompt 7)](#7-assessments-tab--bulk-spreadsheet-mode)
8. [Testing Checklist](#8-testing-checklist)
9. [File Map](#9-file-map)

---

## 1. Architecture Audit

A full read-through of the codebase established:

| Aspect | Details |
|--------|---------|
| **Framework** | Flutter + Dart |
| **State Management** | GetX (`Get.find`, `Rx` observables, `Obx` widgets) |
| **Navigation** | GetX named routes (`AppRoutes`) |
| **Backend** | Cloud Firestore, Firebase Auth, Firebase Storage |
| **Models** | `UserModel` (athletes & coaches), `TeamModel`, `SeasonModel`, `ChallengeCatalog` |
| **Manual OVR** | 4 weighted categories → raw points → `OvrEngineService.calculateOvr()` → daily-capped display |

No code was written in this step — it was purely analysis to establish the codebase DNA.

---

## 2. Scoring Engine — Core Math

### Files Created

| File | Purpose |
|------|---------|
| `lib/app/scoring_engine/profile_assignment.dart` | Assigns `PowerProfile` (light/medium/heavy) and `SpeedProfile` (standard/heavy) from height + weight |
| `lib/app/scoring_engine/scoring_engine.dart` | `scoreEvent()` converts raw → Performance Points (30–99); `calculateNumbers()` produces Power/Speed/TopPerfPts; `assignOverallRatings()` for team-relative ranking |
| `lib/app/scoring_engine/tier_tables.dart` | Massive nested `Map` of 8 events × grades 9–12 × body profiles → `TierThresholds` |

### How It Works

```
Raw Value (e.g. 315 lbs squat)
  └─ scoreEvent(raw, TierThresholds)
       ├─ Formula A (higher=better): PP = 30 + ((raw-Good)/(AllAmerican-Good)) × 69
       └─ Formula B (lower=better):  PP = 30 + ((Good-raw)/(Good-AllAmerican)) × 69
           └─ Clamped to [30, 99]

Power Scores (squat PP, bench PP)  ──┐
                                     ├─ calculateNumbers()
Speed Scores (40yd PP)             ──┘     ├─ powerNumber  = avg(powerScores)
                                           ├─ speedNumber  = avg(speedScores)
                                           └─ topPerfPts   = avg(power, speed)
```

### Profile Assignment Logic

```
assignPowerProfile(heightInches, weightLbs):
  Height < 69":   light < 130 | medium 130–179 | heavy 180+
  Height 69–72":  light < 140 | medium 140–198 | heavy 199+
  Height 73–74":  light < 155 | medium 155–219 | heavy 220+
  Height 75"+:    light < 169 | medium 169–239 | heavy 240+

assignSpeedProfile(heightInches, weightLbs):
  Same brackets but only two outcomes: standard / heavy
```

### How to Test

1. Open the app as a **coach**.
2. Go to **Award Points > Assessments** tab.
3. Enter a Squat of `315` for a Grade 12 / heavy-profile athlete.
4. The scoring engine should convert this to a Performance Points value between 30–99.
5. Verify the `automatedOvr` appears on the athlete's Firestore document.

---

## 3. Category Renaming + Admin Delete School

### Category Rename Map

| Old Name | New Name | Affects |
|----------|----------|---------|
| Performance | **Athlete** | UI labels, `ChallengeCatalog`, `OvrEngineService` weights, `CoachController`, `PlayerController` streak labels |
| Classroom | **Student** | Same |
| Program | **Teammate** | Same |
| Standard | **Citizen** | Same |

#### Files Changed
- `lib/app/data/models/challenge_catalog.dart` — `parentCategories` list and `challengesFor()` switch
- `lib/app/core/services/ovr_engine_service.dart` — weight constants renamed (`_athleteWeight`, `_studentWeight`, etc.)
- `lib/app/modules/coach/views/award_points_view.dart` — category details array, labels, short labels
- `lib/app/modules/player/player_controller.dart` — `_catLabel` mapping for backward compatibility with old streak keys

### How to Test — Category Renaming

1. Open **Award Points > Manual Ratings** tab.
2. Confirm the four categories show: **ATHLETE**, **STUDENT**, **TEAMMATE**, **CITIZEN**.
3. Tap each category — verify the challenge dropdown shows the correct subcategories.
4. Award points and confirm Firestore writes use the new category names.

### Admin Delete School

**Location:** `lib/app/modules/admin/`

| Component | What Was Added |
|-----------|----------------|
| `admin_dashboard_view.dart` | Red trash icon on each school card → `_confirmDeleteSchool()` confirmation dialog |
| `admin_controller.dart` | `deleteSchool()` — batch-deletes school doc + all teams, users, seasons, transactions, and feeds matching `schoolId` |

### How to Test — Delete School

1. Log in as **superadmin**.
2. Navigate to the Admin Dashboard.
3. Tap the red trash icon on a test school.
4. Confirm the dialog appears with the warning message.
5. Confirm deletion → verify the school and ALL its subcollections are removed from Firestore.
6. **Important:** Test on a throwaway school. This is a destructive, irreversible operation.

---

## 4. Athlete Data Model + Physical Profile

### New Fields on `UserModel`

| Field | Type | Source |
|-------|------|--------|
| `grade` | `int?` | Player-entered (9, 10, 11, 12) |
| `heightInches` | `int?` | Player-entered |
| `weightLbs` | `int?` | Player-entered |
| `powerProfile` | `String?` | Auto-calculated from height + weight |
| `speedProfile` | `String?` | Auto-calculated from height + weight |
| `automatedOvr` | `int?` | Set by coach via Assessments tab |
| `assessmentData` | `Map?` | Raw event scores + calculated numbers |

All fields are nullable for backward compatibility. `fromJson`, `toJson`, and `copyWith` all handle them.

### Settings View — Physical Profile Card

**File:** `lib/app/modules/settings/settings_view.dart`

Added a **"PHYSICAL PROFILE"** section with:
- Grade dropdown (9–12)
- Height (inches) numeric field
- Weight (lbs) numeric field
- Computed Power / Speed profile chips (displayed after save)
- **SAVE PHYSICAL PROFILE** button → calls `PlayerController.updatePhysicalProfile()`

### Player Controller Logic

**File:** `lib/app/modules/player/player_controller.dart`

`updatePhysicalProfile(grade, heightInches, weightLbs)`:
1. Validates grade is 9–12, height/weight are positive.
2. Calls `assignPowerProfile(heightInches, weightLbs)` → e.g. `"medium"`.
3. Calls `assignSpeedProfile(heightInches, weightLbs)` → e.g. `"standard"`.
4. Updates Firestore document with all 5 fields.
5. Updates local `athlete` observable so UI refreshes immediately.

### How to Test

1. Log in as an **athlete**.
2. Go to **Settings**.
3. Enter Grade: `11`, Height: `71`, Weight: `185`.
4. Tap **SAVE PHYSICAL PROFILE**.
5. Verify snackbar shows success.
6. Verify Power Profile chip shows `medium` and Speed Profile shows `standard`.
7. Check Firestore document for the athlete — confirm `grade`, `heightInches`, `weightLbs`, `powerProfile`, `speedProfile` fields exist.

---

## 5. Award Points — Tabbed Layout

**File:** `lib/app/modules/coach/views/award_points_view.dart`

The Award Points screen was restructured from a single-page into a two-tab layout:

| Tab | Content |
|-----|---------|
| **Manual Ratings** | Athlete multi-select checklist + 4 category challenge dropdowns + points sliders + note + submit |
| **Assessments (Automated)** | Bulk spreadsheet entry (see section 7) |

### Implementation Details

- Uses an explicit `TabController` with `TickerProviderStateMixin` (not `DefaultTabController`) so the FAB can be conditionally shown only on Tab 2.
- `TabBar` is styled as a pill-toggle with glass morphism.
- Each tab swipes via `TabBarView` with bouncing physics.

### How to Test

1. Log in as a **coach** and go to **Award Points**.
2. Verify two tabs appear: "Manual Ratings" and "Assessments".
3. Swipe between tabs — content should switch smoothly.
4. On the Manual Ratings tab, verify the full existing workflow still works (select athletes, pick challenges, award points).

---

## 6. Dual OVR System + FinalOVR Merge

This is the most architecturally significant change. Two separate OVR systems now merge into one displayed value.

### The Two Systems

| System | Range | Source | Firestore Field |
|--------|-------|--------|-----------------|
| **Manual OVR** | 0–99 | Coach awards via 4 categories (Athlete/Student/Teammate/Citizen) | `actualOvr` (or `ovr`) |
| **Automated OVR** | 30–99 | Scoring engine from raw athletic data (squat, bench, 40yd) | `automatedOvr` |

### The Merge Formula

```dart
// In UserModel.finalOvr getter:
int get finalOvr {
  final manual = (actualOvr != null && actualOvr! > 0) ? actualOvr! : ovr;
  if (automatedOvr == null || automatedOvr == 0) return manual;
  if (manual == 0) return automatedOvr!;
  return ((manual + automatedOvr!) / 2).round().clamp(0, 99);
}
```

### Null Safety Rules

| Manual OVR | Automated OVR | FinalOVR |
|-----------|--------------|----------|
| 75 | 85 | `(75+85)/2 = 80` |
| 75 | null/0 | `75` (manual only) |
| 0 | 85 | `85` (automated only) |
| 0 | null/0 | `0` |

### Where FinalOVR Is Used

| Location | How |
|----------|-----|
| `UserModel.coachVisibleOvr` | Returns `finalOvr` — used for coach roster display and leaderboard sorting |
| `PlayerController.displayedOvr` | Uses `finalOvr` then applies day-1 lock and phase cap |
| `LeaderboardController._hasAnyPoints` | Now also returns `true` if `automatedOvr > 0` |

### How to Test

1. Find an athlete who has **only** manual OVR (e.g. 72). Leaderboard should show `72`.
2. Submit an automated assessment for the same athlete → automated OVR = `80`.
3. Leaderboard should now show `(72 + 80) / 2 = 76`.
4. Find an athlete with **no** manual points. Submit an assessment → their `automatedOvr` (e.g. 65) should appear on the leaderboard directly.
5. An athlete with zero on both should NOT appear on the leaderboard.

---

## 7. Assessments Tab — Bulk Spreadsheet Mode

### What Changed

The Assessments tab was completely rewritten from a single-player form into a full-roster spreadsheet.

### Sorting Logic

Athletes are sorted in this priority:
1. **Grade descending** (Seniors/12th first, Freshmen/9th last)
2. **Last name alphabetical** (extracted from the single `name` field — last word = last name)
3. **First name alphabetical** (tiebreaker)

### Spreadsheet Layout

```
┌──────────────┬──────┬──────┬──────┬──────┐
│ ATHLETE      │  SQ  │  BP  │ 40yd │ GPA  │  ← header (color-coded)
├──────────────┼──────┼──────┼──────┼──────┤
│ Smith, John  │[    ]│[    ]│[    ]│[    ]│  ← row (alternating bg)
│ Gr 12  85    │      │      │      │      │
├──────────────┼──────┼──────┼──────┼──────┤
│ Adams, Mike  │[    ]│[    ]│[    ]│[    ]│
│ Gr 11        │      │      │      │      │
└──────────────┴──────┴──────┴──────┴──────┘
```

Each row shows:
- **Name** in "Last, First" format
- **Grade badge** (blue chip)
- **Existing automated OVR** (green chip, if previously scored)
- **4 compact TextFields** pre-populated from existing `assessmentData`

### State Management

```dart
Map<String, Map<String, TextEditingController>> _bulkControllers;
// Key: athleteUID → eventKey → TextEditingController
// Events: 'squat', 'bench', 'dash40', 'gpa'
```

Controllers are created lazily via `_ctrlFor(uid, event)` and properly disposed in `dispose()`.

### "Save All Assessments" FAB

- `FloatingActionButton.extended` at center-bottom, **visible only on Assessments tab**.
- On tap, iterates ALL controllers, collects rows where at least one athletic event (SQ/BP/40yd) is filled.
- Calls `CoachController.submitBulkAssessments(Map<uid, values>)`.
- Shows spinner during save, count snackbar on success.

### CoachController.submitBulkAssessments

Processes each athlete individually through the scoring engine:

```
For each athlete with data:
  1. Look up grade, powerProfile, speedProfile from roster
  2. scoreEventByName('squat', ...) → powerScores
  3. scoreEventByName('bench_press', ...) → powerScores
  4. scoreEventByName('40_yard_dash', ...) → speedScores
  5. If both power + speed → calculateNumbers() → topPerfPts = automatedOvr
     If power only → avg(powerScores) = automatedOvr
     If speed only → avg(speedScores) = automatedOvr
  6. Batch-write automatedOvr + assessmentData to Firestore
```

Handles Firestore's 500-write batch limit by committing and creating a new batch every 499 operations.

### How to Test

1. Log in as a **coach** with a populated roster (athletes should have grade/height/weight set).
2. Go to **Award Points > Assessments** tab.
3. Verify the roster appears sorted: seniors at top, then alphabetical by last name.
4. Enter `Squat: 315` and `Bench: 225` for the first athlete.
5. Enter `40-Yard Dash: 4.65` for the second athlete.
6. Leave all others blank.
7. Tap **Save All Assessments**.
8. Verify success snackbar says "2 athlete(s)".
9. Go to the **Leaderboard** — those two athletes should now show updated FinalOVRs.
10. Return to the Assessments tab — the fields you just saved should appear pre-populated.

---

## 8. Testing Checklist

### Pre-Conditions

- [ ] At least one school, one team, and 3+ athletes exist in Firestore
- [ ] At least 2 athletes have Grade, Height, and Weight saved
- [ ] Coach account is linked to the team

### Category Renaming

- [ ] Manual Ratings tab shows Athlete / Student / Teammate / Citizen
- [ ] Challenge dropdowns match the renamed parent categories
- [ ] Points awarded write to Firestore under new category keys
- [ ] Player streak labels display correctly (backward compat)

### Physical Profile

- [ ] Athlete can enter grade (9–12), height, weight on Settings screen
- [ ] Save triggers profile assignment → chips show power/speed profiles
- [ ] Firestore document has `grade`, `heightInches`, `weightLbs`, `powerProfile`, `speedProfile`

### Assessments — Bulk Entry

- [ ] Assessments tab shows full roster in spreadsheet format
- [ ] Sorted by grade DESC → last name → first name
- [ ] Existing assessment data pre-populates fields
- [ ] Can enter different values per athlete
- [ ] "Save All Assessments" FAB only visible on Assessments tab
- [ ] FAB shows spinner during save
- [ ] Snackbar confirms number of athletes processed
- [ ] Rows with no athletic events (SQ/BP/40yd) are skipped
- [ ] Rows with only GPA and no athletic events are skipped (GPA alone cannot generate automatedOvr)

### Dual OVR Merge

- [ ] Athlete with manual OVR only → leaderboard shows manual
- [ ] Athlete with automated OVR only → leaderboard shows automated
- [ ] Athlete with both → leaderboard shows `(manual + automated) / 2`
- [ ] Athlete with zero on both → does NOT appear on leaderboard
- [ ] Player dashboard shows FinalOVR (with daily cap applied)

### Admin Delete School

- [ ] Trash icon appears next to each school on Admin Dashboard
- [ ] Confirmation dialog shows warning text
- [ ] Deletion removes school + all teams, users, seasons, transactions, feeds
- [ ] Dashboard refreshes after deletion

---

## 9. File Map

```
lib/app/
├── core/
│   ├── constants/app_colors.dart
│   ├── services/ovr_engine_service.dart      ← Manual OVR weighted calc + daily cap
│   └── widgets/
├── data/
│   ├── models/
│   │   ├── user_model.dart                   ← +grade, height, weight, profiles,
│   │   │                                        automatedOvr, assessmentData,
│   │   │                                        finalOvr getter, coachVisibleOvr
│   │   ├── challenge_catalog.dart            ← Renamed categories + subcategories
│   │   ├── team_model.dart
│   │   └── season_model.dart
│   └── repositories/
├── modules/
│   ├── admin/
│   │   ├── admin_controller.dart             ← +deleteSchool()
│   │   └── admin_dashboard_view.dart         ← +trash icon + confirm dialog
│   ├── coach/
│   │   ├── coach_controller.dart             ← +submitAssessment(),
│   │   │                                        +submitBulkAssessments()
│   │   └── views/
│   │       └── award_points_view.dart        ← Tabbed: Manual Ratings + Assessments
│   │                                            Bulk spreadsheet mode + FAB
│   ├── leaderboard/
│   │   └── leaderboard_controller.dart       ← +automatedOvr in _hasAnyPoints()
│   ├── player/
│   │   └── player_controller.dart            ← +updatePhysicalProfile(),
│   │                                            displayedOvr uses finalOvr
│   └── settings/
│       └── settings_view.dart                ← +Physical Profile card
└── scoring_engine/
    ├── profile_assignment.dart               ← assignPowerProfile/SpeedProfile
    ├── scoring_engine.dart                   ← scoreEvent, calculateNumbers,
    │                                            assignOverallRatings
    └── tier_tables.dart                      ← 8 events × grades × profiles
```
