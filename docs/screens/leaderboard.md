# Leaderboard Screen

**File:** `lib/app/modules/leaderboard/leaderboard_view.dart`  
**Controller:** `lib/app/modules/leaderboard/leaderboard_controller.dart`  
**Route:** `/leaderboard`

---

## Overview

The Leaderboard displays the **full ranked list of athletes on the team**, ordered by OVR from highest (rank 1) to lowest. It uses **real data from Firebase** and is the **same UI for both coach and player**: same tabs (TODAY / THIS WEEK / SEASON OVR), podium (top 3), Elite 4–20, category leaders, roster list, and team stats.

- **Player:** Shown as a tab in the bottom nav; team comes from the logged-in athlete’s `teamId`.
- **Coach:** Opened from the dashboard “LEADERBOARD” card (same screen, with back button); team comes from the coach’s `currentTeam`.

---

## UI Layout

- Stadium background
- Page header: **LEADERBOARD** (with back button when opened from coach)
- **Tabs:** TODAY | THIS WEEK | SEASON OVR
- **Podium:** Rank 1, 2, 3 (1st gold, 2nd grey, 3rd orange). Shows 1 or 2 athletes if the team has fewer than 3.
- **Elite 4–20:** Horizontal scroll of rank 4–20 with tier styling
- **Category leaders:** Performance and Classroom
- **Roster:** Remaining ranks (21+) in a list
- **Team stats bar:** Total points and labels

Each athlete card shows rank, avatar with OVR-tier ring, name, jersey, position, OVR badge, and rank delta (↑ / ↓ / —).

---

## OVR Tier Color System

| OVR Range | Color   | Label   |
|-----------|---------|---------|
| 0–29      | #CD7F32 | Bronze  |
| 30–59     | #C0C0C0 | Silver  |
| 60–79     | #FFB800 | Gold    |
| 80–94     | #9B30FF | Purple  |
| 95–99     | #00FFFF | Diamond |

Tier color: `AppColors.getTierColor(int? ovr)`.

---

## Data Source (Firebase)

- **Rankings:** Firestore `users` collection filtered by `teamId` and `role == 'athlete'`, sorted by `ovr` descending via `TeamRepository.streamTeamAthletes(teamId)`.
- **Team ID:**
  - **Player:** `PlayerController.athlete.value?.teamId`
  - **Coach:** `CoachController.currentTeam.value?.id`
- The controller re-subscribes when the athlete’s or coach’s team becomes available or changes, so the leaderboard always shows the correct team’s data.

---

## Notes

- Rankings use the `ovr` field on each `UserModel`; `rank` and `previousRank` are set by the stream for delta display.
- Coach does not have a rank (role ≠ athlete).
- Same screen and data for coach and player; only the source of `teamId` differs.
