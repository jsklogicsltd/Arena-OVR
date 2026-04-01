# Arena OVR 99 — Full Application Overview

> **Purpose of this file:** This is the master context document for the Arena OVR 99 Flutter app.
> When opening this in Cursor, the AI will understand the full app—its purpose, all screens, data
> models, user roles, navigation, tech stack, and design rules—without needing to open individual files.

---

## 1. What is Arena OVR 99?

Arena OVR 99 is a **sports team management app** (American football / multi-sport) built for schools.
It allows a **Super Admin** to set up schools, **Coaches** to manage teams and athlete ratings,
and **Athletes/Players** to view their own stats, rankings, and activity feed.

The core mechanic is an **OVR (Overall Rating) system** — the coach can award points to players across
categories (Strength, Speed, IQ, etc.). The app tracks ratings, streaks, ranks, seasons, and badges,
giving athletes a gamified competitive experience.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Dart / Flutter (cross-platform iOS + Android) |
| **State Management** | GetX (`GetxController`, `Obx`, `RxList`, `Rx<T>`) |
| **Navigation** | GetX Named Routes (`Get.toNamed`, `Get.offAllNamed`, `Get.until`) |
| **Backend / Auth** | Firebase Auth, Cloud Firestore, Firebase Storage |
| **Realtime Data** | Firestore `snapshots()` streams inside controllers |
| **Push Notifications** | `firebase_messaging` + `flutter_local_notifications` |
| **Fonts** | `google_fonts` (primary: `SpaceGrotesk`) |
| **Images** | `cached_network_image` |
| **Animations** | `flutter_animate` |
| **File Picking** | `image_picker` |

---

## 3. User Roles

There are **three user roles** stored in Firestore `users.role`:

| Role | Value | Description |
|---|---|---|
| **Super Admin** | `superadmin` | Creates and manages schools. Provides invite codes to coaches. |
| **Coach** | `coach` | Creates teams within a school. Manages roster, awards points, runs seasons. |
| **Athlete / Player** | `athlete` | Joined by invite code from coach. Views their stats, rank, feed, badges. |

The role is determined at **Signup** and drives all routing (splash checks role → routes to correct dashboard).

---

## 4. Full Route Map

All routes are defined in `lib/app/routes/app_routes.dart` and registered in `lib/app/routes/app_pages.dart`.

```
/splash            → SplashView           (role check → correct dashboard)
/auth              → AuthView             (Login)
/signup            → SignupView           (role picker + registration)
/forgot-password   → ForgotPasswordView   (email reset)
/invite-code       → InviteCodeView       (code entry for coach/athlete after signup)

/admin             → AdminDashboardView   (Super Admin dashboard)
/create-school     → CreateSchoolView
/school-details    → SchoolDetailsView
/admin-settings    → AdminSettingsView

/coach             → CoachView            (Coach bottom nav shell — PERMANENT controller)
  ├── Tab 0: CoachDashboardView
  ├── Tab 1: RosterView
  ├── Tab 2: AwardPointsView
  ├── Tab 3: FeedView
  └── Tab 4: CoachSettingsView

/create-team       → CreateTeamView       (pushed on first login or from dashboard)
/team-settings     → TeamSettingsView
/season-hq         → SeasonView
/coach-settings    → CoachSettingsView    (also accessible as push-over)

/player            → PlayerView           (Athlete dashboard shell)
/leaderboard       → LeaderboardView
/notifications     → NotificationsView
/badges            → BadgesView
/settings          → SettingsView
```

> ⚠️ `CoachController` uses `Get.put(..., permanent: true)` — it is NEVER auto-disposed during
> navigation. It is only deleted manually via `Get.delete<CoachController>(force: true)` on logout.

---

## 5. Data Models (Firestore)

