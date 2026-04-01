# Badges Screen

**File:** `lib/app/modules/badges/badges_view.dart`
**Controller:** `lib/app/modules/badges/badges_controller.dart`
**Route:** `/badges`

---

## Overview

The Badges screen displays all **achievement badges** an athlete can earn, showing which ones they
have already unlocked and which remain locked. It provides a gamified sense of progression.

---

## UI Layout

- Stadium background
- Screen header: **BADGES**
- Badge grid (2 or 3 columns)
- Each badge card shows:
  - Badge icon / image
  - Badge name
  - Badge description
  - **Unlocked** state: full color, glow effect
  - **Locked** state: greyscale / dimmed overlay with lock icon

---

## Badge System

- Badges are stored as IDs in `users/{uid}.badges: List<String>`
- The badge catalog (all possible badges with names/descriptions/icons) is defined in app constants or Firestore
- When a coach awards certain milestones or when an athlete reaches certain OVR thresholds, badges are automatically added to their `badges` list

---

## Data Source

- Athlete's earned badges: `users/{uid}.badges`
- Full badge catalog: app constants or `badges` Firestore collection

---

## Notes

- Athletes access this from their Player Dashboard
- No coach interaction on this screen — it is read-only for athletes
- Animations: unlocked badges have a subtle glow or shimmer effect
