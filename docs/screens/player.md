# Player Dashboard

**File:** `lib/app/modules/player/player_view.dart`
**Controller:** `lib/app/modules/player/player_controller.dart`
**Route:** `/player`

---

## Overview

The Player (Athlete) dashboard is the **main experience for an athlete** in the app.
Players can see their personal OVR rating, rank within the team, rating history, and engage
with team content via the activity feed, badges, and leaderboard.

---

## UI Layout

- Stadium background (`StadiumBackground`)
- Profile card at top: avatar, name, jersey number, position
- **OVR badge** — large display showing current 0–99 rating with tier color:
  - 0–29: Bronze (`#CD7F32`)
  - 30–59: Silver (`#C0C0C0`)
  - 60–79: Gold (`#FFB800`)
  - 80–94: Purple (`#9B30FF`)
  - 95–99: Diamond (`#00FFFF`)
- Rank widget — current rank + delta arrow (green up / red down)
- Recent Ratings cards — last few transactions from coach
- Navigation links to:
  - Leaderboard (`/leaderboard`)
  - Badges (`/badges`)
  - Notifications (`/notifications`)
  - Settings (`/settings`)

---

## Data Sources

| Data | Firestore Source |
|---|---|
| Athlete profile | `users/{uid}` |
| Current OVR | `users/{uid}.ovr` |
| Rank | `users/{uid}.rank` |
| Recent transactions | `transactions` where `athleteId == uid` |
| Team info | `teams/{teamId}` |

---

## Navigation From Player Dashboard

```
Player Dashboard (/player)
  ├── /leaderboard    — Full team rankings
  ├── /badges         — Achievements
  ├── /notifications  — Push notification inbox
  └── /settings       — Account settings
```

---

## Notes

- Athletes cannot change their own OVR — it is 100% coach-controlled
- The dashboard is read-only — no form inputs
- `PlayerController` is NOT permanent (regular lifecycle)