### 5.1 `UserModel` — `lib/app/data/models/user_model.dart`
Stored in Firestore collection: **`users/{uid}`**

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase Auth UID |
| `email` | `String` | User's email |
| `name` | `String` | Display name |
| `profilePicUrl` | `String?` | Firebase Storage URL |
| `role` | `String` | `superadmin` / `coach` / `athlete` |
| `schoolId` | `String?` | The school this user belongs to |
| `teamId` | `String?` | Athlete's team (single team) |
| `teamIds` | `List<String>` | Coach's managed teams (can be multiple) |
| `activeTeamId` | `String?` | Coach's currently selected team |
| `jerseyNumber` | `String?` | Athlete jersey number |
| `positionGroup` | `String?` | e.g., OFFENSE, DEFENSE, SPECIAL TEAMS |
| `fcmToken` | `String?` | Push notification token |
| `currentRating` | `Map<String, dynamic>` | Category → points (e.g., `{strength: 85}`) |
| `ovr` | `int` | OVR 0–99 composite rating |
| `rank` | `int?` | Current rank within team |
| `previousRank` | `int?` | Previous rank (for delta arrows) |
| `badges` | `List<String>` | Badge IDs earned |
| `hasUploadedPic` | `bool` | Whether profile pic is uploaded |
| `currentStreak` | `Map<String, dynamic>` | Streak tracking data |
| `createdAt` | `DateTime?` | Account creation time |
| `lastActiveAt` | `DateTime?` | Last active timestamp |

---

### 5.2 `TeamModel` — `lib/app/data/models/team_model.dart`
Stored in Firestore collection: **`teams/{teamId}`**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore doc ID |
| `schoolId` | `String` | Parent school |
| `schoolName` | `String?` | Denormalized school name |
| `schoolInviteCode` | `String?` | Invite code for this school |
| `name` | `String` | Team name |
| `teamCode` | `String` | Unique numeric/alpha code players use to join |
| `isActive` | `bool` | Is team currently active |
| `primaryColor` | `String` | Hex color string for team primary color |
| `secondaryColor` | `String` | Hex color string for team secondary color |
| `logoUrl` | `String?` | Firebase Storage URL for team logo |
| `currentSeasonId` | `String?` | Active season document ID |
| `totalRatingsThisSeason` | `int` | Count of rating transactions in season |
| `averageOvr` | `int` | Team-wide average OVR |
| `createdAt` | `DateTime?` | Team creation time |
| `createdBy` | `String` | Coach UID who created this team |

---

### 5.3 `SeasonModel` — `lib/app/data/models/season_model.dart`
Stored in Firestore collection: **`seasons/{seasonId}`**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore doc ID |
| `teamId` | `String` | Parent team |
| `schoolId` | `String` | Parent school |
| `seasonNumber` | `int` | Season number (1, 2, 3...) |
| `startDate` | `DateTime?` | Season start |
| `endDate` | `DateTime?` | Season end |
| `isActive` | `bool` | Is this the current active season |
| `revealDate` | `DateTime?` | Date when season OVR rankings are revealed |
| `createdAt` | `DateTime?` | Created at |

---

### 5.4 `FeedModel` — `lib/app/data/models/feed_model.dart`
Stored in Firestore collection: **`feed/{docId}`** (scoped to teamId + schoolId)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore doc ID |
| `teamId` | `String` | Team scope |
| `schoolId` | `String` | School scope |
| `type` | `String` | Event type (e.g. `rating_award`, `badge_earned`, `announcement`) |
| `actorId` | `String?` | Who performed the action (coach UID) |
| `targetId` | `String?` | Who it happened to (athlete UID) |
| `actorName` | `String` | Display name of actor |
| `targetName` | `String` | Display name of target |
| `content` | `String` | Text content of the feed item |
| `category` | `String?` | Rating category if applicable |
| `value` | `int?` | Points value if applicable |
| `isPinned` | `bool` | Whether this post is pinned to the top |
| `createdAt` | `DateTime?` | When the event occurred |

---

### 5.5 `TransactionModel` — `lib/app/data/models/transaction_model.dart`
Stored in Firestore collection: **`transactions/{docId}`**

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore doc ID |
| `athleteId` | `String` | Target athlete UID |
| `coachId` | `String` | Coach who awarded |
| `teamId` | `String` | Team scope |
| `schoolId` | `String` | School scope |
| `seasonId` | `String` | Season this belongs to |
| `category` | `String` | Rating category (e.g., `strength`, `speed`) |
| `value` | `int` | Points awarded (positive or negative) |
| `note` | `String?` | Optional note |
| `type` | `String` | `award` or `deduct` |
| `createdAt` | `DateTime?` | Timestamp |
| `isArchived` | `bool` | Archived/deleted flag |

---

## 6. CoachController — The Big One

**File:** `lib/app/modules/coach/coach_controller.dart`

This is the central controller for the entire coach experience. It is **permanent** (`permanent: true`
in `GetPage` binding) and never auto-disposed during normal navigation. It is only manually deleted
via `Get.delete<CoachController>(force: true)` during logout.

