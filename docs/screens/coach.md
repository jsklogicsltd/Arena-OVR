# Coach Module — All Tabs

**Shell File:** `lib/app/modules/coach/coach_view.dart`
**Controller:** `lib/app/modules/coach/coach_controller.dart`
**Route:** `/coach`

---

## Overview

The Coach module is the **primary experience for a coach user**. It uses a custom bottom navigation
bar shell (`CoachView`) with 5 tabs rendered via `IndexedStack`.

The `CoachController` is **permanent** — it never auto-disposes during navigation. It manages all
real-time Firestore streams (teams, roster, season, feed) and survives tab switches and push overlays.

---

## Bottom Navigation Bar

Built with Flutter's native `Scaffold.floatingActionButton` (gold trophy FAB) + `BottomAppBar`.

| Tab | Index | Icon | Color (active) | View |
|---|---|---|---|---|
| HOME | 0 | `home_rounded` | `#00A8FF` (cyan) | `CoachDashboardView` |
| ROSTER | 1 | `people_rounded` | `#00A8FF` (cyan) | `RosterView` |
| AWARD | 2 | `emoji_events_rounded` | `#FFD700` (gold FAB) | `AwardPointsView` |
| FEED | 3 | `wifi_tethering` | `#00A8FF` (cyan) | `FeedView` |
| PROFILE | 4 | `person_rounded` | `#00A8FF` (cyan) | `CoachSettingsView` |

The **AWARD tab** is rendered as a gold circle FAB that floats above the nav bar.
It is implemented as `floatingActionButton` with `FloatingActionButtonLocation.centerDocked`.

> **Note:** Back arrow buttons are intentionally removed from AwardPoints, Roster, and CoachSettings
> because these are inner tabs (not pushed routes). Navigating back is done via the bottom tabs.

---

## CoachController State

| Observable | Type | Description |
|---|---|---|
| `coachTeams` | `RxList<TeamModel>` | All teams this coach has created |
| `currentTeam` | `Rx<TeamModel?>` | Currently selected team |
| `roster` | `RxList<UserModel>` | Players on current team |
| `season` | `Rx<SeasonModel?>` | Current active season |
| `feed` | `RxList<FeedModel>` | Activity feed items |
| `coachName` | `RxString` | Coach's display name |
| `selectedTab` | `RxInt` | Current tab (0–4) |

### `_hasLoadedInitialTeams`
Boolean guard that prevents the Firestore teams snapshot from triggering a redirect to CREATE_TEAM
after teams have already been loaded (e.g., during transient empty snapshots after team creation).

---

## Tab 0 — CoachDashboardView

**File:** `lib/app/modules/coach/views/coach_dashboard_view.dart`

Main coach home screen. Contains:
- Coach name greeting + avatar
- Top athlete card (highest OVR player)
- Season overview glass card (dates, status)
- 3-tile stats row: Ratings This Week, Active Players, Avg Overall
- 4 quick-action cards:
  - **CREATE TEAM** → navigates to `/create-team`
  - **TEAM SETTINGS** → navigates to `/team-settings`
  - **SEASON HQ** → navigates to `/season-hq`
  - **Announcements** → navigates to `AnnouncementView`
- Animated entry via `flutter_animate`

---

## Tab 1 — RosterView

**File:** `lib/app/modules/coach/views/roster_view.dart`

Displays the team roster.
- Header: **MY TEAM** (centered, no back arrow)
- GlassCard for team info (name, school, player count)
- Horizontal filter chips: ALL, OFFENSE, DEFENSE, SPECIAL TEAMS
- Player cards with:
  - Avatar with colored ring (OVR tier color)
  - Name, jersey number, position
  - OVR badge
  - Colored left border per tier
- `+` yellow button to add a player
- Falls back to mock data if roster is empty

---

## Tab 2 — AwardPointsView

**File:** `lib/app/modules/coach/views/award_points_view.dart`

Coach awards or deducts OVR points to athletes.
- Header: **AWARD POINTS** (centered, no icon, no back arrow)
- Athlete selector at top
- Category grid (Strength, Speed, IQ, etc.)
- Points value slider / stepper
- Award button → creates a `TransactionModel` in Firestore, updates athlete OVR
- Animated entry with `flutter_animate`

---

## Tab 3 — FeedView

**File:** `lib/app/modules/feed/feed_view.dart`

Real-time activity feed for the team.
- Displays `FeedModel` items from Firestore
- Different visual styles per `type`: `rating_award`, `badge_earned`, `announcement`
- Pinned items appear at the top (`isPinned == true`)

---

## Tab 4 — CoachSettingsView

**File:** `lib/app/modules/coach/views/coach_settings_view.dart`

Coach profile and settings tab.
- Header: **SETTINGS** (centered, no back arrow)
- Coach name, avatar, school info
- Options: edit profile, notifications, privacy, help
- **Logout** button → calls `CoachController.logout()`:
  - Signs out Firebase Auth
  - Calls `Get.delete<CoachController>(force: true)` to clean permanent controller
  - Navigates to `/auth`

---

## Push-Over Views (Accessed from Dashboard)

### CreateTeamView (`/create-team`)
**File:** `lib/app/modules/coach/views/create_team_view.dart`
- Form: team name, colors, logo upload, school selection
- Generates a unique `teamCode`
- On success: `_showSuccessOverlay` shows the invite code with gold glow styling and stadium background
- Navigation after success: `Get.until((route) => route.settings.name == Routes.COACH)`
  — ensures the permanent `CoachController` is never disposed

### TeamSettingsView (`/team-settings`)
**File:** `lib/app/modules/coach/views/team_settings_view.dart`
- Edit existing team: name, colors, logo, active status

### SeasonView (`/season-hq`)
**File:** `lib/app/modules/coach/views/season_view.dart`
- Start a new season, end current season, set reveal date
- Season is stored as a `SeasonModel` in Firestore

### AnnouncementView (in-module)
**File:** `lib/app/modules/coach/views/announcement_view.dart`
- Coach posts announcements to the team feed

---

## Navigation Rules

```dart
// From dashboard quick-action cards:
Get.toNamed(Routes.CREATE_TEAM)      // Create Team
Get.toNamed(Routes.TEAM_SETTINGS)    // Team Settings
Get.toNamed(Routes.SEASON_HQ)        // Season HQ

// After successful team creation — stay in coach shell:
Get.until((route) => route.settings.name == Routes.COACH)

// Logout:
await FirebaseAuth.instance.signOut();
Get.delete<CoachController>(force: true);
Get.offAllNamed(Routes.AUTH);
```
