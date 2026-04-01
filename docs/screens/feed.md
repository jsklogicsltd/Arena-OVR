# Feed Screen

**File:** `lib/app/modules/feed/feed_view.dart`
**Controller:** `lib/app/modules/feed/feed_controller.dart`
**Route:** `/feed` (also embedded as Tab 3 in CoachView)

---

## Overview

The Feed is a **real-time activity log for the team**. It shows events like points being awarded,
badges earned, and announcements from the coach. Both coaches and athletes can view the feed.

---

## Feed Event Types (`FeedModel.type`)

| Type | Description | Visual |
|---|---|---|
| `rating_award` | Coach awarded points to an athlete | Points badge + athlete name |
| `badge_earned` | Athlete earned a badge | Badge icon + achievement name |
| `announcement` | Coach posted an announcement | Pinned card (if `isPinned == true`) |

---

## FeedModel Fields (recap)

| Field | Description |
|---|---|
| `teamId` | The team this feed item belongs to |
| `type` | Event type (above) |
| `actorName` | Who did the action (coach name) |
| `targetName` | Who it happened to (athlete name) |
| `content` | Text content of the event |
| `category` | Rating category if applicable (e.g., `strength`) |
| `value` | Points value if applicable |
| `isPinned` | Pinned announcements appear at top |
| `createdAt` | Timestamp for ordering |

---

## UI

- Stadium background
- Feed list of cards (GlassCard style)
- Pinned items at top (highlighted)
- Chronological order for the rest
- Each card shows: actor → action → target + value + timestamp
- Animated slide-in per card via `flutter_animate`

---

## Data Source

Firestore: `feed` collection filtered by `teamId == currentTeam.id` (and `schoolId`).
Realtime stream via `snapshots()` in `CoachController._feedSub`.

---

## Notes

- Coaches access this as **Tab 3** in the CoachView bottom nav (no back arrow)
- Athletes access this via a link from their Player dashboard
- Pinned announcements are set by the coach via the `AnnouncementView`