### Key State
| Observable | Type | Description |
|---|---|---|
| `coachTeams` | `RxList<TeamModel>` | All teams this coach has created |
| `currentTeam` | `Rx<TeamModel?>` | Currently selected/active team |
| `roster` | `RxList<UserModel>` | Athletes on the current team |
| `season` | `Rx<SeasonModel?>` | Current active season for the team |
| `feed` | `RxList<FeedModel>` | Activity feed for current team |
| `coachName` | `RxString` | Coach's display name |
| `selectedTab` | `RxInt` | Current bottom nav tab index (0–4) |

### Key Streams
- `_teamsSub` — Firestore `teams` collection filtered by `createdBy == uid`. On each snapshot:
  - If teams exist → load active team, mark `_hasLoadedInitialTeams = true`
  - If no teams AND `!_hasLoadedInitialTeams` → navigate to `/create-team`
- `_rosterSub` — `users` collection where `teamId == currentTeam.id`
- `_seasonSub` — `seasons` collection where `teamId == currentTeam.id && isActive == true`
- `_feedSub` — `feed` collection filtered by teamId

### `_hasLoadedInitialTeams` Guard
This boolean prevents the Firestore snapshot from incorrectly redirecting the coach to CREATE_TEAM
after team creation or when switching teams causes a transient empty snapshot.

### Navigation Flow (Multi-Team)
1. Coach creates team A → `Get.until(route == /coach)` → stays on coach dashboard
2. Coach creates team B → same path → `CoachController` is already permanent, not re-created
3. Switching teams calls `switchTeam(team)` → cancels current streams, starts new ones for new team

---

## 7. Design System

### Colors — `lib/app/core/constants/app_colors.dart`
| Name | Hex | Usage |
|---|---|---|
| `background` | `#0A0E1A` | App root dark background |
| `backgroundEnd` | `#141B2D` | Gradient end for backgrounds |
| `primary` | `#00A3FF` | Blue — active nav, accent |
| `accent` | `#FFB800` | Gold — highlights, ratings |
| `positive` | `#00FF88` | Green — rank up, positive delta |
| `negative` | `#FF3B5C` | Red — rank down, negative delta |
| `cardSurface` | `#141B2D` at 70% | Glass card backgrounds |
| `cardBorder` | `#FFFFFF` at 10% | Glass card border |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#8899AA` | Secondary/muted text |
| `seasonGold` | `#FFD700` | Season highlights, FAB button |

### OVR Tier Color System
| OVR Range | Color | Label |
|---|---|---|
| 0–29 | `#CD7F32` | Bronze |
| 30–59 | `#C0C0C0` | Silver |
| 60–79 | `#FFB800` | Gold |
| 80–94 | `#9B30FF` | Purple |
| 95–99 | `#00FFFF` | Diamond |

### Fonts
- Primary: **SpaceGrotesk** (via `google_fonts`)
- Weights used: w700 (bold), w800 (heavy), w900 (black)
- Letter spacing: `1.5` for ALL CAPS headers, `-0.5` for compact display text

### Design Language — Glassmorphism
- All cards use **GlassCard** widget: semi-transparent dark background + thin white border
- Background: **StadiumBackground** widget wraps all major screens — stadium image at 40% opacity
  layered over the dark `AppColors.background` base + gradient fade at bottom
- Micro-animations: All major views use `flutter_animate` (`.animate().fade().slideX()`)
- Typography: All caps labels with letter spacing for sports aesthetic

### Background — `lib/app/core/widgets/stadium_background.dart`
Wraps a `Scaffold` body with:
1. 40% opacity stadium image (`assets/images/background.*`)
2. Bottom gradient fade to `AppColors.backgroundEnd`
3. `SafeArea(child: child)` for the actual screen content

---

## 8. Module Breakdown

### 8.1 Splash (`/splash`)
- **File:** `lib/app/modules/splash/splash_view.dart`
- Checks Firebase Auth state on startup
- Reads `users/{uid}.role` from Firestore
- Routes to `/admin`, `/coach`, or `/player` depending on role
- Routes to `/auth` if not logged in

### 8.2 Auth (`/auth`)
- **File:** `lib/app/modules/auth/auth_view.dart`
- Email + password login via Firebase Auth
- Links to Signup and Forgot Password
- On success → reads role → navigates to correct dashboard

### 8.3 Signup (`/signup`)
- **File:** `lib/app/modules/signup/signup_view.dart`
- User picks role (Coach or Athlete) on signup
- Creates Firebase Auth user + Firestore `users` document
- After signup → `/invite-code`
- Super admins are created out-of-band (not via public signup)

### 8.4 Forgot Password (`/forgot-password`)
- **File:** `lib/app/modules/forgot_password/forgot_password_view.dart`
- Sends Firebase password reset email

### 8.5 Invite Code (`/invite-code`)
- **File:** `lib/app/modules/invite_code/invite_code_view.dart`
- Coach enters **school invite code** (provided by Super Admin) after signup
- Athlete enters **team code** (provided by Coach) after signup
- On valid code → user's `schoolId` / `teamId` saved → navigate to dashboard

### 8.6 Admin (`/admin`)
- **Files:** `lib/app/modules/admin/`
- Super Admin can create schools (`/create-school`)
- View/manage all school details (`/school-details`)
- Access admin settings (`/admin-settings`)

### 8.7 Coach (`/coach`) — Main Shell
- **File:** `lib/app/modules/coach/coach_view.dart`
- Contains `IndexedStack` with 5 tabs + custom bottom nav bar
- Bottom nav uses Flutter's `FloatingActionButton` (`centerDocked`) + `BottomAppBar`
- FAB = gold trophy button (AWARD tab) — floats above the bar
- `CoachController` is permanent — never auto-disposed

#### Coach Tabs:
| Tab | Index | View | Description |
|---|---|---|---|
| HOME | 0 | `CoachDashboardView` | Summary stats, top athlete, season overview, quick action cards |
| ROSTER | 1 | `RosterView` | Full player list with OVR, filters, avatar rings |
| AWARD | 2 | `AwardPointsView` | Award/deduct points to athletes by category |
| FEED | 3 | `FeedView` | Activity feed of rating events |
| PROFILE | 4 | `CoachSettingsView` | Coach profile, app settings, logout |

#### Push-Over Views (from Coach):
- `/create-team` — Create a new team (can create multiple)
- `/team-settings` — Edit existing team details
- `/season-hq` — Season management (start/end seasons)
- `/coach-settings` — Full coach settings overlay

### 8.8 Create Team (`/create-team`)
- **File:** `lib/app/modules/coach/views/create_team_view.dart`
- Fields: team name, school, colors, logo
- Generates a unique `teamCode`
- On success: shows `_showSuccessOverlay` with invite code
- Navigation on success: `Get.until(route == Routes.COACH)` (preserves permanent CoachController)
- First-time coaches are automatically directed here before seeing the dashboard

### 8.9 Player (`/player`)
- **File:** `lib/app/modules/player/player_view.dart`
- Athlete's personal dashboard
- Shows OVR, rank, recent ratings, badges

### 8.10 Leaderboard (`/leaderboard`)
- **File:** `lib/app/modules/leaderboard/leaderboard_view.dart`
- Team-wide ranking of athletes by OVR
- Shows rank delta (up/down arrows with colors)

### 8.11 Feed (`/feed`)
- **File:** `lib/app/modules/feed/feed_view.dart`
- Real-time activity feed for the team
- `FeedModel` type drives the visual style (rating, badge, announcement, etc.)

### 8.12 Notifications (`/notifications`)
- **File:** `lib/app/modules/notifications/notifications_view.dart`
- Push notification inbox (Firebase Messaging)

### 8.13 Badges (`/badges`)
- **File:** `lib/app/modules/badges/badges_view.dart`
- Achievement badges earned by the athlete
- Badge catalog showing locked/unlocked state

### 8.14 Settings (`/settings`)
- **File:** `lib/app/modules/settings/settings_view.dart`
- General app settings (shared between roles)
- Theme, account, notifications toggle

---

## 9. Navigation Patterns

### Standard Push
```dart
Get.toNamed(Routes.ROUTE_NAME)          // push, can go back
Get.offNamed(Routes.ROUTE_NAME)         // push, removes current route
Get.offAllNamed(Routes.ROUTE_NAME)      // push, clears entire stack
```

### Safe Navigation (Coach Stack)
```dart
// Used after team creation — keeps stack intact, preserves permanent controller
Get.until((route) => route.settings.name == Routes.COACH);
```

### Back Navigation
```dart
Get.back()   // standard back
// NOTE: back arrow buttons have been REMOVED from  
// AwardPointsView, RosterView, and CoachSettingsView
// because these are inside the IndexedStack bottom nav tabs
```

---

## 10. Firestore Collection Structure

```
firestore/
├── users/
│   └── {uid}/                     ← UserModel
├── teams/
│   └── {teamId}/                  ← TeamModel
├── seasons/
│   └── {seasonId}/                ← SeasonModel
├── feed/
│   └── {docId}/                   ← FeedModel (teamId + schoolId scoped)
├── transactions/
│   └── {docId}/                   ← TransactionModel
├── schools/
│   └── {schoolId}/                ← School data (name, inviteCode)
└── notifications/
    └── {docId}/                   ← NotificationModel
```

---

## 11. Key Files Quick Reference

| Purpose | File Path |
|---|---|
| App entry point | `lib/main.dart` |
| All routes | `lib/app/routes/app_routes.dart` |
| Route registrations | `lib/app/routes/app_pages.dart` |
| Coach shell + bottom nav | `lib/app/modules/coach/coach_view.dart` |
| Coach state management | `lib/app/modules/coach/coach_controller.dart` |
| Coach dashboard UI | `lib/app/modules/coach/views/coach_dashboard_view.dart` |
| Team creation | `lib/app/modules/coach/views/create_team_view.dart` |
| Roster | `lib/app/modules/coach/views/roster_view.dart` |
| Award points | `lib/app/modules/coach/views/award_points_view.dart` |
| Season management | `lib/app/modules/coach/views/season_view.dart` |
| Team settings | `lib/app/modules/coach/views/team_settings_view.dart` |
| Color constants | `lib/app/core/constants/app_colors.dart` |
| Asset path constants | `lib/app/core/constants/app_assets.dart` |
| Background widget | `lib/app/core/widgets/stadium_background.dart` |
| GlassCard widget | `lib/app/core/widgets/` |
| UserModel | `lib/app/data/models/user_model.dart` |
| TeamModel | `lib/app/data/models/team_model.dart` |
| SeasonModel | `lib/app/data/models/season_model.dart` |
| FeedModel | `lib/app/data/models/feed_model.dart` |
| TransactionModel | `lib/app/data/models/transaction_model.dart` |

---

## 12. Known Bugs Fixed & Important Decisions

### Multi-Team Coach Bug (Critical)
**Problem:** When a coach created a second team, the `CoachController` was being deleted because:
1. The `CREATE_TEAM` route had its own `CoachController` binding (causing duplication)
2. `Get.offAllNamed(Routes.COACH)` in `_showSuccessOverlay` destroyed the entire stack

**Fix:**
- `CoachController` is now `permanent: true` on the `/coach` route
- `CREATE_TEAM` route has no binding
- Success navigation uses `Get.until(route == Routes.COACH)`
- `_hasLoadedInitialTeams` flag prevents phantom redirects to CREATE_TEAM on transient empty snapshots
- `logout()` manually calls `Get.delete<CoachController>(force: true)` for clean state on re-login

### Bottom Nav AWARD Button Hit-Testing Bug
**Problem:** When the AWARD (trophy) button was implemented as a `Stack` with a child visually
overflowing via negative offset, Flutter's hit testing did not register taps on the overflowing part.

**Fix:** Implemented using Flutter's native `Scaffold.floatingActionButton` with
`FloatingActionButtonLocation.centerDocked` — this natively handles the overlapping area hit-testing.

---

## 13. Screen Documentation Index

| Screen | Doc File |
|---|---|
| Splash | [splash.md](screens/splash.md) |
| Auth / Login | [auth.md](screens/auth.md) |
| Signup | [signup.md](screens/signup.md) |
| Forgot Password | [forgot_password.md](screens/forgot_password.md) |
| Invite Code | [invite_code.md](screens/invite_code.md) |
| Super Admin | [admin_super.md](screens/admin_super.md) |
| Coach (All Tabs) | [coach.md](screens/coach.md) |
| Feed | [feed.md](screens/feed.md) |
| Leaderboard | [leaderboard.md](screens/leaderboard.md) |
| Badges | [badges.md](screens/badges.md) |
| Notifications | [notifications.md](screens/notifications.md) |
| Settings | [settings.md](screens/settings.md) |
| Player | [player.md](screens/player.md) |
